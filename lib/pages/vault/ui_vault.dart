import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:old_file_recovery/pages/audio/audio_player.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:old_file_recovery/pages/images/image_detail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_filex/open_filex.dart';

import '../../video_player/video_player.dart';
import 'move_file_to_vault/vault_database.dart';

class VaultPage extends StatefulWidget {
  final String fileType;

  const VaultPage({super.key, required this.fileType});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<Map<String, dynamic>> _files = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String _currentSortType = 'date';
  final DatabaseHelperVault _databaseHelper = DatabaseHelperVault(); // Initialize database helper

  final Map<String, String> _categoryTitles = {
    'video': 'Video Files',
    'audio': 'Audio Files',
    'docs': 'Documents',
    'image': 'Images',
  };

  final Map<String, IconData> _categoryIcons = {
    'video': Icons.video_library_rounded,
    'audio': Icons.audiotrack_rounded,
    'docs': Icons.description_rounded,
    'image': Icons.photo_rounded,
  };

  final Map<String, Color> _categoryColors = {
    'video': const Color(0xFF5E72E4),
    'audio': const Color(0xFFFF9D54),
    'docs': const Color(0xFF11CDEF),
    'image': const Color(0xFFF5365C),
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _loadFiles();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get files from database by type
      final files = await _databaseHelper.getFilesByType(widget.fileType);

      setState(() {
        _files = files;
        _isLoading = false;
      });

      // Apply current sort
      _sortFiles(_currentSortType);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading files: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteFile(int id) async {
    try {
      await _databaseHelper.deleteFile(id);
      setState(() {
        _files.removeWhere((file) => file['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File removed from vault')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting file: ${e.toString()}')),
      );
    }
  }

  void _sortFiles(String sortType) {
    setState(() {
      _currentSortType = sortType;

      switch (sortType) {
        case 'name':
          _files.sort((a, b) => a['file_name'].toString().compareTo(b['file_name'].toString()));
          break;
        case 'size':
          _files.sort((a, b) => (b['size'] ?? 0).compareTo(a['size'] ?? 0));
          break;
        case 'date':
        default:
          _files.sort((a, b) => b['created_at'].toString().compareTo(a['created_at'].toString()));
          break;
      }
    });
  }

  void _navigateToViewer(String file) {
    switch (widget.fileType) {
      case 'image':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FullImagePage(image: File(file))),
        );
        break;
      case 'video':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VideoPlayerScreen(title: file, videoUrl: File(file).path)),
        );
        break;
      case 'docs':
      // Open document with URL launcher
        _openDocumentWithUrlLauncher(File(file));
        break;
      case 'audio':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AudioPlayerPage(audioFile: File(file))),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot view this file type')),
        );
        return;
    }
  }

  Future<void> _openDocumentWithUrlLauncher(File file) async {
    try {
      OpenFilex.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening document: ${e.toString()}')),
      );
    }
  }

  Future<void> _restoreFile(Map<String, dynamic> file) async {
    try {
      setState(() => _isLoading = true);

      final sourceFile = File(file['encrypted_path']);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist');
      }

      final destinationPath = file['original_path'];
      final destinationDir = Directory(path.dirname(destinationPath));

      // Create destination directory if it doesn't exist
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      final destinationFile = File(destinationPath);

      // Use File.copy to efficiently handle the file transfer
      await sourceFile.copy(destinationFile.path);

      // Verify the destination file exists after copying
      if (await destinationFile.exists()) {
        // Delete the database entry and source file only after successful copy
        await _databaseHelper.deleteFile(file['id']);
        await sourceFile.delete();

        setState(() {
          _files.removeWhere((item) => item['id'] == file['id']);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File restored successfully')),
        );
      } else {
        throw Exception('Failed to restore file');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restoring file: ${e.toString()}')),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color categoryColor = _categoryColors[widget.fileType] ?? CusColor.darkBlue3;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Text(
          _categoryTitles[widget.fileType] ?? "Files",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            tooltip: 'Back',
            splashRadius: 24,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
              icon: Icon(
                  _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  color: Colors.white,
                  size: 20
              ),
              tooltip: _isGridView ? 'List View' : 'Grid View',
              splashRadius: 24,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(_categoryIcons[widget.fileType] ?? Icons.folder,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "${_files.length} ${widget.fileType} files secured",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
                            ),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('Date', 'date'),
                                SizedBox(width: 10.w),
                                _buildFilterChip('Name', 'name'),
                                SizedBox(width: 10.w),
                                _buildFilterChip('Size', 'size'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Files list/grid
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _files.isEmpty
                      ? _buildEmptyState()
                      : _isGridView
                      ? _buildGridView()
                      : _buildListView(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: categoryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // This would navigate to add file screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add file functionality coming soon')),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String sortType) {
    final isSelected = _currentSortType == sortType;
    final categoryColor = _categoryColors[widget.fileType] ?? CusColor.darkBlue3;

    return InkWell(
      onTap: () => _sortFiles(sortType),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(50),
          border: isSelected
              ? Border.all(color: categoryColor, width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? categoryColor : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _categoryIcons[widget.fileType] ?? Icons.folder_off_rounded,
              size: 70,
              color: Colors.grey.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              "No ${widget.fileType} files yet",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add files to secure them in your vault",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Files"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _categoryColors[widget.fileType],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add file functionality coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 80),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final file = _files[index];
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final delay = index * 0.05;
              final start = 0.3 + delay;
              final end = 0.6 + delay;

              final slideAnimation = Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Interval(start, end, curve: Curves.easeOut),
              ));

              final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(start, end, curve: Curves.easeOut),
                ),
              );
              return FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              );
            },
            child: _buildFileGridItem(file, index),
          );
        },
        itemCount: _files.length,
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 80),
      itemBuilder: (context, index) {
        final file = _files[index];

        // Staggered animation for list items
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final delay = index * 0.05;
            final start = 0.3 + delay;
            final end = 0.6 + delay;

            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Interval(start, end, curve: Curves.easeOut),
            ));

            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(start, end, curve: Curves.easeOut),
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
          child: _buildFileListItem(file, index),
        );
      },
      itemCount: _files.length,
    );
  }

  Widget _buildFileGridItem(Map<String, dynamic> file, int index) {
    final fileName = file['file_name'] ?? 'Unknown';
    final fileSize = _formatFileSize(file['size'] ?? 0);
    final dateAdded = _formatDate(file['created_at'] ?? '');
    final categoryColor = _categoryColors[widget.fileType] ?? CusColor.darkBlue3;

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _navigateToViewer(file['encrypted_path']);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail area
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                height: 90.h,
                width: double.infinity,
                color: categoryColor.withOpacity(0.1),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Default file type icon
                    Icon(
                      _categoryIcons[widget.fileType] ?? Icons.insert_drive_file_rounded,
                      size: 40,
                      color: categoryColor,
                    ),

                    // Options menu
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.more_vert, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) => _buildFileOptionsMenu(file, index),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // File info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF2D3748),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$fileSize • $dateAdded",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildFileListItem(Map<String, dynamic> file, int index) {
    final fileName = file['file_name'] ?? 'Unknown';
    final fileSize = _formatFileSize(file['size'] ?? 0);
    final dateAdded = _formatDate(file['created_at'] ?? '');
    final categoryColor = _categoryColors[widget.fileType] ?? CusColor.darkBlue3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            _navigateToViewer(file['encrypted_path']);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // File type icon/thumbnail
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _categoryIcons[widget.fileType] ?? Icons.insert_drive_file_rounded,
                    color: categoryColor,
                    size: 24,
                  ),
                ),

                SizedBox(width: 16.w),

                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF2D3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$fileSize • $dateAdded",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => _buildFileOptionsMenu(file, index),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileOptionsMenu(Map<String, dynamic> file, int index) {
    final categoryColor = _categoryColors[widget.fileType] ?? CusColor.darkBlue3;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
        
            Text(
              file['file_name'] ?? 'File Options',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
        
            _buildOptionItem(
              icon: Icons.visibility_rounded,
              color: categoryColor,
              label: 'View File',
              onTap: () {
                Navigator.pop(context);
                _navigateToViewer(file["encrypted_path"]);
              },
            ),
        
            _buildOptionItem(
              icon: Icons.file_download_outlined,
              color: Colors.green,
              label: 'Restore Original',
              onTap: () {
                Navigator.pop(context);
                _restoreFile(file);
              },
            ),
        
            _buildOptionItem(
              icon: Icons.share_rounded,
              color: Colors.blue,
              label: 'Share Securely',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Secure sharing coming soon')),
                );
              },
            ),
        
            _buildOptionItem(
              icon: Icons.info_outline_rounded,
              color: Colors.grey[700]!,
              label: 'File Details',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File details coming soon')),
                );
              },
            ),
        
            _buildOptionItem(
              icon: Icons.delete_outline_rounded,
              color: Colors.red,
              label: 'Delete from Vault',
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: Text('Are you sure you want to remove "${file['file_name']}" from your vault? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFile(file['id']);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    child: Row(
    children: [
    Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(10),

    ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    ),
      SizedBox(width: 16.w),
      Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
    ),
        ),
    );
  }
}