import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/file_manager/file_manager.dart';
import 'package:old_file_recovery/pages/notification/notification_clas.dart';
import 'package:old_file_recovery/pages/vault/move_file_to_vault/vault_database.dart';
import 'package:old_file_recovery/pages/vault/without_encryption.dart';
import 'package:old_file_recovery/video_player/video_player.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:path_provider/path_provider.dart';
import '../../setting/ui/setting_ui.dart';
import '../recover_file/database_process.dart';

class VideoFolderPage extends StatefulWidget {
  final String folderName;
  final List<Map<String, dynamic>> videos;

  const VideoFolderPage({super.key, required this.folderName, required this.videos});

  @override
  State<VideoFolderPage> createState() => _VideoFolderPageState();
}

enum SortType { name, date, size }
enum SortOrder { ascending, descending }

class _VideoFolderPageState extends State<VideoFolderPage> with SingleTickerProviderStateMixin {
  final Set<File> selectedVideos = {};
  final Set<String> _selectedVideoThumbnails = {};
  bool _isSelecting = false;
  final TextEditingController _renameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<Map<String, dynamic>> _filteredVideos = [];
  SortType _sortType = SortType.name;
  SortOrder _sortOrder = SortOrder.ascending;
  Timer? _debounce;
  bool _isSearchVisible = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _filteredVideos = List.from(widget.videos);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _searchController.addListener(_onSearchChanged);
    _sortVideos();
  }

  @override
  void dispose() {
    _renameController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    _debounce?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        final query = _searchController.text.toLowerCase();
        _filteredVideos = widget.videos.where((video) {
          final fileName = video['file'].path.split('/').last.toLowerCase();
          return fileName.contains(query);
        }).toList();
        _sortVideos();
      });
    });
  }

  void _sortVideos() {
    setState(() {
      _filteredVideos.sort((a, b) {
        final File fileA = a['file'];
        final File fileB = b['file'];
        int comparison;
        switch (_sortType) {
          case SortType.name:
            comparison = fileA.path.split('/').last.compareTo(fileB.path.split('/').last);
            break;
          case SortType.date:
            comparison = fileA.lastModifiedSync().compareTo(fileB.lastModifiedSync());
            break;
          case SortType.size:
            comparison = fileA.lengthSync().compareTo(fileB.lengthSync());
            break;
        }
        return _sortOrder == SortOrder.ascending ? comparison : -comparison;
      });
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            _buildSortOption('Name', SortType.name),
            _buildSortOption('Date', SortType.date),
            _buildSortOption('Size', SortType.size),
            const Divider(),
            ListTile(
              leading: Icon(
                _sortOrder == SortOrder.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                color: CusColor.darkBlue3,
              ),
              title: Text(
                _sortOrder == SortOrder.ascending ? 'Ascending' : 'Descending',
                style: TextStyle(fontSize: 16.sp),
              ),
              onTap: () {
                setState(() {
                  _sortOrder = _sortOrder == SortOrder.ascending ? SortOrder.descending : SortOrder.ascending;
                  _sortVideos();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, SortType type) {
    return ListTile(
      leading: Icon(
        type == _sortType ? Icons.check_circle : Icons.radio_button_unchecked,
        color: type == _sortType ? CusColor.darkBlue3 : Colors.grey,
      ),
      title: Text(title, style: TextStyle(fontSize: 16.sp)),
      onTap: () {
        setState(() {
          _sortType = type;
          _sortVideos();
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CusColor.decentWhite,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: CusColor.darkBlue3,
        title: Text(
          widget.folderName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: _isSelecting
            ? [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSelecting = false;
                selectedVideos.clear();
                _selectedVideoThumbnails.clear();
              });
            },
          ),
        ]
            : [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.search_off : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                } else {
                  _searchFocusNode.requestFocus();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: _showSortOptions,
          ),
        ],
        elevation: 0,

      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: selectedVideos.isNotEmpty ? 90.h : 0,
        child: Visibility(
          visible: selectedVideos.isNotEmpty,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: ElevatedButton(
              onPressed: saveVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: CusColor.darkBlue3,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_alt, size: 24),
                  SizedBox(width: 10.w),
                  Text(
                    'Recover Videos (${selectedVideos.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearchVisible ? 60.h : 0,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: _isSearchVisible
                ? TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search videos...',
                prefixIcon: Icon(Icons.search, color: CusColor.darkBlue3),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: CusColor.darkBlue3, width: 2),
                ),
              ),
            )
                : null,
          ),
          Expanded(
            child: _filteredVideos.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: EdgeInsets.all(10.w),
              itemCount: _filteredVideos.length,
              itemBuilder: (context, index) {
                final video = _filteredVideos[index];
                final File videoFile = video['file'];
                final String thumbnailPath = video['thumbnail'];
                final isSelected = selectedVideos.contains(videoFile);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(vertical: 5.h),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onLongPress: () {
                          setState(() {
                            _isSelecting = true;
                            selectedVideos.add(videoFile);
                            _selectedVideoThumbnails.add(thumbnailPath);
                          });
                          _animationController.forward(from: 0.0);
                        },
                        onTap: () {
                          if (_isSelecting) {
                            setState(() {
                              if (isSelected) {
                                selectedVideos.remove(videoFile);
                                _selectedVideoThumbnails.remove(thumbnailPath);
                                if (selectedVideos.isEmpty) {
                                  _isSelecting = false;
                                }
                              } else {
                                selectedVideos.add(videoFile);
                                _selectedVideoThumbnails.add(thumbnailPath);
                              }
                            });
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(
                                  videoUrl: videoFile.path,
                                  title: videoFile.path,
                                ),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 5.w),
                          child: Row(
                            children: [
                              if (_isSelecting)
                                Padding(
                                  padding: EdgeInsets.only(left: 8.w, right: 12.w),
                                  child: ScaleTransition(
                                    scale: _animation,
                                    child: Container(
                                      width: 24.w,
                                      height: 24.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? CusColor.darkBlue3 : Colors.transparent,
                                        border: Border.all(
                                          color: CusColor.darkBlue3,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                          : null,
                                    ),
                                  ),
                                ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: thumbnailPath != null
                                    ? Image.file(
                                  File(thumbnailPath),
                                  height: 70.h,
                                  width: 100.w,
                                  fit: BoxFit.cover,
                                )
                                    : Container(
                                  height: 70.h,
                                  width: 100.w,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.videocam,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      videoFile.path.split('/').last,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: CusColor.darkBlue3,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      _formatFileSize(videoFile.lengthSync()),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!_isSelecting)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(50),
                                    onTap: () => _showVideoOptionsBottomSheet(context, videoFile, thumbnailPath, index),
                                    child: Padding(
                                      padding: EdgeInsets.all(8.w),
                                      child: Icon(
                                        Icons.more_vert,
                                        color: CusColor.darkBlue3,
                                        size: 24.sp,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: selectedVideos.isNotEmpty
          ? Padding(
        padding: EdgeInsets.only(bottom: 80.h),
        child: FloatingActionButton.extended(
          onPressed: _secureSelectedVideosWithoutEncryption,
          icon: const Icon(Icons.safety_check_outlined),
          label: const Text('Quick Secure'),
          backgroundColor: Colors.white,
          foregroundColor: CusColor.darkBlue3,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: CusColor.darkBlue3, width: 1),
          ),
        ),
      )
          : null,
    );
  }

  // Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No Videos Found',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Videos you recover will appear here',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Bottom sheet instead of dialog for better UX
  void _showVideoOptionsBottomSheet(BuildContext context, File videoFile, String thumbnailPath, int videoIndex) {
    final fileName = videoFile.path.split('/').last;
    final fileSize = _formatFileSize(videoFile.lengthSync());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Video preview and basic info
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: thumbnailPath != null
                        ? Image.file(
                      File(thumbnailPath),
                      height: 90.h,
                      width: 120.w,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      height: 90.h,
                      width: 120.w,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.videocam,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: CusColor.darkBlue3,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          fileSize,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Options grid
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                childAspectRatio: 0.9,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildGridOption(
                    icon: Icons.play_circle_filled,
                    label: 'Play',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerScreen(
                            videoUrl: videoFile.path,
                            title: videoFile.path,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildGridOption(
                    icon: Icons.info_outline,
                    label: 'Properties',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _showVideoPropertiesDialog(context, videoFile, thumbnailPath);
                    },
                  ),
                  _buildGridOption(
                    icon: Icons.edit,
                    label: 'Rename',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _showRenameDialog(context, videoFile, videoIndex);
                    },
                  ),
                  _buildGridOption(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmationDialog(context, videoFile, videoIndex);
                    },
                  ),
                  _buildGridOption(
                    icon: Icons.shield,
                    label: 'Secure',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _secureVideoFile(videoFile, thumbnailPath, videoIndex);
                    },
                  ),
                  _buildGridOption(
                    icon: Icons.save_alt,
                    label: 'Save',
                    color: CusColor.darkBlue3,
                    onTap: () {
                      Navigator.pop(context);
                      _saveVideoFile(videoFile);
                    },
                  ),
                  _buildGridOption(
                    icon: Icons.share,
                    label: 'Share',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      display('Sharing functionality will be implemented');
                    },
                  ),
                  _buildGridOption(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    color: Colors.grey,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Grid option widget
  Widget _buildGridOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // Video properties dialog with modern UI
  void _showVideoPropertiesDialog(BuildContext context, File videoFile, String thumbnailPath) {
    final fileSize = _formatFileSize(videoFile.lengthSync());
    final lastModified = videoFile.lastModifiedSync();
    final path = videoFile.path;
    final fileName = path.split('/').last;
    final dateFormatted = '${lastModified.day}/${lastModified.month}/${lastModified.year}';
    final timeFormatted = _formatTime(lastModified);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                color: CusColor.darkBlue3,
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    Text(
                      'Video Properties',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(thumbnailPath),
                            height: 120.h,
                            width: 160.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Container(
                          width: 50.w,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Properties content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _buildPropertyRow(
                    icon: Icons.insert_drive_file_outlined,
                    label: 'Name',
                    value: fileName,
                  ),
                  _buildPropertyRow(
                    icon: Icons.straighten,
                    label: 'Size',
                    value: fileSize,
                  ),
                  _buildPropertyRow(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: dateFormatted,
                  ),
                  _buildPropertyRow(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: timeFormatted,
                  ),
                  _buildPropertyRow(
                    icon: Icons.folder_outlined,
                    label: 'Path',
                    value: path.substring(0, path.lastIndexOf('/')),
                    isLast: true,
                  ),
                ],
              ),
            ),
            // Close button
            Padding(
              padding: EdgeInsets.only(bottom: 16.h, left: 16.w, right: 16.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CusColor.darkBlue3,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Property row widget for properties dialog
  Widget _buildPropertyRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: CusColor.darkBlue3.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: CusColor.darkBlue3,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: Colors.grey[300],
          ),
      ],
    );
  }

  // Modern rename dialog
  void _showRenameDialog(BuildContext context, File videoFile, int videoIndex) {
    final fileName = videoFile.path.split('/').last;
    _renameController.text = fileName;
    _renameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: fileName.lastIndexOf('.'),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Rename Video',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: CusColor.darkBlue3,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _renameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter new name',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: CusColor.darkBlue3, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.video_file_outlined),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: CusColor.darkBlue3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: CusColor.darkBlue3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _renameVideo(videoFile, _renameController.text, videoIndex);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CusColor.darkBlue3,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Rename',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, File videoFile, int videoIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 5,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70.w,
                height: 70.h,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Delete Video',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Are you sure you want to delete this video? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteVideo(videoFile, videoIndex);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _renameVideo(File videoFile, String newName, int videoIndex) async {
    try {

      if (newName.trim().isEmpty) {
        display('File name cannot be empty');
        return;
      }
      final String oldName = videoFile.path.split('/').last;
      final String extension = oldName.substring(oldName.lastIndexOf('.'));
      if (!newName.endsWith(extension)) {
        newName += extension;
      }

      final Directory directory = Directory(videoFile.parent.path);
      final String newPath = '${directory.path}/$newName';

      if (await File(newPath).exists()) {
        _showCustomAlert(
          context: context,
          title: 'File Already Exists',
          message: 'A file with this name already exists. Please choose a different name.',
          iconData: Icons.error_outline,
          iconColor: Colors.orange,
        );
        return;
      }
      _showLoadingDialog(context, 'Renaming video...');
      final File newFile = await videoFile.rename(newPath);
      setState(() {
        widget.videos[videoIndex]['file'] = newFile;
        _filteredVideos = List.from(widget.videos);
        _sortVideos();
      });

      Navigator.pop(context); // Pop loading dialog
      _showCustomAlert(
        context: context,
        title: 'Success',
        message: 'Video renamed successfully',
        iconData: Icons.check_circle_outline,
        iconColor: Colors.green,
      );
    }
    catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showCustomAlert(
        context: context,
        title: 'Error',
        message: 'Failed to rename video: $e',
        iconData: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }
  void _deleteVideo(File videoFile, int videoIndex) async {
    try {
      _showLoadingDialog(context, 'Deleting video...');

      videoFile.deleteSync();

      final String? thumbnailPath = widget.videos[videoIndex]['thumbnail'];
      if (thumbnailPath != null) {
        final File thumbnailFile = File(thumbnailPath);
        if (thumbnailFile.existsSync()) {
          thumbnailFile.deleteSync();
        }
      }
      setState(() {
        widget.videos.removeAt(videoIndex);
        _filteredVideos = List.from(widget.videos);
        _sortVideos();
      });

      // Hide loading indicator
      Navigator.pop(context);

      // Show success message
      _showCustomSnackBar(
        message: 'Video deleted successfully',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      // Hide loading indicator if showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showCustomSnackBar(
        message: 'Error deleting video: $e',
        icon: Icons.error_outline,
        backgroundColor: Colors.red,
      );
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              SizedBox(
                width: 30.w,
                height: 30.h,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(CusColor.darkBlue3),
                  strokeWidth: 3,
                ),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomAlert({
    required BuildContext context,
    required String title,
    required String message,
    required IconData iconData,
    required Color iconColor,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 36,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10.w),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  Future<void> _secureVideoFile(File videoFile, String thumbnailPath, int videoIndex) async {
    try {
      _showLoadingDialog(context, 'Securing video...');

      final VaultProcessWithoutEncryption vaultManager = VaultProcessWithoutEncryption();
      await vaultManager.initializeProcessor();
      final database = DatabaseHelperVault();
      final appDir = await getApplicationDocumentsDirectory();

      bool isDone = await vaultManager.copyFileInChunks(videoFile);
      if (isDone) {
        final metaData = {
          "file_name": videoFile.path.split('/').last,
          "thumbnail": thumbnailPath,
          "encrypted_path": '${appDir.path}/vault/${videoFile.path.split('/').last}',
          "original_path": videoFile.path,
          "size": videoFile.lengthSync(),
          "type": "video",
          "created_at": DateTime.now().toIso8601String(),
        };

        database.insertFile(metaData);
        videoFile.deleteSync();

        setState(() {
          widget.videos.removeAt(videoIndex);
          _filteredVideos = List.from(widget.videos);
          _sortVideos();
        });

        enableNotificationSetting(context, 1);

        // Hide loading dialog
        Navigator.pop(context);

        _showCustomAlert(
          context: context,
          title: 'Video Secured',
          message: 'Video has been moved to secure vault successfully',
          iconData: Icons.shield,
          iconColor: Colors.purple,
        );
      } else {
        // Hide loading dialog
        Navigator.pop(context);

        _showCustomAlert(
          context: context,
          title: 'Error',
          message: 'Failed to secure video',
          iconData: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } catch (e) {
      // Hide loading dialog if showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showCustomAlert(
        context: context,
        title: 'Error',
        message: 'Failed to secure video: $e',
        iconData: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

  void _saveVideoFile(File videoFile) async {
    try {
      _showLoadingDialog(context, 'Saving video...');

      OldFileManager.createMainFolder();
      final fileRecoveryHistory = FileRecoveryService();
      await fileRecoveryHistory.saveRecoveredFiles({videoFile}, 'video');
      OldFileManager.saveFile(videoFile, 'video');

      // Hide loading dialog
      Navigator.pop(context);

      _showCustomAlert(
        context: context,
        title: 'Success',
        message: 'Video saved successfully',
        iconData: Icons.check_circle_outline,
        iconColor: Colors.green,
      );
    } catch (e) {
      // Hide loading dialog if showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showCustomAlert(
        context: context,
        title: 'Error',
        message: 'Failed to save video: $e',
        iconData: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

  Future<void> _secureSelectedVideosWithoutEncryption() async {
    if (selectedVideos.isEmpty) return;

    try {
      _showLoadingDialog(context, 'Securing ${selectedVideos.length} videos...');

      final VaultProcessWithoutEncryption vaultManager = VaultProcessWithoutEncryption();
      await vaultManager.initializeProcessor();
      final database = DatabaseHelperVault();
      final appDir = await getApplicationDocumentsDirectory();

      List<File> securedFiles = [];
      final listOfThumbnail = _selectedVideoThumbnails.toList();
      int i = 0;

      for (final file in selectedVideos) {
        bool isDone = await vaultManager.copyFileInChunks(file);
        final metaData = {
          "file_name": file.path.split('/').last,
          "thumbnail": listOfThumbnail[i],
          "encrypted_path": '${appDir.path}/vault/${file.path.split('/').last}',
          "original_path": file.path,
          "size": file.lengthSync(),
          "type": "video",
          "created_at": DateTime.now().toIso8601String(),
        };
        database.insertFile(metaData);
        if (isDone) {
          file.deleteSync();
          securedFiles.add(file);
        }
        i++;
      }

      _updateVideoList(securedFiles);
      enableNotificationSetting(context, securedFiles.length);

      // Hide loading dialog
      Navigator.pop(context);

      _showCustomAlert(
        context: context,
        title: 'Videos Secured',
        message: '${securedFiles.length} videos have been moved to secure vault successfully',
        iconData: Icons.shield,
        iconColor: Colors.purple,
      );
    } catch (e) {
      // Hide loading dialog if showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showCustomAlert(
        context: context,
        title: 'Error',
        message: 'Failed to secure videos: $e',
        iconData: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

  void _updateVideoList(List<File> securedFiles) {
    setState(() {
      widget.videos.removeWhere((video) => securedFiles.contains(video['file']));
      _filteredVideos = List.from(widget.videos);
      selectedVideos.clear();
      _selectedVideoThumbnails.clear();
      _isSelecting = false;
      _sortVideos();
    });
  }

  Future<void> saveVideo() async {
    if (selectedVideos.isEmpty) return;

    try {
      _showLoadingDialog(context, 'Saving ${selectedVideos.length} videos...');

      OldFileManager.createMainFolder();
      final fileRecoveryHistory = FileRecoveryService();
      await fileRecoveryHistory.saveRecoveredFiles(selectedVideos, 'video');

      for (final video in selectedVideos) {
        OldFileManager.saveFile(video, 'video');
      }

      // Hide loading dialog
      Navigator.pop(context);

      _showCustomAlert(
        context: context,
        title: 'Success',
        message: '${selectedVideos.length} videos saved successfully',
        iconData: Icons.check_circle_outline,
        iconColor: Colors.green,
      );

      setState(() {
        selectedVideos.clear();
        _selectedVideoThumbnails.clear();
        _isSelecting = false;
      });
    } catch (e) {
      // Hide loading dialog if showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showCustomAlert(
        context: context,
        title: 'Error',
        message: 'Failed to save videos: $e',
        iconData: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

  display(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: CusColor.darkBlue3,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void enableNotificationSetting(BuildContext context, int val) {
    final currentState = context.read<SettingsBloc>().state;
    bool newValue = currentState.notifications;
    if (newValue == true) {
      NotificationService().showScanNotificationSecured(val);
    }
  }

}