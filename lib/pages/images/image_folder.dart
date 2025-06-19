import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:old_file_recovery/pages/file_manager/file_manager.dart';
import 'package:old_file_recovery/pages/recover_file/database_process.dart';
import 'package:old_file_recovery/pages/vault/enforce_gallery.dart';
import 'package:path_provider/path_provider.dart';
import '../notification/notification_clas.dart';
import '../vault/move_file_to_vault/vault_database.dart';
import '../vault/without_encryption.dart';
import 'image_detail.dart';

class FolderImagesPage extends StatefulWidget {
  final String folderName;
  final Set<File> images;

  const FolderImagesPage({super.key, required this.folderName, required this.images});

  @override
  State<FolderImagesPage> createState() => _FolderImagesPageState();
}

class _FolderImagesPageState extends State<FolderImagesPage> with SingleTickerProviderStateMixin {
  final Set<File> _selectedImages = {};
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShowTitle = _scrollController.offset > 80;
    if (shouldShowTitle != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = shouldShowTitle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: CusColor.decentWhite,
      appBar: _buildAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CusColor.darkBlue3,
              CusColor.decentWhite,
            ],
            stops: const [0.2, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20.w, top: 15.h, bottom: 5.h),
                child: Text(
                  '${widget.images.length} ${widget.images.length == 1 ? 'image' : 'images'} found',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 5.0,
                    mainAxisSpacing: 5.0,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) {
                    final image = widget.images.elementAt(index);
                    final isSelected = _selectedImages.contains(image);
                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          if (_selectedImages.isEmpty) {
                            _selectedImages.add(image);
                          }
                        });
                      },
                      onTap: () {
                        if (_selectedImages.isEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullImagePage(image: image),
                            ),
                          );
                        } else {
                          setState(() {
                            if (isSelected) {
                              _selectedImages.remove(image);
                            } else {
                              _selectedImages.add(image);
                            }
                          });
                        }
                      },
                      child: Stack(
                        children: [
                          Hero(
                            tag: image.path,
                            child: Container(
                              margin: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  height: 100.h,
                                  child: Image.file(
                                    image,
                                    cacheHeight: 400,
                                    width: 400.w,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: _selectedImages.isNotEmpty ? 1.0 : 0.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? CusColor.darkBlue3
                                      : Colors.white.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(2.w),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                                      : const Icon(Icons.circle_outlined, color: Colors.grey, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _selectedImages.isNotEmpty
            ? Container(
          height: 70.h,
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: CusColor.darkBlue3.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: saveImage,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_alt, color: Colors.white),
                      SizedBox(width: 12.w),
                      Text(
                        'Save ${_selectedImages.length} Images',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
            : const SizedBox.shrink(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _selectedImages.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _secureSelectedVideosWithoutEncryption,
        icon: const Icon(Icons.safety_check_outlined),
        label: const Text('Quick Secure'),
        backgroundColor: CusColor.darkBlue3,
        foregroundColor: Colors.white,
        elevation: 4,
      )
          : null,
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: CusColor.darkBlue3,
      elevation: 0,
      title: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 300),
        child: Text(
          widget.folderName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      actions: [
        if (_selectedImages.isNotEmpty)
          IconButton(
            onPressed: () {
              setState(() {
                _selectedImages.clear();
              });
            },
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Cancel Selection',
          ),
        IconButton(
          icon: const Icon(Icons.select_all, color: Colors.white),
          onPressed: () {
            setState(() {
              if (_selectedImages.length == widget.images.length) {
                _selectedImages.clear();
              } else {
                _selectedImages.addAll(widget.images);
              }
            });
          },
          tooltip: 'Select All',
        ),
      ],
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CusColor.darkBlue3.withOpacity(0.7),
                  CusColor.darkBlue3.withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ),
    );

  }

  void saveImage() async {
    OldFileManager.createMainFolder();
    final fileRecoveryHistory = FileRecoveryService();
    await fileRecoveryHistory.saveRecoveredFiles(_selectedImages, 'image');
    _selectedImages.map((photo) {
      final newPath = OldFileManager.saveFile(photo, "image");
      return newPath;
    }).toList();
    setState(() {
      _selectedImages.clear();
    });
    display('Selected images saved successfully!');
  }

  Future<void> _secureSelectedVideosWithoutEncryption() async {
    display('Images are being secured without encryption...');
    final VaultProcessWithoutEncryption vaultManager = VaultProcessWithoutEncryption();
    final database = DatabaseHelperVault();
    final appDir = await getApplicationDocumentsDirectory();
    await vaultManager.initializeProcessor();
    List<File> securedFiles = [];
    for (final file in _selectedImages) {
      bool isDone = await vaultManager.copyFileInChunks(file);
      final metaData = {
        "file_name": file.path.split('/').last,
        "thumbnail": file.path, // Store thumbnail path
        "encrypted_path": '${appDir.path}/vault/${file.path.split('/').last}', // Store encrypted video path
        "original_path": file.path, // Store original path before encryption
        "size": file.lengthSync(), // File size in bytes
        "type": "image", // File type
        "created_at": DateTime.now().toIso8601String(), // Timestamp
      };
      database.insertFile(metaData);
      if (isDone) {
        file.deleteSync();
        UpdateMediaStore.removeFromGallery(file.path);
        securedFiles.add(file);
      }
    }
    setState(() {
      widget.images.removeAll(securedFiles);
      _selectedImages.clear();
    });
    NotificationService().showScanNotificationSecured(securedFiles.length);
    display('Selected images secured successfully!');
  }

  display(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title, style: const TextStyle(color: Colors.white),),
        backgroundColor: CusColor.darkBlue3,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}