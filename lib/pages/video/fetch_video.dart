import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class VideoFetcher {
  final StreamController<Map<String, List<Map<String, dynamic>>>> _folderStreamController =
  StreamController.broadcast();
  final StreamController<int> _scannedFilesStreamController = StreamController.broadcast();
  final StreamController<double> _progressStreamController = StreamController.broadcast();
  final StreamController<String> _currentFolderStreamController = StreamController.broadcast();
  final StreamController<String?> _errorStreamController = StreamController.broadcast();

  final Map<String, List<Map<String, dynamic>>> _folders = {};
  int _filesScanned = 0;
  double _progress = 0.0;
  final List<String> _videoExtensions = ['.mp4', '.mkv', '.avi', '.mov', '.flv', '.wmv'];
  final int _batchSize = 5;
  bool _isScanning = false;
  bool _cancelRequested = false;
  Completer<void>? _scanCompleter;
  Stream<Map<String, List<Map<String, dynamic>>>> get folderStream => _folderStreamController.stream;
  Stream<int> get scannedFilesStream => _scannedFilesStreamController.stream;
  Stream<double> get progressStream => _progressStreamController.stream;
  Stream<String> get currentFolderStream => _currentFolderStreamController.stream;
  Stream<String?> get errorStream => _errorStreamController.stream;

  bool get isScanning => _isScanning;

  Future<void> fetchVideoFiles() async {
    if (_isScanning) {
      return;
    }

    _isScanning = true;
    _cancelRequested = false;
    _scanCompleter = Completer();

    try {

      _folders.clear();
      _filesScanned = 0;
      _progress = 0.0;
      _scannedFilesStreamController.add(_filesScanned);
      _progressStreamController.add(_progress);
      _folderStreamController.add(_folders);
      _errorStreamController.add(null);
      _currentFolderStreamController.add("Starting scan...");
      _currentFolderStreamController.add("Searching for video files...");

      final List<String> videoFilePaths = await compute(_findVideoFiles, {
        'rootPath': '/storage/emulated/0',
        'extensions': _videoExtensions,
      });

      _currentFolderStreamController.add("Found ${videoFilePaths.length} video files");
      final tempDir = await getTemporaryDirectory();
      int totalFiles = videoFilePaths.length;
      int processedFiles = 0;
      for (int i = 0; i < videoFilePaths.length && !_cancelRequested; i += _batchSize) {
        final int end = (i + _batchSize < videoFilePaths.length) ? i + _batchSize : videoFilePaths.length;
        final List<String> batch = videoFilePaths.sublist(i, end);
        for (final String videoPath in batch) {
          if (_cancelRequested) break;

          final String folderName = videoPath.split('/').reversed.skip(1).first;
          _currentFolderStreamController.add("Processing: $folderName");

          try {
            final String fileHash = md5.convert(utf8.encode(videoPath)).toString();
            final String cachedThumbnailPath = '${tempDir.path}/$fileHash.png';
            final File cachedThumbnail = File(cachedThumbnailPath);

            String thumbnailPath = '';

            if (await cachedThumbnail.exists()) {
              thumbnailPath = cachedThumbnailPath;
            } else {
              final result = await VideoThumbnail.thumbnailFile(
                video: videoPath,
                thumbnailPath: cachedThumbnailPath,
                imageFormat: ImageFormat.PNG,
                maxWidth: 180,
                maxHeight: 120,
                quality: 50,
              );

              thumbnailPath = result.path;
                        }

            if (thumbnailPath.isNotEmpty) {
              if (!_folders.containsKey(folderName)) {
                _folders[folderName] = [];
              }

              _folders[folderName]!.add({
                'file': videoPath,
                'thumbnail': thumbnailPath,
                'folderName': folderName,
              });

              _folderStreamController.add(Map.from(_folders));
            }
          } catch (e) {
            print("Error processing $videoPath: $e");
          }
          processedFiles++;
          _filesScanned = processedFiles;
          _scannedFilesStreamController.add(_filesScanned);
          _progress = totalFiles > 0 ? processedFiles / totalFiles : 0.0;
          _progressStreamController.add(_progress);
          await Future.delayed(const Duration(milliseconds: 5));
        }
      }

      _currentFolderStreamController.add("Scan completed");

    } catch (e) {
      print("Error in scan process: $e");
      _errorStreamController.add("Error in scan process: $e");
    } finally {
      _isScanning = false;
      _scanCompleter?.complete();
    }
  }


  void cancelScan() {
    if (_isScanning) {
      _cancelRequested = true;
      _isScanning = false;
      _currentFolderStreamController.add("Scan canceled");
      _scanCompleter?.complete();
    }
  }
  void dispose() {
    cancelScan();
    _folderStreamController.close();
    _scannedFilesStreamController.close();
    _progressStreamController.close();
    _currentFolderStreamController.close();
    _errorStreamController.close();
  }
}
List<String> _findVideoFiles(Map<String, dynamic> params) {
  final String rootPath = params['rootPath'];
  final List<String> extensions = params['extensions'];
  final List<String> videoFilePaths = [];

  try {
    final directory = Directory(rootPath);
    List<Directory> queue = [directory];

    while (queue.isNotEmpty) {
      Directory currentDir = queue.removeAt(0);

      try {
        List<FileSystemEntity> entities = currentDir.listSync(followLinks: false);

        for (final entity in entities) {
          if (entity is Directory) {
            if (entity.path.contains('/Android')) continue;
            queue.add(entity);
          } else if (entity is File) {
            final String extension = '.${entity.path.split('.').last.toLowerCase()}';
            if (extensions.contains(extension)) {
              videoFilePaths.add(entity.path);
            }
          }
        }
      } catch (e) {
        print("Error listing directory ${currentDir.path}: $e");
      }
    }
  } catch (e) {
    print("Error in finding video files: $e");
  }

  return videoFilePaths;
}