import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:old_file_recovery/pages/vault/ui_vault.dart';

import 'move_file_to_vault/vault_database.dart';

class VaultCategory extends StatefulWidget {
  const VaultCategory({super.key});

  @override
  State<VaultCategory> createState() => _VaultCategoryState();
}

class _VaultCategoryState extends State<VaultCategory> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<CategoryItem> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Load data from database
    _loadCategoriesFromDatabase().then((_) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    });
  }

  Future<void> _loadCategoriesFromDatabase() async {
    final DatabaseHelperVault dbHelper = DatabaseHelperVault();
    final int videoCount = await dbHelper.getFileCountByType('video');
    final int audioCount = await dbHelper.getFileCountByType('audio');
    final int documentCount = await dbHelper.getFileCountByType('docs');
    final int imageCount = await dbHelper.getFileCountByType('image');

    setState(() {
      _categories = [
        CategoryItem(
          title: "Video",
          fileType: "video",
          icon: Icons.video_library_rounded,
          color: const Color(0xFF5E72E4),
          description: "Access your secured videos",
          count: videoCount,
        ),
        CategoryItem(
          title: "Audio",
          fileType: "audio",
          icon: Icons.audiotrack_rounded,
          color: const Color(0xFFFF9D54),
          description: "Browse your audio files",
          count: audioCount,
        ),
        CategoryItem(
          title: "Documents",
          fileType: "docs", // Changed from 'docs' to match database type
          icon: Icons.description_rounded,
          color: const Color(0xFF11CDEF),
          description: "View important documents",
          count: documentCount,
        ),
        CategoryItem(
          title: "Images",
          fileType: "image",
          icon: Icons.photo_rounded,
          color: const Color(0xFFF5365C),
          description: "Browse secured photos",
          count: imageCount,
        ),
      ];
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Secure Vault",
          style: TextStyle(
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
                // Show search or filter action
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search functionality coming soon'))
                );
              },
              icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
              tooltip: 'Search',
              splashRadius: 24,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              color: CusColor.darkBlue3,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero section
                Padding(
                  padding: const EdgeInsets.all(24.0),
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
                          child: const Row(
                            children: [
                              Icon(Icons.lock, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Your files are protected",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
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
                          child: const Text(
                            "Categories",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
                            ),
                          ),
                          child: const Text(
                            "Select a category to browse your secured files",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category grid
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(top: 10, bottom: 30),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      itemBuilder: (context, index) {
                        // Staggered animation for grid items
                        return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final delay = index * 0.1;
                            final start = 0.4 + delay;
                            final end = 0.7 + delay;

                            final slideAnimation = Tween<Offset>(
                              begin: const Offset(0, 0.5),
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
                          child: _buildCategoryCard(
                            _categories[index],
                            onTap: () => _navigateToVaultPage(_categories[index].fileType),
                          ),
                        );
                      },
                      itemCount: _categories.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryItem category, {required VoidCallback onTap}) {
    return Hero(
      tag: 'category_${category.fileType}',
      child: Material(
        color: Colors.transparent,
        child: Card(
          elevation: 6,
          shadowColor: category.color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: category.color.withOpacity(0.1),
            highlightColor: category.color.withOpacity(0.05),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    category.color.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      category.icon,
                      size: 28,
                      color: category.color,
                    ),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    category.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 4.h),

                  Text(
                    category.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                 SizedBox(height: 10.h),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${category.count} files",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: category.color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: category.color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToVaultPage(String fileType) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            VaultPage(fileType: fileType),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}

class CategoryItem {
  final String title;
  final String fileType;
  final IconData icon;
  final Color color;
  final String description;
  final int count;

  CategoryItem({
    required this.title,
    required this.fileType,
    required this.icon,
    required this.color,
    required this.description,
    required this.count,
  });
}
