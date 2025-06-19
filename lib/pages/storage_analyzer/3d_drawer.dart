import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/drawer_header.dart';
import 'dart:math';
import 'dart:ui';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:old_file_recovery/pages/database/valut_access.dart';
import 'package:old_file_recovery/pages/home_page.dart';
import 'package:old_file_recovery/pages/playlists/playlists.dart';
import 'package:old_file_recovery/pages/recover_file/ui_recovered_file.dart';
import 'package:old_file_recovery/permission/permission.dart';
import '../recover_file/size_map_recovered_file.dart';
import '../ui/ui_component.dart';
import 'detail_storage.dart';

class HomePageOriginal extends StatefulWidget {
  const HomePageOriginal({super.key});
  @override
  State<HomePageOriginal> createState() => _HomePageOriginalState();
}

class _HomePageOriginalState extends State<HomePageOriginal> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late PageController _pageController;
  int _currentPage = 0;
  double maxSlide = 0;

  final List<FeatureOption> _featureOptions = [
    FeatureOption(
      title: "Scan Old Files",
      description: "Find lost files and recover them easily",
      icon: Icons.find_in_page,
      buttonText: 'Start Scanning',
      buttonIcon: Icons.search_outlined,
      color: const Color(0xFF4A80F0),
      destination: const HomePage(),
    ),
    FeatureOption(
      title: "Secure Your File",
      description: "Protect files with Vault's encryption",
      icon: Icons.lock,
      buttonText: 'Start Securing',
      buttonIcon: Icons.lock,
      color: const Color(0xFFFC7F5F),
      destination: const VaultAccessScreen(),
    ),
    FeatureOption(
      title: "Storage Analyzer",
      description: "Scan and analyze storage space",
      icon: Icons.pie_chart_outline,
      buttonText: 'Analyze Now',
      buttonIcon: Icons.storage_outlined,
      color: const Color(0xFF2ECC71),
      destination: const StorageAnalysisScreen(),
    ),
    FeatureOption(
      title: "Storage Analyzer",
      description: "Scan and analyze storage space",
      icon: Icons.pie_chart_outline,
      buttonText: 'Analyze Now',
      buttonIcon: Icons.storage_outlined,
      color: const Color(0xFF2ECC71),
      destination: const VideoListScreen(),
    ),

  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pageController = PageController(viewportFraction: 0.9);
    StoragePermissionHelper.requestStoragePermission();
  }

  void toggleDrawer() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    maxSlide = MediaQuery.of(context).size.width * 0.65;

    return Scaffold(
      backgroundColor: CusColor.darkBlue3,
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          double delta = details.primaryDelta! / maxSlide;
          _animationController.value += delta;
        },
        onHorizontalDragEnd: (details) {
          if (_animationController.value > 0.5) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        },
        child: Stack(
          children: [
            // Drawer content
            Container(
              width: maxSlide,
              color: CusColor.darkBlue3,
              child: const AppDrawer(),
            ),

            // Main content with animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                double slide = maxSlide * _animationController.value;
                double scale = 1 - (_animationController.value * 0.2);
                double rotateY = (_animationController.value * -10) * (pi / 180);

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspective effect
                    ..translate(slide)
                    ..rotateY(rotateY)
                    ..scale(scale),
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_animationController.value * 25),
                    child: Scaffold(
                      extendBodyBehindAppBar: true,
                      backgroundColor: CusColor.decentWhite,
                      appBar: AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        title: const Text(
                          "Old File Scan",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: toggleDrawer,
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                            onPressed: () {

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
                              CusColor.decentWhite.withOpacity(0.9),
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 20.w, top: 10.h, bottom: 5.h),
                                  child: const Text(
                                    'What would you like to do?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 240.h,
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: _featureOptions.length,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentPage = index;
                                      });
                                    },
                                    itemBuilder: (context, index) {
                                      final option = _featureOptions[index];
                                      final isActive = index == _currentPage;

                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: isActive ? 10.h : 25.h,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: option.color.withOpacity(0.3),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
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
                                            Icon(
                                              option.icon,
                                              size: 64,
                                              color: Colors.white,
                                            ),
                                            SizedBox(height: 12.h),
                                            Text(
                                              option.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 8.h),
                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                                              child: Text(
                                                option.description,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.8),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 16.h),
                                            _buildActionButton(context, option),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _featureOptions.length,
                                          (index) => buildIndicator(index == _currentPage, _featureOptions[index].color),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                _buildQuickAccessGrid(),
                                SizedBox(height: 20.h),
                                _buildRecoveryHistory(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIndicator(bool isActive, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, FeatureOption option) {
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
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(option.buttonIcon, size: 16),
          SizedBox(width: 8.w),
          Text(
            option.buttonText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              _featureOptions.length,
                  (index) => _buildQuickAccessItem(
                icon: _featureOptions[index].icon,
                color: _featureOptions[index].color,
                label: _featureOptions[index].title.split(' ')[0],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => _featureOptions[index].destination),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryHistory() {
    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, int>>(
        future: FileRecoveryService().getTotalSizeByCategory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: SizedBox(
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A80F0)),
                    ),
                    SizedBox(height: 10.h),
                    const Text(
                      "Loading recovery data...",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recovery History",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RecoveryDashboard()),
                      );
                    },
                    child: const Text(
                      "View All",
                      style: TextStyle(
                        color: Color(0xFF4A80F0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              _buildHistoryItem(
                "Recovered Images",
                formatFileSize(data['image'] ?? 0),
                Icons.image,
                const Color(0xFF4A80F0),
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecoveryDashboard()),
                  );
                },
              ),
              SizedBox(height: 10.h),
              _buildHistoryItem(
                "Recovered Videos",
                formatFileSize(data['video'] ?? 0),
                Icons.ondemand_video_rounded,
                const Color(0xFFFC7F5F),
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecoveryDashboard()),
                  );
                },
              ),
              SizedBox(height: 10.h),
              _buildHistoryItem(
                "Recovered Documents",
                formatFileSize(data['docs'] ?? 0),
                Icons.picture_as_pdf,
                const Color(0xFF2ECC71),
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecoveryDashboard()),
                  );
                },
              ),
              SizedBox(height: 10.h),
              _buildHistoryItem(
                "Recovered Audio",
                formatFileSize(data['audio'] ?? 0),
                Icons.music_note,
                const Color(0xFFE74C3C),
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecoveryDashboard()),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(
      String title,
      String size,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 15.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    size,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

class FeatureOption {
  final String title;
  final String description;
  final IconData icon;
  final String buttonText;
  final IconData buttonIcon;
  final Color color;
  final Widget destination;

  const FeatureOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.buttonText,
    required this.buttonIcon,
    required this.color,
    required this.destination,
  });
}