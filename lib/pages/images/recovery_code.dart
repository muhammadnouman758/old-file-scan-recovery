import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:permission_handler/permission_handler.dart';

class ScanProgress {
  final String currentPath;
  final int foldersScanned;
  final int totalFilesFound;
  final int imageFilesFound;
  final DateTime lastUpdate;

  ScanProgress({
    required this.currentPath,
    required this.foldersScanned,
    required this.totalFilesFound,
    required this.imageFilesFound,
    required this.lastUpdate,
  });
}

abstract class FileScanner {
  Stream<Map<String, Set<File>>> get folderStream;
  Stream<ScanProgress> get progressStream;
  Duration get scanDuration;

  Future<void> fetchImages();
  void cancel();
  void dispose();
}

class FileScannerFactory {
  static FileScanner createScanner(ScanType type) {
    switch (type) {
      case ScanType.quick:
        return QuickFileFetcher();
      case ScanType.deep:
        return DeepFileFetcher();
    }
  }
}

enum ScanType { quick, deep }

class QuickFileFetcher implements FileScanner {
  final _folderStreamController = StreamController<Map<String, Set<File>>>.broadcast();
  final _progressStreamController = StreamController<ScanProgress>.broadcast();
  final _seenFiles = <String>{};

  bool _isRunning = false;
  bool _isCancelled = false;
  Isolate? _isolate;
  ReceivePort? _receivePort;
  int _totalFoldersScanned = 0;
  int _totalFilesFound = 0;
  int _totalImagesFound = 0;
  DateTime? _scanStartTime;
  String _currentScanPath = '';

  @override
  Stream<Map<String, Set<File>>> get folderStream => _folderStreamController.stream;

  @override
  Stream<ScanProgress> get progressStream => _progressStreamController.stream;

  @override
  Duration get scanDuration => _scanStartTime != null
      ? DateTime.now().difference(_scanStartTime!)
      : Duration.zero;

  Future<void> requestPermissions() async {
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }
  }

  static Future<void> _scanFilesInBackground(IsolateMessage message) async {
    final sendPort = message.sendPort;
    final rootDir = Directory(message.directoryPath);

    int foldersScanned = 0;
    int totalFiles = 0;
    int imageFiles = 0;
    final seenFiles = <String>{};

    try {
      await _scanDirectoryRecursively(
          rootDir,
          sendPort,
          seenFiles,
              (currentPath, folderCount, fileCount, imgCount) {
            foldersScanned = folderCount;
            totalFiles = fileCount;
            imageFiles = imgCount;

            sendPort.send({
              'type': 'progress',
              'path': currentPath,
              'folders': foldersScanned,
              'files': totalFiles,
              'images': imageFiles,
            });
          });

      sendPort.send(null);
    } catch (e) {
      sendPort.send(null);
    }
  }

  static Future<void> _scanDirectoryRecursively(
      Directory directory,
      SendPort sendPort,
      Set<String> seenFiles,
      Function(String, int, int, int) progressCallback,
      {int foldersScanned = 0, int totalFiles = 0, int imageFiles = 0}
      ) async {
    if (!await directory.exists()) return;

    try {
      foldersScanned++;
      progressCallback(directory.path, foldersScanned, totalFiles, imageFiles);

      final entities = directory.listSync(recursive: false);
      totalFiles += entities.whereType<File>().length;

      final foundImageFiles = entities
          .whereType<File>()
          .where((file) {
        final path = file.path;
        final isImage = path.toLowerCase().endsWith('.jpg') ||
            path.toLowerCase().endsWith('.jpeg') ||
            path.toLowerCase().endsWith('.png');
        return isImage && !seenFiles.contains(path);
      })
          .map((file) {
        seenFiles.add(file.path);
        return file.path;
      })
          .toList();

      imageFiles += foundImageFiles.length;

      if (foundImageFiles.isNotEmpty) {
        final folderName = directory.path.split('/').last;
        sendPort.send({
          'type': 'folder',
          'name': folderName,
          'files': foundImageFiles,
          'path': directory.path,
        });
      }

      final directories = entities
          .whereType<Directory>()
          .where((dir) => !dir.path.contains('/Android'))
          .toList();

      for (final subDir in directories) {
        await _scanDirectoryRecursively(
            subDir,
            sendPort,
            seenFiles,
            progressCallback,
            foldersScanned: foldersScanned,
            totalFiles: totalFiles,
            imageFiles: imageFiles
        );
      }
    } catch (e) {
      // Skip errors
    }
  }

  @override
  Future<void> fetchImages() async {
    if (_isRunning) return;

    _isRunning = true;
    _isCancelled = false;
    _seenFiles.clear();
    _totalFoldersScanned = 0;
    _totalFilesFound = 0;
    _totalImagesFound = 0;
    _scanStartTime = DateTime.now();
    _currentScanPath = '';

    await requestPermissions();

    final folderMap = <String, Set<File>>{};
    _receivePort = ReceivePort();

    _receivePort!.listen((dynamic message) {
      if (_isCancelled) return;

      if (message == null) {
        _cleanupIsolate();
        _isRunning = false;

        if (!_progressStreamController.isClosed) {
          _progressStreamController.add(ScanProgress(
            currentPath: 'Scan completed',
            foldersScanned: _totalFoldersScanned,
            totalFilesFound: _totalFilesFound,
            imageFilesFound: _totalImagesFound,
            lastUpdate: DateTime.now(),
          ));
          _progressStreamController.close();
        }

        if (!_folderStreamController.isClosed) {
          _folderStreamController.add(Map.from(folderMap));
          _folderStreamController.close();
        }
        return;
      }

      if (message is Map) {
        if (message['type'] == 'progress') {
          _currentScanPath = message['path'];
          _totalFoldersScanned = message['folders'];
          _totalFilesFound = message['files'];
          _totalImagesFound = message['images'];

          if (!_progressStreamController.isClosed) {
            _progressStreamController.add(ScanProgress(
              currentPath: _currentScanPath,
              foldersScanned: _totalFoldersScanned,
              totalFilesFound: _totalFilesFound,
              imageFilesFound: _totalImagesFound,
              lastUpdate: DateTime.now(),
            ));
          }
        } else if (message['type'] == 'folder') {
          final folderName = message['name'];
          final newFiles = (message['files'] as List<String>)
              .where((path) => !_seenFiles.contains(path))
              .map((path) => File(path))
              .toList();

          if (newFiles.isNotEmpty) {
            _seenFiles.addAll(newFiles.map((f) => f.path));
            folderMap[folderName] = folderMap[folderName] ?? <File>{};
            folderMap[folderName]!.addAll(newFiles);

            if (!_folderStreamController.isClosed) {
              _folderStreamController.add(Map.from(folderMap));
            }
          }
        }
      }
    });

    final isolateMessage = IsolateMessage('/storage/emulated/0', _receivePort!.sendPort);
    _isolate = await Isolate.spawn(_scanFilesInBackground, isolateMessage);
  }

  void _cleanupIsolate() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
  }

  @override
  void cancel() {
    _isCancelled = true;
    _cleanupIsolate();
  }

  @override
  void dispose() {
    cancel();
    _seenFiles.clear();
    if (!_folderStreamController.isClosed) {
      _folderStreamController.close();
    }
    if (!_progressStreamController.isClosed) {
      _progressStreamController.close();
    }
  }
}

class DeepFileFetcher implements FileScanner {
  final _folderStreamController = StreamController<Map<String, Set<File>>>.broadcast();
  final _progressStreamController = StreamController<ScanProgress>.broadcast();
  final _seenFiles = <String>{};
  final _folderMap = <String, Set<File>>{};

  bool _isRunning = false;
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  DateTime _startTime = DateTime.now();

  // Fixed: Changed to static const
  static const _fileSignatures = {
    'jpeg': [0xFF, 0xD8, 0xFF],
    'png': [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    'gif': [0x47, 0x49, 0x46, 0x38],
    'bmp': [0x42, 0x4D],
    'webp': [0x52, 0x49, 0x46, 0x46],
  };

  static const _minImageSize = 1024;
  static const _maxImageSize = 20 * 1024 * 1024;
  static const _blockSize = 4096;

  @override
  Stream<Map<String, Set<File>>> get folderStream => _folderStreamController.stream;

  @override
  Stream<ScanProgress> get progressStream => _progressStreamController.stream;

  @override
  Duration get scanDuration => _isRunning
      ? DateTime.now().difference(_startTime)
      : Duration.zero;

  @override
  Future<void> fetchImages() async {
    if (_isRunning) return;

    _isRunning = true;
    _startTime = DateTime.now();
    _seenFiles.clear();
    _folderMap.clear();

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntryPoint, _receivePort!.sendPort);

    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        _sendPort!.send({'command': 'start'});
      } else if (message is Map && message.containsKey('folderUpdate')) {
        _updateFolders(message['folderUpdate'] as Map<String, Set<File>>);
      } else if (message is Map && message.containsKey('progress')) {
        final progress = message['progress'] as Map<String, dynamic>;
        _updateProgress(
          progress['currentPath'] as String,
          progress['foldersScanned'] as int,
          progress['totalFilesFound'] as int,
          progress['imageFilesFound'] as int,
        );
      } else if (message == 'done') {
        _cleanupIsolate();
        _folderStreamController.add(_folderMap);
        _folderStreamController.close();
        _progressStreamController.close();
        _isRunning = false;
      }
    });
  }

  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message is Map && message['command'] == 'start') {
        _startScanningInIsolate(sendPort);
      } else if (message == 'cancel') {
        sendPort.send('done');
        Isolate.exit();
      }
    });
  }

  static Future<void> _startScanningInIsolate(SendPort sendPort) async {
    int foldersScanned = 0;
    int totalFilesFound = 0;
    int imageFilesFound = 0;
    final folderMap = <String, Set<File>>{};
    final seenFiles = <String>{};

    final emulatedDir = Directory('/storage/emulated/0');
    if (!emulatedDir.existsSync()) {
      sendPort.send('done');
      return;
    }

    _sendProgressUpdate(sendPort, emulatedDir.path, foldersScanned, totalFilesFound, imageFilesFound);

    await _scanDirectoryForImages(
        emulatedDir,
        sendPort,
        folderMap,
        seenFiles,
        foldersScanned,
        totalFilesFound,
        imageFilesFound
    );

    sendPort.send({'folderUpdate': folderMap});
    sendPort.send('done');
  }

  static Future<void> _scanDirectoryForImages(
      Directory directory,
      SendPort sendPort,
      Map<String, Set<File>> folderMap,
      Set<String> seenFiles,
      int foldersScanned,
      int totalFilesFound,
      int imageFilesFound
      ) async {
    try {
      foldersScanned++;
      _sendProgressUpdate(sendPort, directory.path, foldersScanned, totalFilesFound, imageFilesFound);

      final entities = await directory.list().toList();

      for (final entity in entities) {
        final entityPath = entity.path;
        final entityName = entityPath.split('/').last.toLowerCase();

        if ((entityName == 'android' && (entityPath.contains('/data') || entityPath.contains('/obb'))) ||
            entityPath.contains('/Android/data') ||
            entityPath.contains('/Android/obb')) {
          continue;
        }

        if (entity is Directory) {
          if (!entityName.startsWith('.') &&
              entityName != 'recoveredimages' &&
              !entityName.contains('cache')) {
            await _scanDirectoryForImages(
                entity,
                sendPort,
                folderMap,
                seenFiles,
                foldersScanned,
                totalFilesFound,
                imageFilesFound
            );
          }
        } else if (entity is File && !seenFiles.contains(entityPath)) {
          totalFilesFound++;
          seenFiles.add(entityPath);

          if (await _isImageFile(entity)) {
            imageFilesFound++;
            final folderPath = directory.path;
            folderMap.putIfAbsent(folderPath, () => {}).add(entity);

            if (imageFilesFound % 10 == 0 || folderMap.keys.length % 5 == 0) {
              sendPort.send({'folderUpdate': folderMap});
              _sendProgressUpdate(
                  sendPort,
                  directory.path,
                  foldersScanned,
                  totalFilesFound,
                  imageFilesFound
              );
            }
          }
        }
      }
    } catch (e) {
      // Skip errors
    }
  }

  static Future<bool> _isImageFile(File file) async {
    try {
      final fileName = file.path.toLowerCase();
      if (fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.png') ||
          fileName.endsWith('.gif') ||
          fileName.endsWith('.bmp') ||
          fileName.endsWith('.webp')) {
        return true;
      }

      final raf = await file.open(mode: FileMode.read);
      try {
        final fileSize = await raf.length();
        if (fileSize < _minImageSize) return false;

        final buffer = await raf.read(32);
        for (final signature in _fileSignatures.values) {
          if (buffer.length >= signature.length) {
            bool matches = true;
            for (int i = 0; i < signature.length; i++) {
              if (buffer[i] != signature[i]) {
                matches = false;
                break;
              }
            }
            if (matches) return true;
          }
        }
        return false;
      } finally {
        await raf.close();
      }
    } catch (e) {
      return false;
    }
  }

  void _updateFolders(Map<String, Set<File>> update) {
    for (final entry in update.entries) {
      final newFiles = entry.value.where((file) => !_seenFiles.contains(file.path)).toList();
      if (newFiles.isNotEmpty) {
        _seenFiles.addAll(newFiles.map((f) => f.path));
        _folderMap.putIfAbsent(entry.key, () => {}).addAll(newFiles);
      }
    }
    _folderStreamController.add(_folderMap);
  }

  void _updateProgress(String currentPath, int foldersScanned, int totalFilesFound, int imageFilesFound) {
    _progressStreamController.add(ScanProgress(
      currentPath: currentPath,
      foldersScanned: foldersScanned,
      totalFilesFound: totalFilesFound,
      imageFilesFound: imageFilesFound,
      lastUpdate: DateTime.now(),
    ));
  }

  static void _sendProgressUpdate(
      SendPort sendPort,
      String currentPath,
      int foldersScanned,
      int totalFilesFound,
      int imageFilesFound
      ) {
    sendPort.send({
      'progress': {
        'currentPath': currentPath,
        'foldersScanned': foldersScanned,
        'totalFilesFound': totalFilesFound,
        'imageFilesFound': imageFilesFound,
      }
    });
  }

  @override
  void cancel() {
    if (_isRunning && _sendPort != null) {
      _sendPort!.send('cancel');
      _cleanupIsolate();
      _isRunning = false;
    }
  }

  void _cleanupIsolate() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;
  }

  @override
  void dispose() {
    cancel();
    _seenFiles.clear();
    if (!_folderStreamController.isClosed) {
      _folderStreamController.close();
    }
    if (!_progressStreamController.isClosed) {
      _progressStreamController.close();
    }
  }
}

class IsolateMessage {
  final String directoryPath;
  final SendPort sendPort;

  IsolateMessage(this.directoryPath, this.sendPort);
}