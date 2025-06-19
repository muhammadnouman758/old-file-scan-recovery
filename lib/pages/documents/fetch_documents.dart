import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DocumentFileFetcher {
  final _folderController = StreamController<Map<String, Set<File>>>.broadcast();
  final _progressController = StreamController<double>.broadcast();
  final _currentPathController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Map<String, Set<File>> _foundFolders = {};
  double _lastProgress = 0.0;
  bool _isDisposed = false;
  static bool _shouldStopScanning = false; // Static flag for scan cancellation

  Stream<Map<String, Set<File>>> get folderStream => _folderController.stream;
  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get currentPathStream => _currentPathController.stream;
  Stream<String> get errorStream => _errorController.stream;

  Future<void> fetchDocumentFiles() async {
    if (_isDisposed) {
      _errorController.add('Fetcher has been disposed');
      return;
    }

    // Reset state for new scan
    _foundFolders = {};
    _lastProgress = 0.0;
    _shouldStopScanning = false;
    _progressController.add(0.0);

    try {
      final folders = await compute(_scanDocuments, null);
      if (!_shouldStopScanning) {
        _foundFolders = folders;
        _folderController.add(Map.from(_foundFolders));
        _progressController.add(100.0);
      }
    } catch (e) {
      if (!_shouldStopScanning) {
        _errorController.add('Failed to scan documents: ${e.toString()}');
        _folderController.add(Map.from(_foundFolders));
        _progressController.add(100.0);
      }
    }
  }

  static Future<Map<String, Set<File>>> _scanDocuments(_) async {
    final folders = <String, Set<File>>{};
    final root = Directory('/storage/emulated/0');

    if (!await root.exists()) {
      return folders;
    }

    int processedFiles = 0;
    const docExtensions = [
      '.pdf', '.txt', '.doc', '.docx',
      '.ppt', '.pptx', '.xls', '.xlsx', '.csv'
    ];

    try {
      await for (final file in _scanDirectory(root, docExtensions)) {
        if (_shouldStopScanning) break;

        final folderPath = file.parent.path;
        folders.putIfAbsent(folderPath, () => <File>{}).add(file);
        processedFiles++;

        // Update progress every 100 files
        if (processedFiles % 100 == 0) {
          debugPrint('Processed $processedFiles files');
        }
      }
    } catch (e) {
      debugPrint('Scan error: $e');
    }

    return folders;
  }

  static Stream<File> _scanDirectory(Directory directory, List<String> docExtensions) async* {
    final List<FileSystemEntity> entities;

    try {
      entities = await directory.list().toList();
    } catch (e) {
      debugPrint('Error scanning ${directory.path}: $e');
      return;
    }

    for (final entity in entities) {
      if (_shouldStopScanning) break;

      if (entity is Directory) {
        // Skip system directories
        if (entity.path.contains('/Android/data') ||
            entity.path.contains('/Android/obb') ||
            entity.path.contains('.thumbnails')) {
          continue;
        }
        yield* _scanDirectory(entity, docExtensions);
      } else if (entity is File) {
        if (docExtensions.any((ext) => entity.path.toLowerCase().endsWith(ext))) {
          yield entity;
        }
      }
    }
  }

  Map<String, Set<File>> get currentFolders => Map.from(_foundFolders);
  double get currentProgress => _lastProgress;

  void dispose() {
    _isDisposed = true;
    _shouldStopScanning = true;
    _folderController.close();
    _progressController.close();
    _currentPathController.close();
    _errorController.close();
  }
}