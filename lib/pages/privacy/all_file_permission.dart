import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'dart:ui';

class FilePermissionsScreen extends StatefulWidget {
  const FilePermissionsScreen({super.key});

  @override
  State<FilePermissionsScreen> createState() => _FilePermissionsScreenState();
}

class _FilePermissionsScreenState extends State<FilePermissionsScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;
  late AnimationController _animationController;
  late List<GlobalKey> _sectionKeys;
  int _expandedSectionIndex = -1;

  final List<Map<String, String>> _sections = [
    {
      'title': '1. MANAGE_EXTERNAL_STORAGE',
      'content': '**Technical Purpose**\n'
          'This high-level permission provides complete access to all files in external storage, bypassing the scoped storage restrictions introduced in Android 10 (API level 29) and above. It allows the app to:\n\n'
          '- Access the full file system hierarchy\n'
          '- Read from normally inaccessible directories\n'
          '- Find residual file data in system folders\n'
          '- Locate file fragments in various storage locations\n\n'
          '**Why It\'s Essential**\n'
          'For effective file recovery, we need to scan deeper than what standard APIs allow. Standard storage permissions only provide access to media files through MediaStore or user-selected directories through Storage Access Framework (SAF). However, deleted files or file fragments often reside in locations that these APIs cannot reach.\n\n'
          '**User Benefit**\n'
          'This permission enables our app to perform comprehensive scans that can recover files that other apps (with more limited permissions) simply cannot find.',
    },
    {
      'title': '2. READ_EXTERNAL_STORAGE',
      'content': '**Technical Purpose**\n'
          'This permission grants read access to the external storage directories. On Android 12 (API level 31) and below, it enables:\n\n'
          '- Reading files from public directories\n'
          '- Accessing media files through MediaStore API\n'
          '- Scanning accessible directories for file signatures\n'
          '- Reading file metadata from storage volumes\n\n'
          '**Why It\'s Essential**\n'
          'While more limited than MANAGE_EXTERNAL_STORAGE, this permission is still crucial for basic file scanning capabilities. It allows us to detect recoverable files in public directories and read their contents for recovery. For devices running Android 9 (Pie) or earlier, this is the primary permission needed for file access.\n\n'
          '**User Benefit**\n'
          'This permission enables the core functionality of scanning for and displaying recoverable files that exist in standard storage locations.',
    },
    {
      'title': '3. WRITE_EXTERNAL_STORAGE',
      'content': '**Technical Purpose**\n'
          'This permission enables write access to external storage directories. Specifically, it allows the app to:\n\n'
          '- Create directories to save recovered files\n'
          '- Write recovered file data to user-selected locations\n'
          '- Create temporary cache files during the recovery process\n'
          '- Modify file attributes when necessary\n\n'
          '**Why It\'s Essential**\n'
          'After identifying and recovering files, we need the ability to save them somewhere accessible to the user. Without write permission, we could scan for and identify recoverable files, but would be unable to actually save them to your device.\n\n'
          '**User Benefit**\n'
          'This permission enables the critical final step of the recovery process - saving your recovered files in a location where you can access and use them.',
    },
    {
      'title': '4. ACCESS_MEDIA_LOCATION',
      'content': '**Technical Purpose**\n'
          'Introduced in Android 10 (API level 29), this permission allows access to the original location metadata in media files such as photos. It enables:\n\n'
          '- Reading the EXIF location data from images\n'
          '- Accessing precise geolocation information in media files\n'
          '- Preserving location metadata during file recovery\n'
          '- Organizing recovered media by original capture location\n\n'
          '**Why It\'s Essential**\n'
          'When recovering media files, particularly photos, preserving metadata is crucial. Without this permission, location data would be stripped from recovered media files, resulting in incomplete recovery. For users who value the geographic context of their photos, this loss would be significant.\n\n'
          '**User Benefit**\n'
          'This permission ensures that recovered photos maintain their original location data, preserving the complete context and value of your memories.',
    },
    {
      'title': '5. FOREGROUND_SERVICE',
      'content': '**Technical Purpose**\n'
          'This permission allows the app to run a foreground service, which is a type of service that performs operations that are noticeable to the user. With this permission, the app can:\n\n'
          '- Continue scanning operations even when the app is not in focus\n'
          '- Maintain scan progress when the screen is turned off\n'
          '- Display a persistent notification showing scan status\n'
          '- Prevent the system from killing the recovery process\n\n'
          '**Why It\'s Essential**\n'
          'File scanning and recovery can be time-intensive processes that require uninterrupted operation. Without a foreground service, the system might terminate the process when the app is backgrounded or the device enters a low-power state, resulting in incomplete scans or lost recovery data.\n\n'
          '**User Benefit**\n'
          'This permission allows thorough scans to complete even if you switch to another app or turn off your screen, ensuring the most comprehensive recovery results.',
    },
    {
      'title': '6. Permission Best Practices',
      'content': '**Granting Permissions**\n'
          'For the best recovery results, we recommend granting all requested permissions. However, we\'ve designed the app to work with minimal permissions if you prefer. Here\'s what you should know:\n\n'
          '- Permissions are requested only when needed\n'
          '- Each permission serves a specific recovery function\n'
          '- Limited permissions will result in limited recovery capabilities\n'
          '- All permissions are used solely for file recovery purposes\n\n'
          '**Managing Permissions**\n'
          'You can manage permissions at any time through:\n\n'
          '- Your device\'s Settings > Apps > Old File Scan Recovery > Permissions\n'
          '- The app\'s Settings > Permissions section\n'
          '- System permission dialogs when specific features are used\n\n'
          '**Our Commitment**\n'
          'We request only the permissions necessary for effective file recovery. We do not use permissions for any purpose other than their stated recovery function.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _sectionKeys = List.generate(
      _sections.length,
          (_) => GlobalKey(),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShowTitle = _scrollController.offset > 120;
    if (shouldShowTitle != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = shouldShowTitle;
      });
    }
  }

  void _toggleSection(int index) {
    setState(() {
      if (_expandedSectionIndex == index) {
        _expandedSectionIndex = -1;
      } else {
        _expandedSectionIndex = index;

        // Scroll to the expanded section with a delay to allow animation to complete
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_sectionKeys[index].currentContext != null) {
            Scrollable.ensureVisible(
              _sectionKeys[index].currentContext!,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
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
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(top: 16.h, bottom: 30.h),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(),
                SizedBox(height: 30.h),
                _buildQuickNavigation(),
                SizedBox(height: 20.h),
                ..._buildSections(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildScrollToTopFAB(),
    );
  }

  Widget _buildScrollToTopFAB() {
    return AnimatedOpacity(
      opacity: _showAppBarTitle ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: FloatingActionButton(
        mini: true,
        backgroundColor: CusColor.darkBlue3,
        onPressed: _showAppBarTitle
            ? () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
            : null,
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: AnimatedOpacity(
        opacity: _showAppBarTitle ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: const Text(
          'File Permissions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: () {
            // Show permission info dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  'About Permissions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CusColor.darkBlue3,
                  ),
                ),
                content: Text(
                  'Permissions are requested only when needed for specific recovery functions. You can always manage permissions in your device settings.',
                  style: TextStyle(fontSize: 14.sp),
                ),
                actions: [
                  TextButton(
                    child: Text(
                      'OK',
                      style: TextStyle(color: CusColor.darkBlue3),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
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

  Widget _buildPageHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File Permissions',
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Old File Scan Recovery',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Last Updated: 22 Feb 2025',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: CusColor.darkBlue3.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.folder_open,
                        color: CusColor.darkBlue3,
                        size: 18.h,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Why We Need Access',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: CusColor.darkBlue3,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  'Old File Scan Recovery requires specific permissions to effectively scan for and recover your deleted files. Each permission has a crucial purpose in the recovery process.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'We only request permissions that are essential for recovery functions. Your privacy remains our priority, and permissions are never used for data collection or sharing.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNavigation() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permission Navigator',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: CusColor.darkBlue3,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: List.generate(
              _sections.length,
                  (index) => ActionChip(
                label: Text(
                  _sections[index]['title']!.split('.')[0],
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: CusColor.darkBlue3,
                  ),
                ),
                backgroundColor: CusColor.darkBlue3.withOpacity(0.1),
                onPressed: () {
                  _toggleSection(index);
                  if (_sectionKeys[index].currentContext != null) {
                    Scrollable.ensureVisible(
                      _sectionKeys[index].currentContext!,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections() {
    return List.generate(
      _sections.length,
          (index) => Container(
        key: _sectionKeys[index],
        margin: EdgeInsets.only(bottom: 16.h, left: 20.w, right: 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSectionHeader(index),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _expandedSectionIndex == index
                  ? _buildSectionContent(index)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int index) {
    final title = _sections[index]['title']!;
    final isExpanded = _expandedSectionIndex == index;

    return InkWell(
      onTap: () => _toggleSection(index),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: CusColor.darkBlue3.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  title.split('.')[0],
                  style: TextStyle(
                    color: CusColor.darkBlue3,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: CusColor.darkBlue3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent(int index) {
    final content = _sections[index]['content']!;
    final paragraphs = content.split('\n\n');

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        bottom: 16.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs.map((paragraph) {
          if (paragraph.startsWith('**')) {
            // This is a subheading
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h, top: 8.h),
              child: Text(
                paragraph.replaceAll('**', ''),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: CusColor.darkBlue3,
                ),
              ),
            );
          } else if (paragraph.contains('- ')) {
            // This is a list
            final listItems = paragraph.split('\n');
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: listItems.map((item) {
                  if (item.startsWith('- ')) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 6.h, right: 8.w),
                            width: 6.w,
                            height: 6.w,
                            decoration: BoxDecoration(
                              color: CusColor.darkBlue3,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.replaceFirst('- ', ''),
                              style: TextStyle(
                                fontSize: 15.sp,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 15.sp,
                          height: 1.5,
                        ),
                      ),
                    );
                  }
                }).toList(),
              ),
            );
          } else {
            // Regular paragraph
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Text(
                paragraph,
                style: TextStyle(
                  fontSize: 15.sp,
                  height: 1.5,
                ),
              ),
            );
          }
        }).toList(),
      ),
    );
  }
}