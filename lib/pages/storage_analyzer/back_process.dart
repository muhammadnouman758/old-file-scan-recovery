import 'dart:io';
import 'dart:async';

class StorageAnalyzer {
  // Common file extensions by category
  static const Map<String, List<String>> _categoryExtensions = {
    'Images': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'svg', 'tiff'],
    'Videos': ['mp4', 'mkv', 'avi', 'mov', '3gp', 'webm', 'flv', 'wmv'],
    'Documents': ['pdf', 'doc', 'docx', 'xlsx', 'xls', 'pptx', 'ppt', 'txt', 'rtf', 'csv', 'odt'],
    'Audio': ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma'],
    'Compressed': ['zip', 'rar', '7z', 'tar', 'gz', 'tgz', 'bz2'],
    'APK': ['apk'],
  };

  // Directories to skip for better performance
  static const List<String> _excludedDirs = [
    '/Android/data',
    '/Android/obb',
    '/Android/media',
    '.thumbnail',
    '.tmp',
    '.cache',
    '.Trash'
  ];

  static Future<Map<String, int>> analyzeStorage() async {
    const rootPath = '/storage/emulated/0';
    final Directory rootDirectory = Directory(rootPath);

    // Initialize categories with zeros
    final Map<String, int> fileCategories = {
      for (String category in _categoryExtensions.keys) category: 0,
      'Other': 0,
      'Total': 0,
    };

    if (!await rootDirectory.exists()) {
      return fileCategories; // Return empty results if directory doesn't exist
    }

    await _scanDirectory(rootDirectory, fileCategories);

    return fileCategories;
  }

  static Future<void> _scanDirectory(Directory dir, Map<String, int> fileCategories) async {
    try {
      List<FileSystemEntity> entities = await dir.list(followLinks: false).toList();

      for (var entity in entities) {
        final String path = entity.path;

        // Skip excluded directories
        if (entity is Directory && _shouldSkipDirectory(path)) {
          continue;
        }

        if (entity is File) {
          _categorizeFile(entity, fileCategories);
        } else if (entity is Directory) {
          await _scanDirectory(entity, fileCategories);
        }
      }
    } catch (e) {
      // Silently continue on errors (permission issues, etc.)
    }
  }

  static bool _shouldSkipDirectory(String path) {
    return _excludedDirs.any((excluded) => path.contains(excluded));
  }

  static void _categorizeFile(File file, Map<String, int> fileCategories) {
    try {
      int fileSize = file.lengthSync(); // Sync for better performance in this case
      if (fileSize <= 0) return;

      String ext = file.path.split('.').last.toLowerCase();
      bool categorized = false;

      // Find the category for this extension
      for (var entry in _categoryExtensions.entries) {
        if (entry.value.contains(ext)) {
          fileCategories[entry.key] = fileCategories[entry.key]! + fileSize;
          categorized = true;
          break;
        }
      }

      // If not found in any category, mark as Other
      if (!categorized) {
        fileCategories['Other'] = fileCategories['Other']! + fileSize;
      }

      // Update total size
      fileCategories['Total'] = fileCategories['Total']! + fileSize;
    } catch (e) {
      // Silently handle errors for individual files
    }
  }
}