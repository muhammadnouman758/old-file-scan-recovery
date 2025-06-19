import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:old_file_recovery/pages/recover_file/database_helper_recovered_file.dart';

class FileRecoveryService {
  Future<bool> saveRecoveredFiles(Set<File> files, String fileType) async {

    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    print('daa taa => $files');
    print('type is $fileType');
    for (var file in files) {
      if ( await file.exists() ) {
        print('doc => ${file.path}');
        batch.insert(
          'recovered_files',
          {
            'file_name': basename(file.path),
            'file_path': file.path,
            'file_type': fileType,
            'file_size': await file.length(),
            'recovered_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

      }

    }

    try {
      await batch.commit(noResult: true);
    } catch (e) {
      return false;
    }
    return true;
  }
}
