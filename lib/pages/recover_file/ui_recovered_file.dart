import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:path/path.dart' as obj;
import 'package:sqflite/sqflite.dart';
import 'dart:ui';

import '../../video_player/video_player.dart';

class RecoveryDashboard extends StatefulWidget {
  const RecoveryDashboard({super.key});

  @override
  State<RecoveryDashboard> createState() => _RecoveryDashboardState();
}

class _RecoveryDashboardState extends State<RecoveryDashboard> {
  String selectedCategory = "All";
  late Database db;
  late Future<void> _dbInitialized;

  // Define colors for different file types to match home page
  final Map<String, Color> _categoryColors = {
    'image': const Color(0xFF4A80F0),
    'video': const Color(0xFFFC7F5F),
    'audio': const Color(0xFF2ECC71),
    'docs': const Color(0xFFE74C3C),
    'All': CusColor.darkBlue3,
  };

  @override
  void initState() {
    super.initState();
    _dbInitialized = _initDatabase();
  }

  Future<void> _initDatabase() async {
    db = await openDatabase(
      obj.join(await getDatabasesPath(), 'recovered_files.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE recovered_files (id INTEGER PRIMARY KEY, file_name TEXT, file_path TEXT, file_type TEXT, file_size INTEGER, recovered_at TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<List<Map<String, dynamic>>> fetchRecoveredFiles() async {
    await _dbInitialized;
    var data = await db.query('recovered_files');
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: CusColor.decentWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white)
        ),
        title: const Text(
          "Recovered Files",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Add search functionality here
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
            children: [
              SizedBox(height: 15.h),
              // Improved category selector
              SizedBox(
                height: 50.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                  children: ["All", "image", "video", "audio", "docs"].map((category) {
                    String label = category == "All" ? "All" :
                    category == "image" ? "Images" :
                    category == "video" ? "Videos" :
                    category == "audio" ? "Audio" : "Documents";
                    bool isSelected = selectedCategory == category;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 10.w),
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _categoryColors[category]
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: _categoryColors[category]!.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 15.h),

              // Stats cards
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchRecoveredFiles(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(height: 80.h);
                    }

                    List<Map<String, dynamic>> files = snapshot.data ?? [];
                    int totalFiles = files.length;
                    double totalSizeMB = files.fold(0.0, (sum, file) =>
                    sum + ((file['file_size'] ?? 0) / 1048576));

                    List<Map<String, dynamic>> filteredFiles =
                    selectedCategory == "All" ? files :
                    files.where((file) => file['file_type'] == selectedCategory).toList();

                    return Container(
                      height: 80.h,
                      padding: EdgeInsets.all(15.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.folder,
                            value: selectedCategory == "All" ? totalFiles.toString() : filteredFiles.length.toString(),
                            label: "Files",
                            color: _categoryColors[selectedCategory]!,
                          ),
                          _buildDivider(),
                          _buildStatItem(
                            icon: Icons.sd_storage_rounded,
                            value: selectedCategory == "All"
                                ? "${totalSizeMB.toStringAsFixed(1)} MB"
                                : "${(filteredFiles.fold(0.0, (sum, file) => sum + ((file['file_size'] ?? 0) / 1048576))).toStringAsFixed(1)} MB",
                            label: "Size",
                            color: _categoryColors[selectedCategory]!,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 15.h),

              // Files list section
              Expanded(
                child: Container(
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
                      Padding(
                        padding: EdgeInsets.only(left: 20.w, top: 20.h, bottom: 10.h),
                        child: Text(
                          selectedCategory == "All" ? "All Recovered Files" :
                          "${selectedCategory == 'docs' ? 'Document' : selectedCategory.capitalize()} Files",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _categoryColors[selectedCategory],
                          ),
                        ),
                      ),

                      Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: fetchRecoveredFiles(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text("Error: ${snapshot.error}"),
                              );
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text("No recovered files found"),
                              );
                            }

                            List<Map<String, dynamic>> filteredFiles = snapshot.data!;
                            if (selectedCategory != "All") {
                              filteredFiles = filteredFiles
                                  .where((file) => file['file_type'] == selectedCategory)
                                  .toList();
                            }

                            if (filteredFiles.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        getFileIcon(selectedCategory),
                                        size: 60,
                                        color: Colors.grey.withOpacity(0.5)
                                    ),
                                    SizedBox(height: 15.h),
                                    Text(
                                      "No ${selectedCategory == 'All' ? 'recovered' : selectedCategory.toLowerCase()} files found",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 15.w),
                              itemCount: filteredFiles.length,
                              itemBuilder: (context, index) {
                                var file = filteredFiles[index];
                                return fileTile(file);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _categoryColors[selectedCategory],
        onPressed: () => showBottomSheetInfo(context),
        icon: const Icon(Icons.analytics, color: Colors.white),
        label: const Text(
          "Statistics",
          style: TextStyle(color: Colors.white),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String value, required String label, required Color color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            SizedBox(width: 5.w),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30.h,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget fileTile(Map<String, dynamic> file) {
    final fileType = file['file_type'] ?? 'unknown';
    final Color typeColor = _categoryColors[fileType] ?? Colors.grey;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: typeColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: typeColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
        leading: Container(
          width: 45.w,
          height: 45.w,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            getFileIcon(fileType),
            color: typeColor,
            size: 24,
          ),
        ),
        title: Text(
          file['file_name'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          file['file_path'].replaceFirst('/storage/emulated/0/', ''),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${(file['file_size'] / 1048576).toStringAsFixed(1)} MB",
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              _formatDate(file['recovered_at'] ?? ''),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        onTap: () {
          // Handle file tap based on file type
          if (fileType == 'video') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  videoUrl: file['file_path'],
                  title: file['file_name'],
                ),
              ),
            );
          }
          // Add other file type handling if needed
        },
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "Unknown";
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  /// Get icon based on file type
  IconData getFileIcon(String fileType) {
    switch (fileType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      case 'docs':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  void showBottomSheetInfo(BuildContext context) async {
    // Ensure database is initialized
    await _dbInitialized;
    List<Map<String, dynamic>> files = await fetchRecoveredFiles();

    int totalFiles = files.length;
    double totalSizeMB =
    files.fold(0.0, (sum, file) => sum + (file['file_size'] ?? 0) / 1048576);

    Map<String, int> categoryCounts = {};
    Map<String, double> categorySizes = {};

    for (var file in files) {
      String fileType = file['file_type'] ?? 'unknown';
      categoryCounts[fileType] = (categoryCounts[fileType] ?? 0) + 1;
      categorySizes[fileType] = (categorySizes[fileType] ?? 0) + ((file['file_size'] ?? 0) / 1048576);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 25.h),
          height: 350.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              topRight: Radius.circular(30.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: CusColor.darkBlue3.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: CusColor.darkBlue3,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  const Text(
                    "File Recovery Summary",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.folder_outlined,
                      title: "Total Files",
                      value: "$totalFiles",
                      color: CusColor.darkBlue3,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.sd_storage_outlined,
                      title: "Total Size",
                      value: "${totalSizeMB.toStringAsFixed(2)} MB",
                      color: CusColor.darkBlue3,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
              const Text(
                "File Type Distribution",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15.h),

              // Category breakdown
              categoryCounts.isEmpty
                  ? const Text("No files categorized")
                  : Expanded(
                child: ListView(
                  children: categoryCounts.keys.map((type) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 15.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: _categoryColors[type]?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              getFileIcon(type),
                              color: _categoryColors[type] ?? Colors.grey,
                            ),
                          ),
                          SizedBox(width: 15.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type == 'image' ? 'Images' :
                                type == 'video' ? 'Videos' :
                                type == 'audio' ? 'Audio' :
                                type == 'docs' ? 'Documents' : type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${categoryCounts[type]} files · ${categorySizes[type]?.toStringAsFixed(2)} MB",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            "${((categoryCounts[type]! / totalFiles) * 100).toStringAsFixed(0)}%",
                            style: TextStyle(
                              color: _categoryColors[type] ?? Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 10.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}