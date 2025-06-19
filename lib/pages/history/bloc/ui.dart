import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:open_filex/open_filex.dart';
import '../../../video_player/video_player.dart';
import '../../audio/audio_player.dart';
import '../../images/image_detail.dart';
import '../scan_records.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';



class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});
  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final ScanHistoryBloc _scanHistoryBloc;
  final List<String> _fileTypes = ['image', 'video', 'audio', 'docs'];
  final List<dynamic> _fileIcons = [
    Icons.image_rounded,
    Icons.videocam_rounded,
    Icons.audiotrack_rounded,
    Icons.description_rounded
  ];

  bool _isGridView = true;
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  SortType _sortType = SortType.date;
  SortDirection _sortDirection = SortDirection.descending;

  late AnimationController _animationController;
  late List<GlobalKey> _navKeys;

  @override
  void initState() {
    super.initState();
    _scanHistoryBloc = ScanHistoryBloc();
    _scanHistoryBloc.add(LoadScans(_fileTypes[_selectedIndex]));

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _navKeys = List.generate(_fileTypes.length, (index) => GlobalKey());
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        _searchQuery = "";
        _searchController.clear();
      });
      _scanHistoryBloc.add(LoadScans(_fileTypes[index]));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scanHistoryBloc.close();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleViewMode() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = "";
        _searchController.clear();
        _scanHistoryBloc.add(LoadScans(_fileTypes[_selectedIndex]));
      }
    });
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _scanHistoryBloc.add(SearchScans(_fileTypes[_selectedIndex], query));
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Sort By'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<SortType>(
                title: const Text('Name'),
                value: SortType.name,
                groupValue: _sortType,
                onChanged: (value) {
                  setDialogState(() {
                    _sortType = value!;
                  });
                },
                activeColor: _getColorForFileType(_fileTypes[_selectedIndex]),
              ),
              RadioListTile<SortType>(
                title: const Text('Date'),
                value: SortType.date,
                groupValue: _sortType,
                onChanged: (value) {
                  setDialogState(() {
                    _sortType = value!;
                  });
                },
                activeColor: _getColorForFileType(_fileTypes[_selectedIndex]),
              ),
              RadioListTile<SortType>(
                title: const Text('Size'),
                value: SortType.size,
                groupValue: _sortType,
                onChanged: (value) {
                  setDialogState(() {
                    _sortType = value!;
                  });
                },
                activeColor: _getColorForFileType(_fileTypes[_selectedIndex]),
              ),
              const Divider(),
              RadioListTile<SortDirection>(
                title: const Text('Ascending'),
                value: SortDirection.ascending,
                groupValue: _sortDirection,
                onChanged: (value) {
                  setDialogState(() {
                    _sortDirection = value!;
                  });
                },
                activeColor: _getColorForFileType(_fileTypes[_selectedIndex]),
              ),
              RadioListTile<SortDirection>(
                title: const Text('Descending'),
                value: SortDirection.descending,
                groupValue: _sortDirection,
                onChanged: (value) {
                  setDialogState(() {
                    _sortDirection = value!;
                  });
                },
                activeColor: _getColorForFileType(_fileTypes[_selectedIndex]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              _scanHistoryBloc.add(SortScans(
                _fileTypes[_selectedIndex],
                _sortType,
                _sortDirection,
                // _searchQuery,
              ));
              Navigator.pop(context);
            },
            child: const Text('Apply'),

          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(Map<String, dynamic> scan) {
    final String fileType = scan['file_type'].toString().toLowerCase();
    final String filePath = scan['file_path'];

    if (fileType.contains('jpg') || fileType.contains('jpeg') ||
        fileType.contains('png') || fileType.contains('gif')) {
      return Hero(
        tag: 'file_${scan['id']}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(filePath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.broken_image_rounded,
              size: 45,
              color: CusColor.darkBlue3.withOpacity(0.7),
            ),
          ),
        ),
      );
    } else if (fileType.contains('mp4') || fileType.contains('mov')) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
                Icons.play_circle_fill_rounded,
                size: 45,
                color: CusColor.darkBlue3.withOpacity(0.8)
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Video',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            )
          ],
        ),
      );
    } else if (fileType.contains('mp3') || fileType.contains('wav')) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF667EEA).withOpacity(0.7),
              const Color(0xFF764BA2).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.audio_file_rounded, size: 45, color: Colors.white),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0BA360).withOpacity(0.7),
              const Color(0xFF3CBA92).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.insert_drive_file_rounded, size: 45, color: Colors.white),
        ),
      );
    }
  }

  void _showFileDetailsBottomSheet(BuildContext context, Map<String, dynamic> scan) {
    final String fileType = scan['file_type'].toString().toLowerCase();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 50.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  scan['file_name'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 200.h,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: fileType.contains('jpg') || fileType.contains('jpeg') ||
                      fileType.contains('png') || fileType.contains('gif')
                      ? Image.file(
                    File(scan['file_path']),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[100],
                      child: const Icon(Icons.broken_image_rounded, size: 100),
                    ),
                  )
                      : Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: Icon(
                        fileType.contains('mp4') || fileType.contains('mov')
                            ? Icons.movie_rounded
                            : fileType.contains('mp3') || fileType.contains('wav')
                            ? Icons.audiotrack_rounded
                            : Icons.insert_drive_file_rounded,
                        size: 100,
                        color: _getColorForFileType(scan['folder_name']),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _detailTile('File Name', scan['file_name']),
                    _detailTile('File Type', '${scan['folder_name']} (${scan['file_type']})'),
                    _detailTile('Scan Date', formatDate(scan['scan_date'])),
                    _detailTile('File Path', scan['file_path']),
                    _detailTile('File Size', _formatFileSize(scan['file_size'] ?? 0)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToViewer(context, scan),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Open'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getColorForFileType(scan['folder_name']),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Delete File'),
                              content: const Text('Are you sure you want to delete this file?'),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _scanHistoryBloc.add(DeleteScan(scan['id'], scan['folder_name']));
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('File deleted successfully'),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        margin: const EdgeInsets.all(10),
                                      ),
                                    );
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  Color _getColorForFileType(String folderName) {
    switch (folderName.toLowerCase()) {
      case 'image':
        return const Color(0xFF4FACFE);
      case 'video':
        return const Color(0xFFF6D365);
      case 'audio':
        return const Color(0xFF667EEA);
      case 'docs':
        return const Color(0xFF0BA360);
      default:
        return CusColor.darkBlue3;
    }
  }

  void _navigateToViewer(BuildContext context, Map<String, dynamic> scan) {
    final String filePath = scan['file_path'];
    final String fileType = scan['file_type'].toString().toLowerCase();
    final String folderName = scan['folder_name'].toString().toLowerCase();
    final File file = File(filePath);

    if (folderName == 'image') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => FullImagePage(image: file),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else if (folderName == 'video') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(title: scan['file_name'], videoUrl: filePath),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else if (folderName == 'audio') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => AudioPlayerPage(audioFile: file),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else if (folderName == 'docs') {
      _openDocumentWithUrlLauncher(file);
    } else {
      if (fileType.contains('jpg') || fileType.contains('jpeg') ||
          fileType.contains('png') || fileType.contains('gif')) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => FullImagePage(image: file),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else if (fileType.contains('mp4') || fileType.contains('mov')) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(title: scan['file_name'], videoUrl: filePath),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else if (fileType.contains('mp3') || fileType.contains('wav')) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => AudioPlayerPage(audioFile: file),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        _openDocumentWithUrlLauncher(file);
      }
    }
  }

  Future<void> _openDocumentWithUrlLauncher(File file) async {
    try {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening file: ${result.message}'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  Widget _detailTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
          Divider(
            height: 16,
            color: Colors.grey[200],
            thickness: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final categoryColor = _getColorForFileType(_fileTypes[_selectedIndex]);

    return Center(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _fileIcons[_selectedIndex],
                size: 60,
                color: categoryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results found for "$_searchQuery"'
                  : 'No ${_fileTypes[_selectedIndex]} files found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Scan some files to see them here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _scanHistoryBloc.add(LoadScans(_fileTypes[_selectedIndex]));
              },
              icon: const Icon(Icons.document_scanner_rounded),
              label: const Text('Scan now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: categoryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> scans) {
    return RefreshIndicator(
      onRefresh: () async {
        _scanHistoryBloc.add(LoadScans(_fileTypes[_selectedIndex]));
        return Future.delayed(const Duration(milliseconds: 1500));
      },
      color: _getColorForFileType(_fileTypes[_selectedIndex]),
      child: AnimationLimiter(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: scans.length,
          itemBuilder: (context, index) {
            final scan = scans[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 500),
              columnCount: 2,
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: GestureDetector(
                    onTap: () => _showFileDetailsBottomSheet(context, scan),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: Container(
                                width: double.infinity,
                                color: Colors.grey[100],
                                child: _buildFilePreview(scan),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  scan['file_name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        formatDate(scan['scan_date']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> scans) {
    return RefreshIndicator(
      onRefresh: () async {
        _scanHistoryBloc.add(LoadScans(_fileTypes[_selectedIndex]));
        return Future.delayed(const Duration(milliseconds: 1500));
      },
      color: _getColorForFileType(_fileTypes[_selectedIndex]),
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scans.length,
          itemBuilder: (context, index) {
            final scan = scans[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 400),
              child: SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      onTap: () => _showFileDetailsBottomSheet(context, scan),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: _buildFilePreview(scan),
                        ),
                      ),
                      title: Text(
                        scan['file_name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            scan['file_type'].toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatDate(scan['scan_date']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.open_in_new_rounded),
                                  title: const Text('Open'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _navigateToViewer(context, scan);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _scanHistoryBloc.add(DeleteScan(scan['id'], scan['folder_name']));
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CusColor.decentWhite,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getColorForFileType(_fileTypes[_selectedIndex]),
                _getColorForFileType(_fileTypes[_selectedIndex]).withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: _isSearching
            ? TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search files...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          autofocus: true,
          onChanged: _performSearch,
        )
            : const Text(
          'Scan History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: Colors.white),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            onPressed: _showSortDialog,
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: Colors.white),
            onPressed: _toggleViewMode,
          ),
        ],
      ),
      body: BlocProvider(
        create: (_) => _scanHistoryBloc,
        child: BlocBuilder<ScanHistoryBloc, ScanHistoryState>(
          builder: (context, state) {
            if (state is ScanHistoryLoading) {
              return Center(
                child: CircularProgressIndicator(color: _getColorForFileType(_fileTypes[_selectedIndex])),
              );
            } else if (state is ScanHistoryError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 70, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _scanHistoryBloc.add(LoadScans(_fileTypes[_selectedIndex])),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getColorForFileType(_fileTypes[_selectedIndex]),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is ScanHistoryLoaded) {
              if (state.scans.isEmpty) {
                return _buildEmptyState();
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isGridView
                    ? _buildGridView(state.scans)
                    : _buildListView(state.scans),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to scan screen or trigger scan action
        },
        backgroundColor: _getColorForFileType(_fileTypes[_selectedIndex]),
        child: const Icon(Icons.document_scanner_rounded, color: Colors.white),
      ),
      bottomNavigationBar: _buildGlassBottomNavBar(),
    );
  }

  Widget _buildGlassBottomNavBar() {
    final List<List<Color>> itemGradients = [
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFFF6D365), const Color(0xFFFDA085)],
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFF0BA360), const Color(0xFF3CBA92)],
    ];

    return Container(
      height: 75,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _fileTypes.length,
              (index) {
            bool isSelected = _selectedIndex == index;
            return _buildBottomNavItem(
              icon: _fileIcons[index],
              label: _fileTypes[index].capitalize(),
              isSelected: isSelected,
              onTap: () => _onItemTapped(index),
              gradientColors: itemGradients[index],
              key: _navKeys[index],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required List<Color> gradientColors,
    required Key key,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Container(
          key: key,
          width: isSelected ? 110.w + (20 * value) : 60.w,
          height: 48.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isSelected
                ? LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isSelected ? null : Colors.transparent,
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 10 * value,
                spreadRadius: 2 * value,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              splashColor: Colors.white.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey,
                      size: 22 + (2 * value),
                    ),
                    SizedBox(width: isSelected ? 6 * value : 0),
                    if (isSelected)
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: Opacity(
                            opacity: value,
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

String formatDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    return '${date.day}/${date.month}/${date.year}';
  } catch (e) {
    return isoDate;
  }
}