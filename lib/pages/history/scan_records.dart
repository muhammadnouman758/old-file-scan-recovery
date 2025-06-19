import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

enum SortType { name, date, size }
enum SortDirection { ascending, descending }

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'files.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tables will be created dynamically as needed
  }
  Future<dynamic> getDataFromTable(String tableName) async {
    try {
      dynamic results = await _database?.query(tableName);
      return results;
    } catch (e) {
      print("Error accessing database: $e");
      return [];
    }
  }


  Future<void> _createTableIfNotExists(String tableName) async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_name TEXT,
        file_path TEXT UNIQUE,
        folder_name TEXT,
        file_type TEXT,
        scan_date TEXT,
        file_size INTEGER
      )
    ''');
  }

  Future<int> insertFile(String tableName, Map<String, dynamic> file) async {
    final db = await database;
    await _createTableIfNotExists(tableName);
    return await db.insert(
      tableName,
      file,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getFiles(String tableName, {SortType sortType = SortType.date, SortDirection sortDirection = SortDirection.descending}) async {
    final db = await database;
    await _createTableIfNotExists(tableName);
    String sortColumn = _getSortColumn(sortType);
    String orderBy = '$sortColumn ${sortDirection == SortDirection.ascending ? 'ASC' : 'DESC'}';
    return await db.query(
      tableName,
      orderBy: orderBy,
    );
  }

  String _getSortColumn(SortType sortType) {
    switch (sortType) {
      case SortType.name:
        return 'file_name';
      case SortType.date:
        return 'scan_date';
      case SortType.size:
        return 'file_size';
    }
  }

  Future<int> deleteFile(String tableName, int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getFileById(String tableName, int id) async {
    final db = await database;
    await _createTableIfNotExists(tableName);
    final List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateFile(String tableName, Map<String, dynamic> file) async {
    final db = await database;
    return await db.update(
      tableName,
      file,
      where: 'id = ?',
      whereArgs: [file['id']],
    );
  }

  Future<void> clearTable(String tableName) async {
    final db = await database;
    await db.delete(tableName);
  }

  Future<List<Map<String, dynamic>>> searchFiles(String tableName, String query, {SortType sortType = SortType.date, SortDirection sortDirection = SortDirection.descending}) async {
    final db = await database;
    await _createTableIfNotExists(tableName);
    String sortColumn = _getSortColumn(sortType);
    String orderBy = '$sortColumn ${sortDirection == SortDirection.ascending ? 'ASC' : 'DESC'}';
    return await db.query(
      tableName,
      where: 'file_name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: orderBy,
    );
  }

  Future<List<Map<String, dynamic>>> advancedSearch(String tableName, String query, {SortType sortType = SortType.date, SortDirection sortDirection = SortDirection.descending}) async {
    final db = await database;
    await _createTableIfNotExists(tableName);
    String sortColumn = _getSortColumn(sortType);
    String orderBy = '$sortColumn ${sortDirection == SortDirection.ascending ? 'ASC' : 'DESC'}';
    return await db.query(
      tableName,
      where: 'file_name LIKE ? OR file_type LIKE ? OR file_path LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: orderBy,
    );
  }

  Future<void> closeDatabase() async {
    final db = await database;
    db.close();
  }
}
class FileManager {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<bool> saveFile(Map<String, dynamic> fileData) async {
    try {
      final tableName = fileData['folder_name'];
      final result = await _dbHelper.insertFile(tableName, fileData);
      return result > 0;
    } catch (e) {
      print('Error saving file: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getFilesByType(String fileType, {SortType sortType = SortType.date, SortDirection sortDirection = SortDirection.descending}) async {
    try {
      return await _dbHelper.getFiles(fileType, sortType: sortType, sortDirection: sortDirection);
    } catch (e) {
      print('Error getting files: $e');
      return [];
    }
  }

  Future<bool> deleteFile(String tableName, int id) async {
    try {
      final file = await _dbHelper.getFileById(tableName, id);
      if (file != null) {
        final filePath = file['file_path'];
        final fileExists = await File(filePath).exists();
        if (fileExists) {
          await File(filePath).delete();
        }
        final result = await _dbHelper.deleteFile(tableName, id);
        return result > 0;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  Future<File?> getFileFromPath(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Error accessing file: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchFilesByName(String fileType, String query, {SortType sortType = SortType.date, SortDirection sortDirection = SortDirection.descending}) async {
    try {
      return await _dbHelper.searchFiles(fileType, query, sortType: sortType, sortDirection: sortDirection);
    } catch (e) {
      print('Error searching files: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> advancedSearchFiles(String fileType, String query, {SortType sortType = SortType.date, SortDirection sortDirection = SortDirection.descending}) async {
    try {
      return await _dbHelper.advancedSearch(fileType, query, sortType: sortType, sortDirection: sortDirection);
    } catch (e) {
      print('Error performing advanced search: $e');
      return [];
    }
  }
}

abstract class ScanHistoryEvent {}

class LoadScans extends ScanHistoryEvent {
  final String fileType;
  final SortType sortType;
  final SortDirection sortDirection;
  LoadScans(this.fileType, {this.sortType = SortType.date, this.sortDirection = SortDirection.descending});
}

class DeleteScan extends ScanHistoryEvent {
  final int id;
  final String fileType;
  DeleteScan(this.id, this.fileType);
}

class SearchScans extends ScanHistoryEvent {
  final String fileType;
  final String query;
  final SortType sortType;
  final SortDirection sortDirection;
  SearchScans(this.fileType, this.query, {this.sortType = SortType.date, this.sortDirection = SortDirection.descending});
}

class SortScans extends ScanHistoryEvent {
  final String fileType;
  final SortType sortType;
  final SortDirection sortDirection;
  SortScans(this.fileType, this.sortType, this.sortDirection);
}

abstract class ScanHistoryState {}

class ScanHistoryInitial extends ScanHistoryState {}

class ScanHistoryLoading extends ScanHistoryState {}

class ScanHistoryLoaded extends ScanHistoryState {
  final List<Map<String, dynamic>> scans;
  final SortType sortType;
  final SortDirection sortDirection;
  ScanHistoryLoaded(this.scans, {this.sortType = SortType.date, this.sortDirection = SortDirection.descending});
}

class ScanHistoryError extends ScanHistoryState {
  final String message;
  ScanHistoryError(this.message);
}
class ScanHistoryBloc extends Bloc<ScanHistoryEvent, ScanHistoryState> {
  final FileManager _fileManager = FileManager();

  ScanHistoryBloc() : super(ScanHistoryInitial()) {
    on<LoadScans>(_onLoadScans);
    on<DeleteScan>(_onDeleteScan);
    on<SearchScans>(_onSearchScans);
    on<SortScans>(_onSortScans);
  }

  Future<void> _onLoadScans(LoadScans event, Emitter<ScanHistoryState> emit) async {
    emit(ScanHistoryLoading());
    try {
      final scans = await _fileManager.getFilesByType(event.fileType, sortType: event.sortType, sortDirection: event.sortDirection);
      emit(ScanHistoryLoaded(scans, sortType: event.sortType, sortDirection: event.sortDirection));
    } catch (e) {
      emit(ScanHistoryError('Failed to load ${event.fileType} files: $e'));
    }
  }

  Future<void> _onDeleteScan(DeleteScan event, Emitter<ScanHistoryState> emit) async {
    try {
      final success = await _fileManager.deleteFile(event.fileType, event.id);
      if (success) {
        add(LoadScans(event.fileType));
      } else {
        emit(ScanHistoryError('Failed to delete file'));
      }
    } catch (e) {
      emit(ScanHistoryError('Error while deleting file: $e'));
    }
  }

  Future<void> _onSearchScans(SearchScans event, Emitter<ScanHistoryState> emit) async {
    emit(ScanHistoryLoading());
    try {
      List<Map<String, dynamic>> results;
      if (event.query.isEmpty) {
        results = await _fileManager.getFilesByType(event.fileType, sortType: event.sortType, sortDirection: event.sortDirection);
      } else {
        results = await _fileManager.advancedSearchFiles(event.fileType, event.query, sortType: event.sortType, sortDirection: event.sortDirection);
        if (results.isEmpty) {
          results = await _fileManager.searchFilesByName(event.fileType, event.query, sortType: event.sortType, sortDirection: event.sortDirection);
        }
        if (results.isEmpty) {
          final allScans = await _fileManager.getFilesByType(event.fileType, sortType: event.sortType, sortDirection: event.sortDirection);
          results = allScans.where((scan) {
            final fileName = scan['file_name'].toString().toLowerCase();
            final filePath = scan['file_path'].toString().toLowerCase();
            final fileType = scan['file_type'].toString().toLowerCase();
            final query = event.query.toLowerCase();
            return fileName.contains(query) || filePath.contains(query) || fileType == query;
          }).toList();
        }
      }
      emit(ScanHistoryLoaded(results, sortType: event.sortType, sortDirection: event.sortDirection));
    } catch (e) {
      emit(ScanHistoryError('Search failed: $e'));
    }
  }

  Future<void> _onSortScans(SortScans event, Emitter<ScanHistoryState> emit) async {
    emit(ScanHistoryLoading());
    try {
      final scans = await _fileManager.getFilesByType(event.fileType, sortType: event.sortType, sortDirection: event.sortDirection);
      emit(ScanHistoryLoaded(scans, sortType: event.sortType, sortDirection: event.sortDirection));
    } catch (e) {
      emit(ScanHistoryError('Failed to sort ${event.fileType} files: $e'));
    }
  }
}

class FileScannerService {
  final FileManager _fileManager = FileManager();

  Future<Map<String, dynamic>> scanFile(File file, String category) async {
    final fileName = file.path.split('/').last;
    final fileType = fileName.split('.').last;
    final fileSize = await file.length();

    final fileData = {
      'file_name': fileName,
      'file_path': file.path,
      'folder_name': category,
      'file_type': fileType,
      'scan_date': DateTime.now().toIso8601String(),
      'file_size': fileSize,
    };

    final success = await _fileManager.saveFile(fileData);
    if (success) {
      return fileData;
    } else {
      throw Exception('Failed to save scanned file');
    }
  }

  Future<List<Map<String, dynamic>>> batchScanFiles(List<File> files, String category) async {
    final results = <Map<String, dynamic>>[];

    for (final file in files) {
      try {
        final result = await scanFile(file, category);
        results.add(result);
      } catch (e) {
        print('Error scanning file ${file.path}: $e');
      }
    }

    return results;
  }
}

class ScanHistoryTransform {
  static List<Map<String, dynamic>> prepareScanData(Map<String, Set<File>> folders) {
    List<Map<String, dynamic>> scanData = [];

    for (var entry in folders.entries) {
      String folderName = entry.key;
      Set<File> files = entry.value;

      scanData.add({
        folderName: files,
      });
    }

    return scanData;
  }

  static Future<void> storeFiles(List<Map<String, dynamic>> fileData) async {
    final fileManager = FileManager();

    for (final entry in fileData) {
      for (final key in entry.keys) {
        final tableName = key;
        final files = entry[key]!;

        for (final file in files) {
          final fileSize = await file.length();
          final fileMetadata = {
            'file_name': file.path.split('/').last,
            'file_path': file.path,
            'folder_name': key,
            'file_type': file.path.split('.').last,
            'scan_date': DateTime.now().toIso8601String(),
            'file_size': fileSize,
          };

          await fileManager.saveFile(fileMetadata);
        }
      }
    }
  }
}