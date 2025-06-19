import 'dart:async';
import 'dart:io';
import 'dart:isolate';

class AudioFileFetcher {
  // Use BehaviorSubject-like streams to maintain last value
  final _folderController = StreamController<Map<String, Set<File>>>.broadcast();
  final _progressController = StreamController<double>.broadcast();
  final _currentPathController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Cache for maintaining state
  Map<String, Set<File>> _foundFolders = {};
  double _lastProgress = 0.0;

  Stream<Map<String, Set<File>>> get folderStream => _folderController.stream;
  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get currentPathStream => _currentPathController.stream;
  Stream<String> get errorStream => _errorController.stream;

  Isolate? _isolate;
  ReceivePort? _receivePort;
  bool _isDisposed = false;
  bool _isScanning = false;

  // Configuration
  static const _excludedPaths = [
    '/Android/data',
    '/Android/obb',
    '/WhatsApp Business',
    '/com.whatsapp.w4b',
    '/.thumbnails',
  ];

  static const _audioExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.flac', '.ogg'];
  static const _operationTimeout = Duration(seconds: 3);
  static const _progressUpdateThreshold = 50;
  static const _batchSize = 200;

  Future<void> fetchAudioFiles() async {
    if (_isScanning) {
      _errorController.add('Scan already in progress');
      return;
    }

    _isScanning = true;
    _isDisposed = false;
    _foundFolders = {};
    _lastProgress = 0.0;
    _receivePort = ReceivePort();

    try {
      _isolate = await Isolate.spawn(
        _scanAudioFiles,
        _receivePort!.sendPort,
        debugName: 'AudioFileScanner',
      );

      _receivePort!.listen(_handleIsolateMessage, onDone: _cleanUp);
    } catch (e) {
      _errorController.add('Failed to start scan: ${e.toString()}');
      _cleanUp();
      _isScanning = false;
    }
  }

  void _handleIsolateMessage(dynamic data) {
    if (_isDisposed) return;

    if (data is Map<String, dynamic>) {
      if (data.containsKey('folders')) {
        try {
          final dynamicFolders = data['folders'] as Map<dynamic, dynamic>;

          // Merge new results with existing ones
          dynamicFolders.forEach((key, value) {
            if (key is String && value is Set<dynamic>) {
              _foundFolders[key] = (value.whereType<File>().toSet())..addAll(_foundFolders[key] ?? {});
            }
          });

          // Emit the complete current state
          _folderController.add(Map.from(_foundFolders));
        } catch (e) {
          _errorController.add('Error processing results: ${e.toString()}');
        }
      } else if (data.containsKey('progress')) {
        _lastProgress = data['progress'] as double;
        _progressController.add(_lastProgress);

        if (_lastProgress == 100.0) {
          _cleanUp();
        }
      } else if (data.containsKey('path')) {
        _currentPathController.add(data['path'] as String);
      } else if (data.containsKey('error')) {
        _errorController.add(data['error'] as String);
      }
    }
  }

  static void _scanAudioFiles(SendPort sendPort) {
    final folders = <String, Set<File>>{};
    final rootDir = Directory('/storage/emulated/0');
    int totalEstimatedFiles = 10000;
    int scannedFiles = 0;
    int lastProgressReport = 0;

    void reportProgress() {
      final progress = (scannedFiles / totalEstimatedFiles * 100).clamp(0.0, 99.0);
      sendPort.send({'progress': progress});
    }

    void reportPath(String path) {
      sendPort.send({'path': path});
    }

    void reportError(String error) {
      sendPort.send({'error': error});
    }

    Future<void> scanDirectory(Directory dir) async {
      final dirPath = dir.path;

      for (final excluded in _excludedPaths) {
        if (dirPath.contains(excluded)) {
          return;
        }
      }

      reportPath(dirPath);

      List<FileSystemEntity> entities;
      try {
        entities = await dir.list().timeout(_operationTimeout).toList();
      } on TimeoutException {
        reportError('Timeout scanning $dirPath');
        return;
      } catch (e) {
        reportError('Error scanning $dirPath: ${e.toString()}');
        return;
      }

      for (final entity in entities) {
        try {
          if (entity is Directory) {
            await scanDirectory(entity);
          } else if (entity is File) {
            scannedFiles++;

            if (scannedFiles - lastProgressReport >= _progressUpdateThreshold) {
              lastProgressReport = scannedFiles;
              reportProgress();
            }

            if (scannedFiles > totalEstimatedFiles * 0.8) {
              totalEstimatedFiles = (scannedFiles * 1.5).toInt();
            }

            if (_isAudioFile(entity.path)) {
              final folderPath = entity.parent.path;
              folders.putIfAbsent(folderPath, () => <File>{}).add(entity);

              // Send incremental updates instead of clearing
              if (folders.length % _batchSize == 0) {
                sendPort.send({'folders': Map.from(folders)});
              }
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    scanDirectory(rootDir).then((_) {
      // Send final results without clearing
      sendPort.send({'folders': Map.from(folders)});
      sendPort.send({'progress': 100.0});
    }).catchError((e) {
      sendPort.send({'folders': Map.from(folders)});
      sendPort.send({'progress': 100.0});
      sendPort.send({'error': 'Scan failed: ${e.toString()}'});
    });
  }

  static bool _isAudioFile(String path) {
    final lowercasePath = path.toLowerCase();
    return _audioExtensions.any((ext) => lowercasePath.endsWith(ext));
  }

  void _cleanUp() {
    if (!_isDisposed) {
      _receivePort?.close();
      _receivePort = null;
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      _isScanning = false;
    }
  }

  void dispose() {
    _isDisposed = true;
    _cleanUp();
    _folderController.close();
    _progressController.close();
    _currentPathController.close();
    _errorController.close();
  }

  // Get current state
  Map<String, Set<File>> get currentFolders => Map.from(_foundFolders);
  double get currentProgress => _lastProgress;
}