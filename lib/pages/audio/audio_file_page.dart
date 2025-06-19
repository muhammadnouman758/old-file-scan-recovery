import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/audio/audio_player.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:path_provider/path_provider.dart';

import '../file_manager/file_manager.dart';
import '../notification/notification_clas.dart';
import '../recover_file/database_process.dart';
import '../vault/move_file_to_vault/vault_database.dart';
import '../vault/without_encryption.dart';

class AudioFolderPage extends StatefulWidget {
  final String folderName;
  final Set<File> audioFiles;

  const AudioFolderPage({super.key, required this.folderName, required this.audioFiles});

  @override
  State<AudioFolderPage> createState() => _AudioFolderPageState();
}

class _AudioFolderPageState extends State<AudioFolderPage> {
  Set<File> selectedFiles = {};

  void _toggleSelection(File file) {
    setState(() {
      if (selectedFiles.contains(file)) {
        selectedFiles.remove(file);
      } else {
        selectedFiles.add(file);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CusColor.decentWhite,
      appBar: AppBar(
        backgroundColor: CusColor.darkBlue3,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          widget.folderName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: widget.audioFiles.length,
        itemBuilder: (context, index) {
          final audioFile = widget.audioFiles.elementAt(index);
          final isSelected = selectedFiles.contains(audioFile);

          return ListTile(
            leading: Icon(
              isSelected ? Icons.check_circle : Icons.music_note, size: 40,
              color: isSelected ? CusColor.darkBlue3 : CusColor.darkBlue3,
            ),
            title: Text(
              audioFile.path.split('/').last,
              maxLines: 1,
              style: TextStyle(
                color: isSelected ? CusColor.darkBlue3 : CusColor.darkBlue3,
              ),
            ),
            subtitle: Text('Size : ${(audioFile.statSync().size / 1024 /1024).toStringAsFixed(3) } MB'),
            onLongPress: () {
              _toggleSelection(audioFile);
            },
            onTap: () {
              if(selectedFiles.isEmpty){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioPlayerPage(audioFile: audioFile),
                  ),
                );
              }else{
                _toggleSelection(audioFile);
              }

            },
          );
        },
      ),
      bottomNavigationBar: Visibility(
          visible: selectedFiles.isNotEmpty,
          child: InkWell(
            onTap: () {
              saveAudio();
            },
            child: Container(
              width: double.infinity,
              height: 50.h,
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: 50.w, vertical: 20.h
              ),
              decoration: BoxDecoration(
                  color: CusColor.darkBlue3,
                  borderRadius: BorderRadius.circular(10)
              ),
              child: Text(
                'Recovers Audio \t${selectedFiles.length}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          )
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: selectedFiles.isNotEmpty
          ? SizedBox(
        width: 150.w,
        child: FloatingActionButton.extended(
          onPressed: _secureSelectedVideosWithoutEncryption,
          icon: const Icon(Icons.safety_check_outlined),
          label: const Text('Quick Secure'),
          backgroundColor: CusColor.decentWhite,
        ),
      ): null,
    );
  }

  saveAudio()async{
    OldFileManager.createMainFolder();
    final fileRecoveryHistory = FileRecoveryService();
    await fileRecoveryHistory.saveRecoveredFiles(selectedFiles, 'audio');
    selectedFiles.map((video){
      OldFileManager.saveFile(video, 'audio');
      return video;
    }).toList();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File Saved')));

    setState(() {
      selectedFiles.clear();
    });
  }
  Future<void> _secureSelectedVideosWithoutEncryption() async {
    display('Audio are being secured without encryption!');
    final VaultProcessWithoutEncryption vaultManager = VaultProcessWithoutEncryption();
    await vaultManager.initializeProcessor();
    final appDir = await getApplicationDocumentsDirectory();
    final database = DatabaseHelperVault();
    List<File> securedFiles = [];
    for (final file in selectedFiles) {
      bool isDone = await vaultManager.copyFileInChunks(file);
      final metaData = {
        "file_name": file.path.split('/').last,
        "thumbnail": file.path , // Store thumbnail path
        "encrypted_path": '${appDir.path}/vault/${file.path.split('/').last}', // Store encrypted video path
        "original_path": file.path, // Store original path before encryption
        "size": file.lengthSync(), // File size in bytes
        "type": "audio", // File type
        "created_at": DateTime.now().toIso8601String(), // Timestamp
      };
      database.insertFile(metaData);
      if (isDone) {
        file.deleteSync();
        securedFiles.add(file);
      }
    }
    setState(() {
      widget.audioFiles.removeAll(securedFiles);
      selectedFiles.clear();
    });
    NotificationService().showScanNotificationSecured(securedFiles.length);
    display('Selected Audio secured successfully!');
  }

  display(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title, style: const TextStyle(color: Colors.white),),
        backgroundColor: CusColor.darkBlue3,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


}