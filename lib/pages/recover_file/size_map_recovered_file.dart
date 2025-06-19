import 'database_helper_recovered_file.dart';

class FileRecoveryService {

  Future<Map<String, int>> getTotalSizeByCategory() async {
    final db = await DatabaseHelper.instance.database;

    List<String> categories = ['image', 'video', 'audio', 'docs'];
    Map<String, int> categorySizes = {};

    for (String category in categories) {
      final result = await db.rawQuery(
        "SELECT SUM(file_size) as total_size FROM recovered_files WHERE file_type = ?",
        [category],
      );

      int totalSize = result.first['total_size'] as int? ?? 0;
      categorySizes[category] = totalSize;
    }

    return categorySizes;
  }
}
