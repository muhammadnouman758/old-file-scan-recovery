import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/audio/audio_result.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:old_file_recovery/pages/documents/results_documents.dart';
import 'package:old_file_recovery/pages/video/result_video.dart';
import 'images/file_recovery_ui.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController(viewportFraction: 0.9);

  // Recovery option data
  final List<RecoveryOption> _recoveryOptions = [
    const RecoveryOption(
      title: 'Image Recovery',
      subtitle: 'Find lost images and recover them easily',
      icon: Icons.photo_size_select_actual_outlined,
      color: Color(0xFF4A80F0),
      destination: FolderGridApp(),
    ),
    const RecoveryOption(
      title: 'Video Recovery',
      subtitle: 'Find lost videos and recover them easily',
      icon: Icons.ondemand_video_rounded,
      color: Color(0xFFFC7F5F),
      destination: VideoFolderGridApp(),
    ),
    const RecoveryOption(
      title: 'Audio Recovery',
      subtitle: 'Find lost audio files and recover them easily',
      icon: Icons.audiotrack,
      color: Color(0xFF2ECC71),
      destination: AudioFolderGridApp(),
    ),
    const RecoveryOption(
      title: 'Document Recovery',
      subtitle: 'Find lost documents and recover them easily',
      icon: Icons.document_scanner,
      color: Color(0xFFE74C3C),
      destination: DocumentFolderGridApp(),
    ),
  ];

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _recoveryOptions.length, vsync: this);
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    setState(() {
      _currentPage = _pageController.page!.round();
    });
    _tabController.animateTo(_currentPage);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'File Recovery',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Show settings page
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CusColor.darkBlue3,
              CusColor.decentWhite,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20.w, top: 15.h, bottom: 5.h),
                child: const Text(
                  'What would you like to recover?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ),
              SizedBox(height: 5.h),
              // Reduced height from 400.h to 300.h
              SizedBox(
                height: 300.h,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _recoveryOptions.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    _tabController.animateTo(index);
                  },
                  itemBuilder: (context, index) {
                    final option = _recoveryOptions[index];
                    final isActive = index == _currentPage;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: isActive ? 0 : 15.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: option.color.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            option.color.withOpacity(0.9),
                            option.color,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Reduced icon size from 90 to 70
                          Icon(
                            option.icon,
                            size: 70,
                            color: Colors.white,
                          ),
                          SizedBox(height: 15.h),
                          Text(
                            option.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Text(
                              option.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          _buildStartScanButton(context, option),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10.h),
              Center(
                child: TabPageSelector(
                  controller: _tabController,
                  selectedColor: _recoveryOptions[_currentPage].color,
                  indicatorSize: 8,
                ),
              ),
              SizedBox(height: 15.h),
              Expanded(
                child: _buildRecoveryGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartScanButton(BuildContext context, RecoveryOption option) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => option.destination)
        );
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: option.color,
        backgroundColor: Colors.white,
        // Reduced padding for a more compact button
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, size: 18),
          SizedBox(width: 8.w),
          const Text(
            'Start Scanning',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Replaced the Quick Access section with a more compact grid layout
  Widget _buildRecoveryGrid() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Recovery Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15.h),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _recoveryOptions.length,
              itemBuilder: (context, index) {
                final option = _recoveryOptions[index];
                return _buildRecoveryGridItem(option);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryGridItem(RecoveryOption option) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => option.destination),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: option.color.withOpacity(0.1),
          border: Border.all(
            color: option.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(12.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              option.icon,
              size: 32,
              color: option.color,
            ),
            SizedBox(height: 8.h),
            Text(
              option.title.split(' ')[0],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: option.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecoveryOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget destination;

  const RecoveryOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.destination,
  });
}