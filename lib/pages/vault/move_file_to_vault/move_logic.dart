import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';


class FileVaultService {

  Future<void> moveToVault(BuildContext context, File file) async {
    if (!await file.exists()) {
      return;
    }

    //  Get Internal Vault Directory
    final vaultDir = await getApplicationDocumentsDirectory();
    final vaultPath = '${vaultDir.path}/Vault';

    await Directory(vaultPath).create(recursive: true); // Ensure vault exists

    //  Move file to vault
    final newFilePath = '$vaultPath/${basename(file.path)}';
    await file.copy(newFilePath); // Copy instead of rename to handle different storage

    //  Delete original file after successful move
    // await file.delete();
    //
    // //  Navigate to the tracking page
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => VaultTrackingPage(newFilePath)),
    // );
  }
}
