import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../file_manager/file_manager.dart';
import '../notification/notification_clas.dart';
import '../recover_file/database_process.dart';
import '../vault/move_file_to_vault/vault_database.dart';
import '../vault/without_encryption.dart';

class DocumentFolderPage extends StatefulWidget {
  final String folderName;
  final Set<File> documentFiles;

  const DocumentFolderPage({super.key, required this.folderName, required this.documentFiles});

  @override
  State<DocumentFolderPage> createState() => _DocumentFolderPageState();
}

class _DocumentFolderPageState extends State<DocumentFolderPage> with SingleTickerProviderStateMixin {
  Set<File> selectedFiles = {};
  bool isGridView = false;
  late AnimationController _animationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSelection(File file) {
    setState(() {
      if (selectedFiles.contains(file)) {
        selectedFiles.remove(file);
      } else {
        selectedFiles.add(file);
      }
    });
  }

  Color _getColorForExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Colors.red.shade700;
      case 'doc':
      case 'docx':
        return Colors.blue.shade700;
      case 'xls':
      case 'xlsx':
        return Colors.green.shade700;
      case 'ppt':
      case 'pptx':
        return Colors.orange.shade700;
      case 'txt':
        return Colors.grey.shade700;
      default:
        return CusColor.darkBlue3;
    }
  }

  Widget _buildFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    final color = _getColorForExtension(fileName);

    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          extension.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nonEmptyDocumentFiles = widget.documentFiles
        .where((file) => (file.statSync().size / 1024 / 1024) > 0)
        .toList();

    return Scaffold(
      backgroundColor: CusColor.decentWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CusColor.darkBlue3,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
            widget.folderName,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20.sp
            )
        ),
        actions: [
          IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.list_view,
              progress: _animationController,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
                if (isGridView) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
          ),
          if (selectedFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  selectedFiles.clear();
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          if (nonEmptyDocumentFiles.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  SizedBox(height: 20.h),
                  Text(
                    'No documents found',
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: CusColor.darkBlue3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
               isGridView
                  ? _buildGridView(nonEmptyDocumentFiles)
                  : _buildListView(nonEmptyDocumentFiles),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: CusColor.darkBlue3,
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Processing files...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: selectedFiles.isNotEmpty
          ? _buildFloatingActionButton()
          : null,
    );
  }

  Widget _buildListView(List<File> documentFiles) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      itemCount: documentFiles.length,
      itemBuilder: (context, index) {
        return _buildListItem(documentFiles[index]);
      },
    );
  }

  Widget _buildGridView(List<File> documentFiles) {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.85,
      ),
      itemCount: documentFiles.length,
      itemBuilder: (context, index) {
        return _buildGridItem(documentFiles[index]);
      },
    );
  }

  Widget _buildListItem(File documentFile) {
    final fileName = documentFile.path.split('/').last;
    final isSelected = selectedFiles.contains(documentFile);
    final sizeFile = (documentFile.statSync().size / 1024 / 1024);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (selectedFiles.isNotEmpty) {
            _toggleSelection(documentFile);
          } else {
            OpenFilex.open(documentFile.path);
          }
        },
        onLongPress: () => _toggleSelection(documentFile),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              _buildFileIcon(fileName),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CusColor.darkBlue3,
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "${sizeFile.toStringAsFixed(2)} MB",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: CusColor.darkBlue3,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16.w,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(File documentFile) {
    final fileName = documentFile.path.split('/').last;
    final isSelected = selectedFiles.contains(documentFile);
    final sizeFile = (documentFile.statSync().size / 1024 / 1024);
    final color = _getColorForExtension(fileName);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (selectedFiles.isNotEmpty) {
                _toggleSelection(documentFile);
              } else {
                OpenFilex.open(documentFile.path);
              }
            },
            onLongPress: () => _toggleSelection(documentFile),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 70.w,
                        height: 70.w,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            fileName.split('.').last.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CusColor.darkBlue3,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "${sizeFile.toStringAsFixed(2)} MB",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isSelected)
          Positioned(
            top: 8.w,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: CusColor.darkBlue3,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 16.w,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    if (selectedFiles.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: saveAudio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CusColor.darkBlue3,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_alt),
                    SizedBox(width: 8.w),
                    Text(
                      'Recover (${selectedFiles.length})',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return SizedBox(
      width: 180.w,
      child: FloatingActionButton.extended(
        onPressed: _secureSelectedVideosWithoutEncryption,
        icon: const Icon(Icons.shield_outlined),
        label: Text(
          'Quick Secure (${selectedFiles.length})',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: CusColor.darkBlue3,
        elevation: 4,
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : CusColor.darkBlue3,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 20.w,
          right: 20.w,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> saveAudio() async {
    if (selectedFiles.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      OldFileManager.createMainFolder();
      final fileRecoveryHistory = FileRecoveryService();
      await fileRecoveryHistory.saveRecoveredFiles(selectedFiles, 'docs');

      for (var doc in selectedFiles) {
        await OldFileManager.saveFile(doc, 'docs');
      }

      _showSnackBar('${selectedFiles.length} files recovered successfully');

      setState(() {
        selectedFiles.clear();
      });
    } catch (e) {
      _showSnackBar('Failed to recover files: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _secureSelectedVideosWithoutEncryption() async {
    if (selectedFiles.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _showSnackBar('Securing files...');

      final VaultProcessWithoutEncryption vaultManager = VaultProcessWithoutEncryption();
      await vaultManager.initializeProcessor();
      final appDir = await getApplicationDocumentsDirectory();
      final database = DatabaseHelperVault();
      List<File> securedFiles = [];

      for (final file in selectedFiles) {
        bool isDone = await vaultManager.copyFileInChunks(file);
        final metaData = {
          "file_name": file.path.split('/').last,
          "thumbnail": file.path,
          "encrypted_path": '${appDir.path}/vault/${file.path.split('/').last}',
          "original_path": file.path,
          "size": file.lengthSync(),
          "type": "docs",
          "created_at": DateTime.now().toIso8601String(),
        };
        await database.insertFile(metaData);

        if (isDone) {
          file.deleteSync();
          securedFiles.add(file);
        }
      }

      setState(() {
        widget.documentFiles.removeAll(securedFiles);
        selectedFiles.clear();
      });

      NotificationService().showScanNotificationSecured(securedFiles.length);
      _showSnackBar('${securedFiles.length} files secured successfully');
    } catch (e) {
      _showSnackBar('Failed to secure files: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}