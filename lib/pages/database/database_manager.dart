import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  late Database _db;

  DatabaseManager._internal();

  factory DatabaseManager() {
    return _instance;
  }

  Future<void> initializeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vault_security.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pin (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pin_code TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> savePin(String pin) async {
    await _db.delete('pin');
    // Ensure only one PIN exists

    await _db.insert('pin', {'pin_code': pin});
  }

  Future<String?> getPin() async {
    final result = await _db.query('pin', limit: 1);
    if (result.isNotEmpty) {
      return result.first['pin_code'] as String;
    }
    return null;
  }

  Future<void> clearPin() async {
    await _db.delete('pin');
  }
}
