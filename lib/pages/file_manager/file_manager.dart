import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class OldFileManager {
  static const String _mainFolder = "Old File Scan";
  static const String _videoFolder = "Videos";
  static const String _audioFolder = "Audio";
  static const String _imageFolder = "Images";
  static const String _docsFolder = "Docs";

  static Future<String> _getBasePath() async {
    Directory? directory = await getDownloadsDirectory();
    if (directory == null) {
      throw Exception("Downloads directory not found");
    }
    return directory.path;
  }

  static Future<void> createMainFolder() async {
    if (await _requestPermission()) {
      String basePath = await _getBasePath();
      Directory mainDir = Directory("$basePath/$_mainFolder");

      if (!await mainDir.exists()) {
        await mainDir.create(recursive: true);
      }
      await _createSubFolder(_videoFolder);
      await _createSubFolder(_audioFolder);
      await _createSubFolder(_imageFolder);
      await _createSubFolder(_docsFolder);
    }
  }

  static Future<void> _createSubFolder(String folderName) async {
    String basePath = await _getBasePath();
    Directory subDir = Directory("$basePath/$_mainFolder/$folderName");

    if (!await subDir.exists()) {
      await subDir.create(recursive: true);
    }
  }

  static Future<String> saveFile(File file, String fileType) async {
    String folderName = _docsFolder;
    if (fileType.contains("video")) {
      folderName = _videoFolder;
    } else if (fileType.contains("audio")) {
      folderName = _audioFolder;
    } else if (fileType.contains("image")) {
      folderName = _imageFolder;
    }

    String basePath = await _getBasePath();
    String targetPath = "$basePath/$_mainFolder/$folderName/${file.path.split('/').last}";
    var fil = await file.copy(targetPath);
    return fil.path;
  }

  static Future<bool> _requestPermission() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    int sdkInt = androidInfo.version.sdkInt ?? 0;

    if (sdkInt >= 30) {
      return await Permission.manageExternalStorage.request().isGranted;
    } else {
      return await Permission.storage.request().isGranted;
    }
  }
}