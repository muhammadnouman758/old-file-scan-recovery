import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:archive/archive_io.dart';

class VaultManager {
  late Directory _vaultDir;
  late Directory _metadataDir;
  late Directory _externalDir;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _saltKey = 'vault_salt';
  static const String _deviceIdKey = 'device_id';

  VaultManager();

  /// Initialize the Vault
  Future<void> initializeVault() async {
    final appDir = await getApplicationDocumentsDirectory();
    _vaultDir = Directory('${appDir.path}/vault');
    _metadataDir = Directory('${appDir.path}/vault_metadata');
    _externalDir = Directory('storage/emulated/0/.VaultSecure');
    if (!await _vaultDir.exists()) {
      await _vaultDir.create(recursive: true);
    }

    if (!await _metadataDir.exists()) {
      await _metadataDir.create(recursive: true);
    }

    if (!await _externalDir.exists()) {
      await _externalDir.create(recursive: true);

      if (Platform.isAndroid) {
        final nomediaFile = File('${_externalDir.path}/.nomedia');
        if (!await nomediaFile.exists()) {
          await nomediaFile.create();
        }
      }
    }

    // Initialize device-specific salt if not exists
    final salt = await _secureStorage.read(key: _saltKey);
    if (salt == null) {
      final randomSalt = _generateRandomString(32);
      await _secureStorage.write(key: _saltKey, value: randomSalt);
    }

    // Initialize device ID if not exists
    final deviceId = await _secureStorage.read(key: _deviceIdKey);
    if (deviceId == null) {
      final id = await _getDeviceUniqueId();
      await _secureStorage.write(key: _deviceIdKey, value: id);
    }
  }

  /// Generate a random string of specified length
  String _generateRandomString(int length) {
    final random = encrypt.SecureRandom(length);
    return base64Url.encode(random.bytes).substring(0, length);
  }

  /// Get unique device identifier
  Future<String> _getDeviceUniqueId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown';
    }
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Derive encryption key from password
  Future<encrypt.Key> _deriveKeyFromPassword(String password) async {
    // Get salt and device ID from secure storage
    final salt = await _secureStorage.read(key: _saltKey) ?? _generateRandomString(32);
    final deviceId = await _secureStorage.read(key: _deviceIdKey) ?? await _getDeviceUniqueId();

    // Combine password with device ID for device binding
    final combinedInput = password + deviceId;

    // Use PBKDF2 to derive a strong key
    final keyBytes = utf8.encode(combinedInput);
    final saltBytes = utf8.encode(salt);

    // Simulate PBKDF2 with multiple SHA-256 iterations
    Uint8List derivedKey = Uint8List.fromList(keyBytes);
    for (int i = 0; i < 10000; i++) {
      derivedKey = Uint8List.fromList(sha256.convert([...derivedKey, ...saltBytes]).bytes);
    }

    // Return key for AES-256 (32 bytes)
    return encrypt.Key(derivedKey.sublist(0, 32));
  }

  /// Test if the password is correct
  Future<bool> validatePassword(String password) async {
    try {
      final testFile = File('${_metadataDir.path}/test_validation.aes');
      if (!await testFile.exists()) {
        // Create a test file for validation
        final key = await _deriveKeyFromPassword(password);
        final iv = encrypt.IV.fromSecureRandom(16);
        final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

        const testData = 'VaultValidation';
        final encrypted = encrypter.encrypt(testData, iv: iv);

        final Map<String, dynamic> testInfo = {
          'iv': base64.encode(iv.bytes),
          'data': encrypted.base64,
        };

        await testFile.writeAsString(jsonEncode(testInfo));
      } else {
        // Try to decrypt test file with provided password
        final testContent = await testFile.readAsString();
        final testInfo = jsonDecode(testContent);

        final key = await _deriveKeyFromPassword(password);
        final iv = encrypt.IV.fromBase64(testInfo['iv']);
        final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

        try {
          final decrypted = encrypter.decrypt64(testInfo['data'], iv: iv);
          return decrypted == 'VaultValidation';
        } catch (e) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Encrypt and Move a File to the Vault
  Future<bool> secureFile(File file, String password) async {
    try {
      final String originalFileName = file.path.split('/').last;
      final String fileId = _generateRandomString(16);
      final String encryptedFilename = '$fileId.aes';
      final vaultFile = File('${_vaultDir.path}/$encryptedFilename');

      final key = await _deriveKeyFromPassword(password);
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

      // Read file content
      final fileBytes = await file.readAsBytes();

      // Encrypt file content
      final encryptResult = encrypter.encryptBytes(fileBytes, iv: iv);

      // Write encrypted content to vault
      await vaultFile.writeAsBytes([
        ...iv.bytes,
        ...encryptResult.bytes
      ]);

      // Save metadata
      await _saveFileMetadata(fileId, originalFileName, file.path, iv, password);

      return true;
    } catch (e) {
      print('Error securing file: $e');
      return false;
    }
  }

  /// Save file metadata
  Future<void> _saveFileMetadata(
      String fileId,
      String originalFileName,
      String originalPath,
      encrypt.IV iv,
      String password
      ) async {
    final metadataFile = File('${_metadataDir.path}/$fileId.meta');

    // Store metadata
    final metadata = {
      'id': fileId,
      'originalName': originalFileName,
      'originalPath': originalPath,
      'originalExtension': originalFileName.split('.').last,
      'dateAdded': DateTime.now().toIso8601String(),
      'iv': base64.encode(iv.bytes),
    };

    // Encrypt metadata
    final key = await _deriveKeyFromPassword(password);
    final metaIv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

    final encryptedMetadata = encrypter.encrypt(jsonEncode(metadata), iv: metaIv);

    // Save metadata with its IV
    final metadataWrapper = {
      'iv': base64.encode(metaIv.bytes),
      'data': encryptedMetadata.base64,
    };

    await metadataFile.writeAsString(jsonEncode(metadataWrapper));
  }

  /// Decrypt metadata
  Future<Map<String, dynamic>?> _decryptMetadata(String fileId, String password) async {
    try {
      final metadataFile = File('${_metadataDir.path}/$fileId.meta');
      if (!await metadataFile.exists()) return null;

      final metaContent = await metadataFile.readAsString();
      final metaWrapper = jsonDecode(metaContent);

      final key = await _deriveKeyFromPassword(password);
      final iv = encrypt.IV.fromBase64(metaWrapper['iv']);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

      final decryptedMetaJson = encrypter.decrypt64(metaWrapper['data'], iv: iv);
      return jsonDecode(decryptedMetaJson);
    } catch (e) {
      print('Error decrypting metadata: $e');
      return null;
    }
  }

  /// Decrypt file to external secure location
  Future<File?> decryptFile(String fileId, String password) async {
    try {
      final encryptedFile = File('${_vaultDir.path}/$fileId.aes');
      if (!await encryptedFile.exists()) return null;

      // Read metadata to get the original file name
      final metadata = await _decryptMetadata(fileId, password);
      if (metadata == null) return null;

      // Create a secure temporary directory in external storage
      final tempDir = Directory('${_externalDir.path}/temp');
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

      final decryptedFilePath = '${tempDir.path}/${metadata['originalName']}';
      final decryptedFile = File(decryptedFilePath);

      // Read encrypted file
      final fileBytes = await encryptedFile.readAsBytes();

      // Extract IV (first 16 bytes)
      final ivBytes = fileBytes.sublist(0, 16);
      final iv = encrypt.IV(ivBytes);

      // Extract encrypted data (after IV)
      final encryptedData = fileBytes.sublist(16);

      // Derive key from password
      final key = await _deriveKeyFromPassword(password);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

      // Decrypt bytes
      final decryptedBytes = encrypter.decryptBytes(
          encrypt.Encrypted(Uint8List.fromList(encryptedData)),
          iv: iv
      );

      // Write decrypted data to external temporary file
      await decryptedFile.writeAsBytes(decryptedBytes);
      return decryptedFile;
    } catch (e) {
      print('Error decrypting file: $e');
      return null;
    }
  }

  /// Generate thumbnail from encrypted file
  Future<String?> generateThumbnail(String fileId, String password) async {
    try {
      // Check metadata to see if it's a video file
      final metadata = await _decryptMetadata(fileId, password);
      if (metadata == null) return null;

      final extension = metadata['originalExtension'].toString().toLowerCase();
      if (!['mp4', 'mkv', 'mov', 'avi', 'webm'].contains(extension)) {
        return null; // Not a video file
      }

      // Create thumbnails directory in external storage
      final thumbnailsDir = Directory('${_externalDir.path}/thumbnails');
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }

      // Check if thumbnail already exists
      final thumbnailFile = File('${thumbnailsDir.path}/$fileId.png');
      if (await thumbnailFile.exists()) {
        return thumbnailFile.path;
      }

      // Decrypt the file to external storage
      final decryptedFile = await decryptFile(fileId, password);
      if (decryptedFile == null) return null;

      try {
        // Generate the thumbnail
        XFile? thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: decryptedFile.path,
          imageFormat: ImageFormat.PNG,
          maxHeight: 250,
          maxWidth: 360,
          quality: 75,
        );

        return thumbnailPath.path;
      } finally {
        // Always delete the temporary decrypted file
        await decryptedFile.delete().catchError((_) {});
      }
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  /// List all files in the vault with metadata
  Future<List<Map<String, dynamic>>> listVaultFiles(String password) async {
    try {
      final metadataFiles = _metadataDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.meta'))
          .toList();

      final List<Map<String, dynamic>> result = [];

      for (final metaFile in metadataFiles) {
        final fileId = metaFile.path.split('/').last.replaceAll('.meta', '');
        final metadata = await _decryptMetadata(fileId, password);

        if (metadata != null) {
          String? thumbnailPath;
          if (['mp4', 'mkv', 'mov', 'avi', 'webm'].contains(
              metadata['originalExtension'].toString().toLowerCase())) {
            thumbnailPath = await generateThumbnail(fileId, password);
          }

          result.add({
            'id': fileId,
            'originalName': metadata['originalName'],
            'dateAdded': metadata['dateAdded'],
            'extension': metadata['originalExtension'],
            'thumbnail': thumbnailPath,
          });
        }
      }

      return result;
    } catch (e) {
      print('Error listing vault files: $e');
      return [];
    }
  }

  /// Delete file from vault
  Future<bool> deleteFile(String fileId) async {
    try {
      final encryptedFile = File('${_vaultDir.path}/$fileId.aes');
      final metadataFile = File('${_metadataDir.path}/$fileId.meta');
      final thumbnailFile = File('${_externalDir.path}/thumbnails/$fileId.png');

      if (await encryptedFile.exists()) {
        await encryptedFile.delete();
      }

      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }

      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }

      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Calculate file checksum
  Future<String> _calculateChecksum(File file) async {
    final fileBytes = await file.readAsBytes();
    return sha256.convert(fileBytes).toString();
  }

  /// Backup vault to external storage
  Future<String?> backupVault(String password, String customBackupPath) async {
    try {
      // Determine backup directory - use custom path or default external storage
      final backupDir = customBackupPath.isNotEmpty
          ? Directory(customBackupPath)
          : Directory('${_externalDir.path}/backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Create a timestamp for the backup filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName = 'vault_backup_$timestamp.zip';
      final backupFile = File('${backupDir.path}/$backupFileName');

      // Create external backup work directory to avoid using internal temporary storage
      final workDir = Directory('${_externalDir.path}/backup_work_$timestamp');
      if (await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
      await workDir.create(recursive: true);

      // Create subdirectories for vault and metadata
      final tempVaultDir = await Directory('${workDir.path}/vault')
          .create(recursive: true);
      final tempMetadataDir = await Directory('${workDir.path}/metadata')
          .create(recursive: true);

      // Prepare backup manifest
      final manifest = {
        'timestamp': timestamp,
        'version': '1.0',
        'filesCount': 0,
        'totalSize': 0,
        'files': [],
      };

      // Copy vault files (.aes) to temp directory
      final vaultFiles = _vaultDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.aes'))
          .toList();

      int fileCount = 0;
      int totalSize = 0;

      for (final file in vaultFiles) {
        final fileName = file.path.split('/').last;
        final fileId = fileName.replaceAll('.aes', '');
        final targetFile = File('${tempVaultDir.path}/$fileName');

        // Copy encrypted file
        await file.copy(targetFile.path);

        // Calculate file size and checksum
        final fileStats = await file.stat();
        final fileSize = fileStats.size;
        final checksum = await _calculateChecksum(file);

        // Add to manifest
        (manifest['files'] as List).add({
          'id': fileId,
          'name': fileName,
          'path': 'vault/$fileName',
          'size': fileSize,
          'checksum': checksum,
          'type': 'data'
        });

        fileCount++;
        totalSize += fileSize;
      }

      // Copy metadata files (.meta) to temp directory
      final metadataFiles = _metadataDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.meta'))
          .toList();

      for (final file in metadataFiles) {
        final fileName = file.path.split('/').last;
        final fileId = fileName.replaceAll('.meta', '');
        final targetFile = File('${tempMetadataDir.path}/$fileName');

        // Copy metadata file
        await file.copy(targetFile.path);

        // Calculate file size and checksum
        final fileStats = await file.stat();
        final fileSize = fileStats.size;
        final checksum = await _calculateChecksum(file);

        // Add to manifest
        (manifest['files'] as List).add({
          'id': fileId,
          'name': fileName,
          'path': 'metadata/$fileName',
          'size': fileSize,
          'checksum': checksum,
          'type': 'metadata'
        });

        totalSize += fileSize;
      }

      // Update manifest with file count and total size
      manifest['filesCount'] = fileCount;
      manifest['totalSize'] = totalSize;

      // Encrypt the manifest
      final key = await _deriveKeyFromPassword(password);
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final encryptedManifest = encrypter.encrypt(jsonEncode(manifest), iv: iv);

      // Save encrypted manifest with IV
      final manifestWrapper = {
        'iv': base64.encode(iv.bytes),
        'data': encryptedManifest.base64,
      };

      final manifestFile = File('${workDir.path}/manifest.enc');
      await manifestFile.writeAsString(jsonEncode(manifestWrapper));

      // Create ZIP archive
      try {
        // Create encoder
        final encoder = ZipFileEncoder();
        encoder.create(backupFile.path);

        // Add all files in work directory to the zip
        await _addDirectoryToZip(encoder, workDir.path, '');

        // Close the encoder when done
        encoder.close();
      } catch (e) {
        print('Error creating ZIP: $e');
        await workDir.delete(recursive: true);
        return null;
      }

      // Clean up work directory
      await workDir.delete(recursive: true);

      return backupFile.path;
    } catch (e) {
      print('Error creating backup: $e');
      return null;
    }
  }

  /// Helper method to add directory contents to zip recursively
  Future<void> _addDirectoryToZip(ZipFileEncoder encoder, String sourcePath, String parentPath) async {
    final sourceDir = Directory(sourcePath);
    final entities = sourceDir.listSync(recursive: false);

    for (final entity in entities) {
      final relativePath = entity.path.substring(sourcePath.length + 1);
      final zipPath = parentPath.isEmpty ? relativePath : '$parentPath/$relativePath';

      if (entity is File) {
        encoder.addFile(entity, zipPath);
      } else if (entity is Directory) {
        final subDir = Directory(entity.path);
        if (subDir.existsSync()) {
          await _addDirectoryToZip(encoder, entity.path, zipPath);
        }
      }
    }
  }

  /// Restore vault from backup
  Future<bool> restoreVault(String backupPath, String password) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        print('Backup file not found');
        return false;
      }

      // Create external restore work directory
      final workDir = Directory('${_externalDir.path}/restore_work_${DateTime.now().millisecondsSinceEpoch}');
      if (await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
      await workDir.create(recursive: true);

      // Extract ZIP archive
      try {
        // Extract the archive to the external work directory
        final bytes = await backupFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        for (final file in archive) {
          final outputPath = '${workDir.path}/${file.name}';

          if (file.isFile) {
            final outputFile = File(outputPath);
            await outputFile.parent.create(recursive: true);
            await outputFile.writeAsBytes(file.content as List<int>);
          } else {
            final outputDir = Directory(outputPath);
            await outputDir.create(recursive: true);
          }
        }
      } catch (e) {
        print('Error extracting ZIP: $e');
        await workDir.delete(recursive: true);
        return false;
      }

      // Read and decrypt manifest
      final manifestFile = File('${workDir.path}/manifest.enc');
      if (!await manifestFile.exists()) {
        print('Manifest file not found in backup');
        await workDir.delete(recursive: true);
        return false;
      }

      try {
        final manifestContent = await manifestFile.readAsString();
        final manifestWrapper = jsonDecode(manifestContent);

        final key = await _deriveKeyFromPassword(password);
        final iv = encrypt.IV.fromBase64(manifestWrapper['iv']);
        final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

        final decryptedManifest = encrypter.decrypt64(manifestWrapper['data'], iv: iv);
        final manifest = jsonDecode(decryptedManifest);

        // Verify backup integrity
        for (final fileInfo in manifest['files']) {
          final path = fileInfo['path'];
          final checksum = fileInfo['checksum'];
          final sourceFile = File('${workDir.path}/$path');

          if (!await sourceFile.exists()) {
            print('Missing file in backup: $path');
            await workDir.delete(recursive: true);
            return false;
          }

          // Verify checksum
          final calculatedChecksum = await _calculateChecksum(sourceFile);
          if (calculatedChecksum != checksum) {
            print('Checksum mismatch for file: $path');
            await workDir.delete(recursive: true);
            return false;
          }
        }
        try {
          await for (final entity in _vaultDir.list()) {
            await entity.delete(recursive: true);
          }
          await for (final entity in _metadataDir.list()) {
            await entity.delete(recursive: true);
          }
        } catch (e) {
          print('Error clearing existing vault: $e');
        }

        for (final fileInfo in manifest['files']) {
          final path = fileInfo['path'];
          final sourceFile = File('${workDir.path}/$path');

          if (path.startsWith('vault/')) {
            final targetFile = File('${_vaultDir.path}/${path.split('/').last}');
            await sourceFile.copy(targetFile.path);
          } else if (path.startsWith('metadata/')) {
            final targetFile = File('${_metadataDir.path}/${path.split('/').last}');
            await sourceFile.copy(targetFile.path);
          }
        }

        // Clean up
        await workDir.delete(recursive: true);
        return true;

      } catch (e) {
        print('Error decrypting manifest: $e');
        await workDir.delete(recursive: true);
        return false;
      }
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }

  /// Clean up external temporary files
  Future<bool> cleanupExternalFiles() async {
    try {
      // Delete temporary directory
      final tempDir = Directory('${_externalDir.path}/temp');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }

      // Recreate empty temporary directory
      await tempDir.create(recursive: true);

      return true;
    } catch (e) {
      print('Error cleaning up external files: $e');
      return false;
    }
  }
}