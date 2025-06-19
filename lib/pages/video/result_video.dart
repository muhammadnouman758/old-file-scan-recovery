import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:old_file_recovery/first/shimmer/shimmer.dart';
import 'package:old_file_recovery/pages/video/fetch_video.dart';
import 'package:old_file_recovery/pages/video/video_player.dart';
import '../../setting/ui/setting_ui.dart';
import '../history/scan_records.dart';
import '../notification/notification_clas.dart';

class VideoFolderGridApp extends StatefulWidget {
  const VideoFolderGridApp({super.key});
  @override
  State<VideoFolderGridApp> createState() => _VideoFolderGridAppState();
}

class _VideoFolderGridAppState extends State<VideoFolderGridApp> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final VideoFetcher _videoFetcher = VideoFetcher();
  Map<String, List<Map<String, dynamic>>> _folders = {};
  int _filesScanned = 0;
  String _currentFolder = '';
  double _progress = 0.0;
  bool _isLoading = true;
  bool _hasCompletedFirstScan = false;
  String? _error;
  bool _isExiting = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _setupListeners();
    _startFetchingVideos();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _videoFetcher.isScanning) {
      _videoFetcher.cancelScan();
    }
  }

  void _setupListeners() {
    _videoFetcher.folderStream.listen((folders) {
      if (mounted) {
        setState(() {
          _folders = _convertFilePathsToFiles(folders);
          if (_folders.isNotEmpty) {
            _hasCompletedFirstScan = true;
            _animationController.forward();
          }
        });
      }
    });

    _videoFetcher.scannedFilesStream.listen((count) {
      if (mounted) {
        setState(() {
          _filesScanned = count;
        });
      }
    });

    _videoFetcher.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
          if (_progress >= 0.99 && _folders.isEmpty) {
            _isLoading = true;
          }
        });
      }
    });

    _videoFetcher.currentFolderStream.listen((folder) {
      if (mounted) {
        setState(() {
          _currentFolder = folder;
          if (folder == "Scan completed") {
            _isLoading = false;
            _hasCompletedFirstScan = true;
            _animationController.forward();
          }
        });
      }
    });

    _videoFetcher.errorStream.listen((error) {
      if (mounted && error != null) {
        setState(() {
          _error = error;
          _isLoading = false;
          _hasCompletedFirstScan = true;
        });
      }
    });
  }

  Map<String, List<Map<String, dynamic>>> _convertFilePathsToFiles(
      Map<String, List<Map<String, dynamic>>> folderData) {
    final result = <String, List<Map<String, dynamic>>>{};
    folderData.forEach((folderName, videos) {
      result[folderName] = videos.map((video) {
        return {
          'file': File(video['file']),
          'thumbnail': video['thumbnail'],
          'folderName': video['folderName'],
        };
      }).toList();
    });
    return result;
  }

  Future<void> _startFetchingVideos() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _filesScanned = 0;
        _error = null;
        _hasCompletedFirstScan = false;
      });
      _animationController.reset();
    }

    try {
      await _videoFetcher.fetchVideoFiles();
      if (mounted) {
        enableNotificationSetting(context, _filesScanned);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _hasCompletedFirstScan = true;
        });
      }
    }
  }

  Future<void> _refreshVideoFolders() async {
    if (_videoFetcher.isScanning) {
      _videoFetcher.cancelScan();
    }
    return _startFetchingVideos();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        backgroundColor: CusColor.decentWhite,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [CusColor.darkBlue3.withOpacity(0.9), CusColor.darkBlue3.withOpacity(0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          title: Text(
            'Video Folders',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
              letterSpacing: 0.5,
            ),
          ),
          leading: IconButton(
            onPressed: () => _handleBackButton(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            splashRadius: 24,
          ),
          actions: [
            AnimatedOpacity(
              opacity: _videoFetcher.isScanning ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IconButton(
                icon: const Icon(Icons.stop, color: Colors.white),
                onPressed: _videoFetcher.isScanning ? () => _videoFetcher.cancelScan() : null,
                splashRadius: 24,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshVideoFolders,
              splashRadius: 24,
            ),
          ],
        ),

        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [CusColor.decentWhite, Colors.grey[100]!],
            ),
          ),
          child: Column(
            children: [
              if (_videoFetcher.isScanning) _buildProgressIndicator(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _handleBackPress() async {
    return _handleBackButton();
  }

  bool _handleBackButton() {
    if (_videoFetcher.isScanning && !_isExiting) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Scanning in Progress',
            style: TextStyle(color: CusColor.darkBlue3, fontWeight: FontWeight.w600),
          ),
          content: const Text('Do you want to stop scanning and go back?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: CusColor.darkBlue3)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isExiting = true;
                });
                _videoFetcher.cancelScan();
                Navigator.of(context).pop();
              },
              child: const Text('Stop & Go Back', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return false;
    } else {
      if (_videoFetcher.isScanning) {
        _videoFetcher.cancelScan();
      }
      return true;
    }
  }

  Widget _buildProgressIndicator() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Scanning: $_currentFolder',
                    style: TextStyle(
                      color: CusColor.darkBlue3,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Files: $_filesScanned',
                  style: TextStyle(
                    color: CusColor.darkBlue3.withOpacity(0.7),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(CusColor.darkBlue3),
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return FadeTransition(
        opacity: _animationController,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48.sp),
              SizedBox(height: 16.h),
              Text(
                "Error loading videos: $_error",
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[800]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              _buildActionButton(
                text: 'Retry',
                onPressed: _refreshVideoFolders,
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasCompletedFirstScan) {
      return const Center(child: VideoScanningAnimation());
    }

    if (_folders.isEmpty) {
      return FadeTransition(
        opacity: _animationController,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: 48.sp, color: Colors.grey[400]),
              SizedBox(height: 16.h),
              Text(
                "No video folders found",
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[800]),
              ),
              SizedBox(height: 16.h),
              _buildActionButton(
                text: 'Scan Again',
                onPressed: _refreshVideoFolders,
                icon: Icons.search,
              ),
            ],
          ),
        ),
      );
    }

    streamListenerTo(_folders, 'video');
    return _buildFolderGrid(_folders);
  }

  Widget _buildFolderGrid(Map<String, List<Map<String, dynamic>>> folders) {
    return RefreshIndicator(
      onRefresh: _refreshVideoFolders,
      color: CusColor.darkBlue3,
      backgroundColor: Colors.white,
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 0.85,
        ),
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        itemCount: folders.keys.length,
        itemBuilder: (context, index) {
          final folderName = folders.keys.elementAt(index);
          final videos = folders[folderName]!;
          final firstVideoThumbnail = videos.isNotEmpty ? videos.first['thumbnail'] : null;

          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: _buildFolderItem(folderName, videos, firstVideoThumbnail),
          );
        },
      ),
    );
  }

  Widget _buildFolderItem(String folderName, List<Map<String, dynamic>> videos, String? thumbnailPath) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoFolderPage(folderName: folderName, videos: videos),
          ),
        );
      },
      child: Hero(
        tag: 'folder-$folderName',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoFolderPage(folderName: folderName, videos: videos),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          thumbnailPath != null
                              ? Image.file(
                            File(thumbnailPath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildFolderIcon(),
                          )
                              : _buildFolderIcon(),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: CusColor.darkBlue3.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${videos.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: CusColor.darkBlue3,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${videos.length} ${videos.length == 1 ? 'video' : 'videos'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12.sp,
                          ),
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
  }

  Widget _buildFolderIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CusColor.darkBlue3.withOpacity(0.1), CusColor.darkBlue3.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.folder,
          color: CusColor.darkBlue3,
          size: 40.sp,
        ),
      ),
    );
  }

  Widget _buildActionButton({required String text, required VoidCallback onPressed, required IconData icon}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: CusColor.darkBlue3,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      icon: Icon(icon, size: 20.sp),
      label: Text(
        text,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
    );
  }

  void streamListenerTo(Map<String, List<Map<String, dynamic>>> folder, String keyName) async {
    final videoFiles = folder.values.expand((list) => list.map((item) => item['file'])).toSet();
    final transformedData = [
      {
        'video': videoFiles,
      }
    ];
    final object = ScanHistoryTransform();
    ScanHistoryTransform.storeFiles(transformedData);
  }

  void enableNotificationSetting(BuildContext context, int scannedFiles) {
    final currentState = context.read<SettingsBloc>().state;
    bool notificationsEnabled = currentState.notifications;

    if (notificationsEnabled && scannedFiles > 0) {
      NotificationService().showScanNotification(scannedFiles);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _videoFetcher.dispose();
    super.dispose();
  }
}