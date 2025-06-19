
import 'dart:io';

import 'database_helper_recovered_file.dart';

class CleanupService {
  Future<void> removeMissingFiles() async {
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> recoveredFiles = await db.query('recovered_files');

    for (var file in recoveredFiles) {
      File f = File(file['file_path']);
      if (!await f.exists()) {
        await db.delete('recovered_files', where: 'id = ?', whereArgs: [file['id']]);
      }
    }
  }
}
