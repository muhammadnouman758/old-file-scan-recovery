import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:old_file_recovery/first/shimmer/shimmer.dart';
import 'package:old_file_recovery/pages/color_lib.dart';

import '../history/scan_records.dart';
import 'documents.dart';
import 'fetch_documents.dart';

class DocumentFolderGridApp extends StatefulWidget {
  const DocumentFolderGridApp({super.key});

  @override
  State<DocumentFolderGridApp> createState() => _DocumentFolderGridAppState();
}

class _DocumentFolderGridAppState extends State<DocumentFolderGridApp> with TickerProviderStateMixin {
  final DocumentFileFetcher _fileFetcher = DocumentFileFetcher();
  late Stream<Map<String, Set<File>>> _folderStream;
  late Stream<double> _progressStream;
  late Stream<String> _currentPathStream;

  // Animation controllers
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _textAnimationController;

  // UI states
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  Map<String, Set<File>> _allFolders = {};

  // Sorting
  String _sortCriteria = "name"; // Default sort by name
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _folderStream = _fileFetcher.folderStream;
    _progressStream = _fileFetcher.progressStream;
    _currentPathStream = _fileFetcher.currentPathStream;

    _startFetchingDocuments();

    // Progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    // Text fade animation
    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Search listener
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  void _startFetchingDocuments() {
    _progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _progressAnimation = Tween<double>(
            begin: _progressAnimation.value,
            end: progress / 100,
          ).animate(
            CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
          );
          _progressController.forward(from: 0.0);
        });
      }
    });

    _currentPathStream.listen((path) {
      // No-op
    });

    _fileFetcher.fetchDocumentFiles();
  }

  @override
  void dispose() {
    _fileFetcher.dispose();
    _progressController.dispose();
    _textAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = "";
      }
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  void _changeSortCriteria(String criteria) {
    setState(() {
      if (_sortCriteria == criteria) {
        _sortAscending = !_sortAscending;
      } else {
        _sortCriteria = criteria;
        _sortAscending = true;
      }
    });
  }

  List<String> _getSortedFolderKeys(Map<String, Set<File>> folders) {
    List<String> keys = folders.keys.toList();

    switch (_sortCriteria) {
      case "name":
        keys.sort((a, b) {
          final nameA = a.split('/').last.toLowerCase();
          final nameB = b.split('/').last.toLowerCase();
          return _sortAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
        });
        break;
      case "count":
        keys.sort((a, b) {
          final countA = folders[a]!.length;
          final countB = folders[b]!.length;
          return _sortAscending ? countA.compareTo(countB) : countB.compareTo(countA);
        });
        break;
      case "date":
        keys.sort((a, b) {
          final dateA = folders[a]!.isNotEmpty
              ? folders[a]!.first.statSync().modified
              : DateTime(1970);
          final dateB = folders[b]!.isNotEmpty
              ? folders[b]!.first.statSync().modified
              : DateTime(1970);
          return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        });
        break;
    }

    return keys;
  }

  List<String> _getFilteredFolderKeys(Map<String, Set<File>> folders) {
    if (_searchQuery.isEmpty) {
      return _getSortedFolderKeys(folders);
    }

    final searchLower = _searchQuery.toLowerCase();
    return _getSortedFolderKeys(folders)
        .where((key) => key.split('/').last.toLowerCase().contains(searchLower))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CusColor.decentWhite,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            if (_isSearching) _buildSearchBar(),
            // _buildSortFilterBar(),
            Expanded(
              child: StreamBuilder<Map<String, Set<File>>>(
                stream: _folderStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingView();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorView();
                  }

                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    _allFolders = snapshot.data!;
                    streamListenerTo(_allFolders, 'docs');

                    final filteredKeys = _getFilteredFolderKeys(_allFolders);

                    if (filteredKeys.isEmpty) {
                      return _buildNoResultsView();
                    }

                    return _buildFoldersGridView(filteredKeys);
                  }

                  return _buildEmptyView();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildRefreshButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: _isSearching
          ? const Text('Search Folders', style: TextStyle(color: Colors.white))
          : const Text('Document Folders', style: TextStyle(color: Colors.white)),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
          onPressed: _toggleSearchMode,
        ),
        IconButton(
          icon: const Icon(Icons.sort, color: Colors.white),
          onPressed: () => _showSortOptions(context),
        ),
      ],
      backgroundColor: CusColor.darkBlue3,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search folders...',
          prefixIcon: Icon(Icons.search, color: CusColor.darkBlue3),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: CusColor.darkBlue3),
            onPressed: () {
              _searchController.clear();
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      ),
    );
  }
  Widget _buildLoadingView() {
    return const VideoScanningAnimation();
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80.w,
            color: Colors.red.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            "Failed to fetch document files",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: CusColor.darkBlue3,
            ),
          ),
          SizedBox(height: 8.h),
          ElevatedButton.icon(
            onPressed: () {
              _fileFetcher.fetchDocumentFiles();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Try Again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: CusColor.darkBlue3,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 16.h),
          Text(
            "No folders match your search",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: CusColor.darkBlue3,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Try using different keywords",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 16.h),
          Text(
            "No document folders found",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: CusColor.darkBlue3,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "We couldn't find any documents on your device",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersGridView(List<String> folderKeys) {
    return AnimationLimiter(
      child: MasonryGridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16.w),
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        itemCount: folderKeys.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildFolderCard(folderKeys[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFolderCard(String folderPath) {
    final folderName = folderPath.split('/').last;
    final files = _allFolders[folderPath]!;
    final itemCount = files.length;

    final totalSize = files.fold<double>(
        0,
            (sum, file) => sum + (file.existsSync() ? file.lengthSync() / (1024 * 1024) : 0)
    );

    // Calculate the elevation based on the number of files
    final elevation = (itemCount / 10).clamp(1.0, 5.0);

    // Choose a gradient color based on the number of files
    final Color startColor = CusColor.darkBlue3;
    final Color endColor = itemCount > 10
        ? Colors.indigo.shade800
        : (itemCount > 5 ? Colors.indigo.shade700 : Colors.indigo.shade600);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentFolderPage(
              folderName: folderName,
              documentFiles: files,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [startColor, endColor],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: startColor.withOpacity(0.3),
              blurRadius: elevation * 2,
              offset: Offset(0, elevation),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 70.w,
                    height: 70.w,
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.folder,
                            size: 70.w,
                            color: Colors.amber.shade400,
                          ),
                        ),
                        if (itemCount > 0)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 5.h),
                              child: Text(
                                itemCount > 99 ? "99+" : itemCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    folderName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$itemCount files",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                      ),
                      Text(
                        "${totalSize.toStringAsFixed(1)} MB",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
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

  Widget? _buildRefreshButton() {
    return FloatingActionButton(
      onPressed: () {
        _fileFetcher.fetchDocumentFiles();
      },
      backgroundColor: CusColor.darkBlue3,
      child: const Icon(Icons.refresh, color: Colors.white),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    "Sort By",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: CusColor.darkBlue3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.sort_by_alpha,
                  color: _sortCriteria == "name" ? CusColor.darkBlue3 : Colors.grey,
                ),
                title: const Text("Folder Name"),
                trailing: _sortCriteria == "name"
                    ? Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: CusColor.darkBlue3,
                )
                    : null,
                selected: _sortCriteria == "name",
                selectedTileColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  _changeSortCriteria("name");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.numbers,
                  color: _sortCriteria == "count" ? CusColor.darkBlue3 : Colors.grey,
                ),
                title: const Text("File Count"),
                trailing: _sortCriteria == "count"
                    ? Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: CusColor.darkBlue3,
                )
                    : null,
                selected: _sortCriteria == "count",
                selectedTileColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  _changeSortCriteria("count");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.date_range,
                  color: _sortCriteria == "date" ? CusColor.darkBlue3 : Colors.grey,
                ),
                title: const Text("Date Modified"),
                trailing: _sortCriteria == "date"
                    ? Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: CusColor.darkBlue3,
                )
                    : null,
                selected: _sortCriteria == "date",
                selectedTileColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  _changeSortCriteria("date");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void streamListenerTo(Map<String, Set<File>> folder, String keyName) async {
    final fileData = [{
      keyName: folder.values.expand((set) => set).toList(),
    }];
    final object = ScanHistoryTransform();
    ScanHistoryTransform.storeFiles(fileData);
  }
}