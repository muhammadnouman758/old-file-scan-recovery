import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._init();
  static DatabaseHelper get instance => _instance;

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'recovered_files.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recovered_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_name TEXT,
        file_path TEXT UNIQUE,
        file_type TEXT CHECK(file_type IN ('image', 'video', 'audio', 'docs')),
        file_size INTEGER,
        recovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }
}
