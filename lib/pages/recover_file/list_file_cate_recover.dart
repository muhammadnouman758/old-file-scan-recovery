
import 'database_helper_recovered_file.dart';

class FileQueryService {
  Future<List<Map<String, dynamic>>> getRecoveredFiles(String fileType) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
        'recovered_files',
        where: 'file_type = ?',
        whereArgs: [fileType],
        orderBy: 'recovered_at DESC'
    );
  }
}
