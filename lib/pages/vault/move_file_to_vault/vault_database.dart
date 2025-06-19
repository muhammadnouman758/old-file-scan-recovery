import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
class DatabaseHelperVault {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = path.join(await getDatabasesPath(), 'vault.db');
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE vault(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_name TEXT,
            encrypted_path TEXT,
            original_path TEXT,
            thumbnail TEXT,
            size INTEGER,
            type TEXT,
            created_at TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertFile(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('vault', data);
  }

  Future<void> deleteFile(int id) async {
    final db = await database;
    await db.delete('vault', where: 'id = ?', whereArgs: [id]);

  }

  Future<List<Map<String, dynamic>>> getVideoFiles(bool isVideo) async {
    final db = await database;
    return isVideo
        ? await db.query('vault', where: 'type = ?', whereArgs: ['video'])
        : await db.query('vault', where: 'type = ?', whereArgs: ['image']);
  }

  Future<List<Map<String, dynamic>>> getFilesByType(String fileType) async {
    final db = await database;
    return await db.query(
        'vault',
        where: 'type = ?',
        whereArgs: [fileType],
        orderBy: 'created_at DESC'
    );
  }

  Future<int> getFileCountByType(String fileType) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM vault WHERE type = ?',
        [fileType]
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static String getFileTypeFromPath(String path) {
    if (path.isEmpty) return 'unknown';

    final extension = path.split('.').last.toLowerCase();

    if (['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', '3gp'].contains(extension)) {
      return 'video';
    }

    if (['mp3', 'wav', 'ogg', 'aac', 'flac', 'm4a', 'wma'].contains(extension)) {
      return 'audio';
    }

    if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'rtf', 'csv'].contains(extension)) {
      return 'docs';
    }

    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic'].contains(extension)) {
      return 'image';
    }

    return 'unknown';
  }
}