import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../history/scan_records.dart';

enum VideoCategory { all, movie, short, video }

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> with SingleTickerProviderStateMixin {
  final ScanHistoryBloc _scanHistoryBloc = ScanHistoryBloc();
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;
  final _scrollController = ScrollController();
  final Map<String, VideoPlayerController> _controllerCache = {};

  List<Map<String, dynamic>> _allVideos = [];
  List<Map<String, dynamic>> _filteredVideos = [];
  List<Map<String, dynamic>> _shorts = [];
  String _selectedMovieGenre = 'All';
  SortType _currentSortType = SortType.date;
  SortDirection _currentSortDirection = SortDirection.descending;
  VideoCategory _selectedCategory = VideoCategory.all;
  bool _isLoading = false;
  String? _currentlyPlayingVideoPath;
  Timer? _searchDebounce;
  bool _isLandscape = false;

  static const List<String> _movieGenres = ['All', 'Action', 'Comedy', 'Drama', 'Sci-Fi'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadVideos();
    _searchController.addListener(_onSearchChanged);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;

    setState(() {
      _selectedCategory = switch (_tabController.index) {
        0 => VideoCategory.all,
        1 => VideoCategory.movie,
        2 => VideoCategory.short,
        3 => VideoCategory.video,
        _ => VideoCategory.all,
      };
      _selectedMovieGenre = 'All';
      _filterVideos();
    });
  }

  void _loadVideos() {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    _scanHistoryBloc.add(LoadScans(
      'video',
      sortType: _currentSortType,
      sortDirection: _currentSortDirection,
    ));
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(_filterVideos);
      }
    });
  }

  void _filterVideos() {
    if (_allVideos.isEmpty) {
      _filteredVideos = [];
      _shorts = [];
      return;
    }

    final searchQuery = _searchController.text.toLowerCase();
    const movieThreshold = 50 * 1024 * 1024;
    const shortThreshold = 10 * 1024 * 1024;

    _filteredVideos = _allVideos.where((video) {
      if (searchQuery.isNotEmpty && _selectedCategory != VideoCategory.movie) {
        final fileName = video['file_name'].toString().toLowerCase();
        final filePath = video['file_path'].toString().toLowerCase();
        final fileType = video['file_type'].toString().toLowerCase();
        if (!fileName.contains(searchQuery) &&
            !filePath.contains(searchQuery) &&
            !fileType.contains(searchQuery)) {
          return false;
        }
      }

      final fileSize = video['file_size'] as int;
      bool categoryMatch = switch (_selectedCategory) {
        VideoCategory.all => true,
        VideoCategory.movie => fileSize > movieThreshold,
        VideoCategory.short => fileSize < shortThreshold,
        VideoCategory.video => fileSize >= shortThreshold && fileSize <= movieThreshold,
      };

      if (_selectedCategory == VideoCategory.movie && _selectedMovieGenre != 'All') {
        return categoryMatch;
      }

      return categoryMatch;
    }).toList();

    _shorts = _allVideos.where((video) => video['file_size'] < shortThreshold).toList();
    _sortFilteredVideos();
  }

  void _sortFilteredVideos() {
    _filteredVideos.sort((a, b) {
      final ascending = _currentSortDirection == SortDirection.ascending ? 1 : -1;
      switch (_currentSortType) {
        case SortType.name:
          return ascending * a['file_name'].toString().compareTo(b['file_name'].toString());
        case SortType.date:
          return ascending * a['scan_date'].toString().compareTo(b['scan_date'].toString());
        case SortType.size:
          return ascending * (a['file_size'] as int).compareTo(b['file_size'] as int);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    for (var controller in _controllerCache.values) {
      controller.dispose();
    }
    _controllerCache.clear();
    super.dispose();
  }

  String _formatFileSize(int sizeInBytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = sizeInBytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  String _formatDate(String isoDate) {
    try {
      return DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SortBottomSheet(
        currentSortType: _currentSortType,
        currentSortDirection: _currentSortDirection,
        onSortChanged: (type, direction) {
          setState(() {
            _currentSortType = type;
            _currentSortDirection = direction;
            _filterVideos();
          });
        },
      ),
    );
  }

  void _deleteVideo(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Are you sure you want to delete this video?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _scanHistoryBloc.add(DeleteScan(id, 'video'));
              setState(() {
                final deletedVideo = _allVideos.firstWhere(
                      (v) => v['id'] == id,
                  orElse: () => {},
                );
                _allVideos.removeWhere((video) => video['id'] == id);
                if (deletedVideo.isNotEmpty && _controllerCache.containsKey(deletedVideo['file_path'])) {
                  _controllerCache[deletedVideo['file_path']]?.dispose();
                  _controllerCache.remove(deletedVideo['file_path']);
                  if (_currentlyPlayingVideoPath == deletedVideo['file_path']) {
                    _currentlyPlayingVideoPath = null;
                  }
                }
                _filterVideos();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video deleted')),
              );
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _playVideo(Map<String, dynamic> video) {
    final filePath = video['file_path'] as String;

    if (_controllerCache.containsKey(filePath)) {
      setState(() {
        _currentlyPlayingVideoPath = filePath;
        _controllerCache[filePath]!.play();
      });

    }

    if (_controllerCache.length > 3) {
    final oldestPath = _controllerCache.keys.first;
    _controllerCache[oldestPath]?.dispose();
    _controllerCache.remove(oldestPath);
    }

    final controller = VideoPlayerController.file(File(filePath));

    controller.initialize().then((_) {
    if (controller.value.isInitialized && mounted) {
    setState(() {
    _currentlyPlayingVideoPath = filePath;
    _controllerCache[filePath] = controller;
    controller.play();
    });
    }
    }).catchError((error) {
    if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error loading video: ${error.toString()}')),
    );
    }
    });
  }

  void _onOrientationChanged(bool isLandscape) {
    setState(() {
      _isLandscape = isLandscape;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: _VideoPlayerWidget(
              controller: _currentlyPlayingVideoPath != null
                  ? _controllerCache[_currentlyPlayingVideoPath]
                  : null,
              fileName: _currentlyPlayingVideoPath != null
                  ? _allVideos.firstWhere(
                    (v) => v['file_path'] == _currentlyPlayingVideoPath,
                orElse: () => {'file_name': ''},
              )['file_name'] as String
                  : '',
              onClose: () {
                setState(() {
                  if (_currentlyPlayingVideoPath != null) {
                    _controllerCache[_currentlyPlayingVideoPath]?.pause();
                  }
                  _currentlyPlayingVideoPath = null;
                });
              },
              onOrientationChanged: _onOrientationChanged,
            ),
          ),
          if (_selectedCategory != VideoCategory.movie && !_isLandscape)
            SliverToBoxAdapter(
              child: _SearchBar(
                controller: _searchController,
                isDarkMode: isDarkMode,
              ),
            ),
          SliverToBoxAdapter(
            child: BlocConsumer<ScanHistoryBloc, ScanHistoryState>(
              bloc: _scanHistoryBloc,
              listener: (context, state) {
                if (state is ScanHistoryLoaded) {
                  setState(() {
                    _allVideos = state.scans;
                    _isLoading = false;
                    _filterVideos();
                  });
                } else if (state is ScanHistoryError) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${state.message}')),
                  );
                }
              },
              builder: (context, state) {
                if (state is ScanHistoryInitial || _isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_filteredVideos.isEmpty) {
                  return _EmptyState(
                    isDarkMode: isDarkMode,
                    hasSearch: _searchController.text.isNotEmpty,
                    onClearSearch: () {
                      setState(() {
                        _searchController.clear();
                        _filterVideos();
                      });
                    },
                  );
                }

                if (_selectedCategory == VideoCategory.movie) {
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_filteredVideos.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0,right: 16,top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FeaturedVideoCard(
                                  video: _filteredVideos[0],
                                  onPlay: () => _playVideo(_filteredVideos[0]),
                                ),
                              ],
                            ),
                          ),
                        _buildContentSection(
                          title: "All Movies",
                          videos: _filteredVideos,
                          onPlay: _playVideo,
                          onDelete: _deleteVideo,
                          onShowDetails: _showVideoDetails,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                } else {
                  return RefreshIndicator(
                    onRefresh: () async => _loadVideos(),
                    child: _selectedCategory == VideoCategory.all
                        ? _VideoListView(
                      videos: _filteredVideos,
                      shorts: _shorts,
                      isDarkMode: isDarkMode,
                      onPlay: _playVideo,
                      onDelete: _deleteVideo,
                      onShowDetails: _showVideoDetails,
                    )
                        : _VideoGridView(
                      videos: _filteredVideos,
                      isDarkMode: isDarkMode,
                      onPlay: _playVideo,
                      onDelete: _deleteVideo,
                      onShowDetails: _showVideoDetails,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isLandscape
          ? null
          : Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showSortBottomSheet,
            backgroundColor: Theme.of(context).primaryColor,
            heroTag: 'sort',
            child: const Icon(Icons.sort),
            tooltip: 'Sort videos',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _loadVideos,
            backgroundColor: Theme.of(context).primaryColor,
            heroTag: 'refresh',
            child: const Icon(Icons.refresh),
            tooltip: 'Refresh videos',
          ),
        ],
      ),
      bottomNavigationBar: _isLandscape
          ? null
          : BottomNavigationBar(
        currentIndex: _tabController.index,
        onTap: (index) => _tabController.animateTo(index),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'All Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: 'Movies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam),
            label: 'Shorts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_file),
            label: 'Videos',
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection({
    required String title,
    required List<Map<String, dynamic>> videos,
    required Function(Map<String, dynamic>) onPlay,
    required Function(int) onDelete,
    required Function(Map<String, dynamic>) onShowDetails,
  }) {
    if (videos.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          "No $title available",
          style: const TextStyle(fontSize: 18.0, color: Colors.grey),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 300.h,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              scrollDirection: Axis.vertical,
              itemCount: videos.length,
              itemBuilder: (context, index) {
                return VideoCard(
                  video: videos[index],
                  onPlay: () => onPlay(videos[index]),
                  onDelete: () => onDelete(videos[index]['id'] as int),
                  onShowDetails: () => onShowDetails(videos[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showVideoDetails(Map<String, dynamic> video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const SizedBox(),
    );
  }
}

class FeaturedVideoCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final VoidCallback onPlay;

  const FeaturedVideoCard({Key? key, required this.video, required this.onPlay}) : super(key: key);

  String _formatFileSize(int sizeInBytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = sizeInBytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final fileName = video['file_name'] as String;
    final fileSize = video['file_size'] as int;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onPlay,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 160.h,
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: IconButton(
                icon: Icon(
                  Icons.play_circle_filled,
                  size: 48.sp,
                  color: Colors.white.withOpacity(0.9),
                ),
                onPressed: onPlay,
                tooltip: 'Play video',
              ),
            ),
            Positioned(
              bottom: 12.h,
              left: 12.w,
              right: 12.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    semanticsLabel: fileName,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatFileSize(fileSize),
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback onShowDetails;

  const VideoCard({
    Key? key,
    required this.video,
    required this.onPlay,
    required this.onDelete,
    required this.onShowDetails,
  }) : super(key: key);

  String _getCategory(int fileSize) {
    const movieThreshold = 50 * 1024 * 1024;
    const shortThreshold = 10 * 1024 * 1024;
    return switch (fileSize) {
      > movieThreshold => 'Movie',
      < shortThreshold => 'Short',
      _ => 'Video',
    };
  }

  @override
  Widget build(BuildContext context) {
    final fileName = video['file_name'] as String;
    final fileSize = video['file_size'] as int;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onPlay,
      child: Container(
        margin: EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            Hero(
              tag: 'video_$fileName',
              child: Container(
                height: 90,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12.0),
                    bottomLeft: Radius.circular(12.0),
                  ),
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.movie,
                      color: isDarkMode ? Colors.white54 : Colors.black38,
                      size: 36,
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          '2:30:00', // Replace with actual duration formatter
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 14.0,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          _getCategory(fileSize),
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Icon(
                          Icons.storage_outlined,
                          size: 14.0,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          _formatFileSize(fileSize),
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.more_vert,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDarkMode;

  const _SearchBar({required this.controller, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search videos...',
          prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            onPressed: controller.clear,
          )
              : null,
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerController? controller;
  final String fileName;
  final VoidCallback onClose;
  final Function(bool) onOrientationChanged;

  const _VideoPlayerWidget({
    required this.controller,
    required this.fileName,
    required this.onClose,
    required this.onOrientationChanged,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late bool _isPlaying;
  double _volume = 1.0;
  bool _showControls = true;
  bool _isLandscape = false;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.controller?.value.isPlaying ?? false;
    widget.controller?.addListener(_updatePlayState);
    _startControlsTimer();
  }

  void _updatePlayState() {
    if (mounted) {
      setState(() {
        _isPlaying = widget.controller?.value.isPlaying ?? false;
      });
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startControlsTimer();
      }
    });
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
      if (_isLandscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        widget.onOrientationChanged(true);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        widget.onOrientationChanged(false);
      }
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_updatePlayState);
    _controlsTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Colors.black,
      height: _isLandscape
          ? MediaQuery.of(context).size.height
          : MediaQuery.of(context).size.height * 0.3,
      child: widget.controller?.value.isInitialized ?? false
          ? GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller!.value.aspectRatio,
                child: VideoPlayer(widget.controller!),
              ),
            ),
            if (_showControls) ...[
              Positioned(
                left: 8,
                top: 50,
                bottom: 50,
                child: Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: Theme.of(context).primaryColor,
                      inactiveColor: Colors.grey,
                      onChanged: (value) {
                        setState(() {
                          _volume = value;
                          widget.controller?.setVolume(value);
                        });
                        _startControlsTimer();
                      },
                    ),
                  ),
                ),
              ),
              Center(
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 64,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  onPressed: () {
                    if (_isPlaying) {
                      widget.controller?.pause();
                    } else {
                      widget.controller?.play();
                    }
                    _startControlsTimer();
                  },
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.fileName.isNotEmpty)
                      Text(
                        widget.fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    VideoProgressIndicator(
                      widget.controller!,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: Theme.of(context).primaryColor,
                        bufferedColor: Colors.white54,
                        backgroundColor: Colors.grey,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: widget.controller!,
                          builder: (context, VideoPlayerValue value, child) {
                            return Text(
                              _formatDuration(value.position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: widget.controller!,
                          builder: (context, VideoPlayerValue value, child) {
                            return Text(
                              _formatDuration(value.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(
                    _isLandscape
                        ? Icons.screen_rotation
                        : Icons.screen_rotation,
                    color: Colors.white,
                  ),
                  onPressed: _toggleOrientation,
                  tooltip: _isLandscape
                      ? 'Back to Portrait'
                      : 'Rotate to Landscape',
                ),
              ),
            ],
          ],
        ),
      )
          : const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam, size: 64, color: Colors.white54),
            SizedBox(height: 8),
            Text('No video selected', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDarkMode;
  final bool hasSearch;
  final VoidCallback onClearSearch;

  const _EmptyState({
    required this.isDarkMode,
    required this.hasSearch,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 80,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'No videos found' : 'Your video library is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try a different search term'
                  : 'Scan your device to find videos',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
            if (hasSearch) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onClearSearch,
                child: const Text('Clear Search'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoListView extends StatelessWidget {
  final List<Map<String, dynamic>> videos;
  final List<Map<String, dynamic>> shorts;
  final bool isDarkMode;
  final Function(Map<String, dynamic>) onPlay;
  final Function(int) onDelete;
  final Function(Map<String, dynamic>) onShowDetails;

  const _VideoListView({
    required this.videos,
    required this.shorts,
    required this.isDarkMode,
    required this.onPlay,
    required this.onDelete,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    const shortThreshold = 10 * 1024 * 1024;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: videos.length + (shorts.isNotEmpty ? (videos.length ~/ 3) : 0),
      itemBuilder: (context, index) {
        if (shorts.isNotEmpty && index > 0 && index % 3 == 0) {
          return _ShortsRow(
            shorts: shorts,
            isDarkMode: isDarkMode,
            onPlay: onPlay,
            onDelete: onDelete,
            onShowDetails: onShowDetails,
          );
        }
        final videoIndex = index - (index ~/ 3);
        if (videoIndex >= videos.length) return const SizedBox.shrink();
        final video = videos[videoIndex];
        if (video['file_size'] < shortThreshold) return const SizedBox.shrink();
        return _VideoListItem(
          video: video,
          isDarkMode: isDarkMode,
          onPlay: () => onPlay(video),
          onDelete: () => onDelete(video['id'] as int),
          onShowDetails: () => onShowDetails(video),
        );
      },
    );
  }
}

class _VideoGridView extends StatelessWidget {
  final List<Map<String, dynamic>> videos;
  final bool isDarkMode;
  final Function(Map<String, dynamic>) onPlay;
  final Function(int) onDelete;
  final Function(Map<String, dynamic>) onShowDetails;

  const _VideoGridView({
    required this.videos,
    required this.isDarkMode,
    required this.onPlay,
    required this.onDelete,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) => _VideoGridItem(
        video: videos[index],
        isDarkMode: isDarkMode,
        onPlay: () => onPlay(videos[index]),
        onDelete: () => onDelete(videos[index]['id'] as int),
        onShowDetails: () => onShowDetails(videos[index]),
      ),
    );
  }
}

class _VideoListItem extends StatelessWidget {
  final Map<String, dynamic> video;
  final bool isDarkMode;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback onShowDetails;
  final bool isShort;

  const _VideoListItem({
    required this.video,
    required this.isDarkMode,
    required this.onPlay,
    required this.onDelete,
    required this.onShowDetails,
    this.isShort = false,
  });

  String _formatFileSize(int sizeInBytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = sizeInBytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  String _formatDate(String isoDate) {
    try {
      return DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = video['file_name'] as String;
    final fileSize = video['file_size'] as int;
    final scanDate = video['scan_date'] as String;
    final fileType = video['file_type'] as String;
    const movieThreshold = 50 * 1024 * 1024;
    const shortThreshold = 10 * 1024 * 1024;

    final (category, categoryColor) = switch (fileSize) {
      > movieThreshold => ('MOVIE', Colors.red),
      < shortThreshold => ('SHORT', Colors.blue),
      _ => ('VIDEO', Colors.green),
    };

    return GestureDetector(
      onTap: onPlay,
      child: Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(horizontal: isShort ? 4 : 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Container(
                    height: isShort ? 120 : 130,
                    width: isShort ? 80 : double.infinity,
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 32,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isShort ? 12 : 14,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isShort) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_formatFileSize(fileSize)} • ${_formatDate(scanDate)} • $fileType',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isShort)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete();
                        } else if (value == 'details') {
                          onShowDetails();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: isDarkMode ? Colors.white70 : Colors.black54),
                              const SizedBox(width: 8),
                              const Text('Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
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
    );
  }
}

class _VideoGridItem extends StatelessWidget {
  final Map<String, dynamic> video;
  final bool isDarkMode;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback onShowDetails;

  const _VideoGridItem({
    required this.video,
    required this.isDarkMode,
    required this.onPlay,
    required this.onDelete,
    required this.onShowDetails,
  });

  String _formatFileSize(int sizeInBytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = sizeInBytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  String _formatDate(String isoDate) {
    try {
      return DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = video['file_name'] as String;
    final fileSize = video['file_size'] as int;
    final scanDate = video['scan_date'] as String;
    final fileType = video['file_type'] as String;
    const movieThreshold = 50 * 1024 * 1024;
    const shortThreshold = 10 * 1024 * 1024;

    final (category, categoryColor) = switch (fileSize) {
      > movieThreshold => ('MOVIE', Colors.red),
      < shortThreshold => ('SHORT', Colors.blue),
      _ => ('VIDEO', Colors.green),
    };

    final isShort = fileSize < shortThreshold;

    return GestureDetector(
      onTap: onPlay,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Container(
                    height: isShort ? 190 : 350,
                    width: double.infinity,
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 32,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isShort ? 12 : 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatFileSize(fileSize)} • ${_formatDate(scanDate)}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortsRow extends StatelessWidget {
  final List<Map<String, dynamic>> shorts;
  final bool isDarkMode;
  final Function(Map<String, dynamic>) onPlay;
  final Function(int) onDelete;
  final Function(Map<String, dynamic>) onShowDetails;

  const _ShortsRow({
    required this.shorts,
    required this.isDarkMode,
    required this.onPlay,
    required this.onDelete,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final selectedShorts = (List<Map<String, dynamic>>.from(shorts)..shuffle(random)).take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8, right: 12, top: 8),
          child: Text(
            'Shorts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: selectedShorts.length,
            itemBuilder: (context, index) => SizedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _VideoListItem(
                  video: selectedShorts[index],
                  isDarkMode: isDarkMode,
                  isShort: true,
                  onPlay: () => onPlay(selectedShorts[index]),
                  onDelete: () => onDelete(selectedShorts[index]['id'] as int),
                  onShowDetails: () => onShowDetails(selectedShorts[index]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SortBottomSheet extends StatelessWidget {
  final SortType currentSortType;
  final SortDirection currentSortDirection;
  final Function(SortType, SortDirection) onSortChanged;

  const _SortBottomSheet({
    required this.currentSortType,
    required this.currentSortDirection,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          height: 4,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Sort Videos By',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _SortOption(
          title: 'Name',
          icon: Icons.sort_by_alpha,
          sortType: SortType.name,
          isSelected: currentSortType == SortType.name,
          direction: currentSortDirection,
          onTap: () => onSortChanged(SortType.name, currentSortDirection),
        ),
        _SortOption(
          title: 'Date Added',
          icon: Icons.calendar_today,
          sortType: SortType.date,
          isSelected: currentSortType == SortType.date,
          direction: currentSortDirection,
          onTap: () => onSortChanged(SortType.date, currentSortDirection),
        ),
        _SortOption(
          title: 'File Size',
          icon: Icons.data_usage,
          sortType: SortType.size,
          isSelected: currentSortType == SortType.size,
          direction: currentSortDirection,
          onTap: () => onSortChanged(SortType.size, currentSortDirection),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Sort Direction:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              ToggleButtons(
                borderRadius: BorderRadius.circular(8),
                selectedBorderColor: Theme.of(context).primaryColor,
                selectedColor: Colors.white,
                fillColor: Theme.of(context).primaryColor,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward),
                        SizedBox(width: 4),
                        Text('Asc'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward),
                        SizedBox(width: 4),
                        Text('Desc'),
                      ],
                    ),
                  ),
                ],
                isSelected: [
                  currentSortDirection == SortDirection.ascending,
                  currentSortDirection == SortDirection.descending,
                ],
                onPressed: (index) {
                  Navigator.pop(context);
                  onSortChanged(
                    currentSortType,
                    index == 0 ? SortDirection.ascending : SortDirection.descending,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SortOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final SortType sortType;
  final bool isSelected;
  final SortDirection direction;
  final VoidCallback onTap;

  const _SortOption({
    required this.title,
    required this.icon,
    required this.sortType,
    required this.isSelected,
    required this.direction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      trailing: isSelected
          ? Icon(
        direction == SortDirection.ascending
            ? Icons.arrow_upward
            : Icons.arrow_downward,
        color: Theme.of(context).primaryColor,
      )
          : null,
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1048576).toStringAsFixed(1)} MB';
}