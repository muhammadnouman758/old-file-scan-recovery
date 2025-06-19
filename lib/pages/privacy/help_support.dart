import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'dart:ui';

import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;
  late AnimationController _animationController;
  late List<GlobalKey> _sectionKeys;
  int _expandedSectionIndex = -1;

  final List<Map<String, String>> _sections = [
    {
      'title': '1. Frequently Asked Questions',
      'content': '**a. How does file recovery work?**\n'
          'Our app scans your device\'s storage for deleted files that haven\'t been completely overwritten. The recovery process is entirely local and works by analyzing residual data that remains after deletion.\n\n'
          '**b. Can all deleted files be recovered?**\n'
          'Recovery success depends on several factors:\n\n'
          '- How long ago the file was deleted.\n'
          '- Whether the storage space has been overwritten with new data.\n'
          '- The file system and storage type of your device.\n\n'
          'Generally, recently deleted files have a higher chance of recovery.\n\n'
          '**c. Why does the app need storage permissions?**\n'
          'Storage permissions are essential for scanning your device to locate and recover deleted files. Without these permissions, we cannot access the areas where deleted file data may still exist.\n\n'
          '**d. Is my data safe?**\n'
          'Absolutely. Our app operates entirely offline, and we don\'t collect, store, or share any of your personal data or recovered files. All operations happen locally on your device.',
    },
    {
      'title': '2. Troubleshooting',
      'content': '**a. App crashes during scanning**\n'
          'If the app crashes during scanning, try these steps:\n\n'
          '- Restart your device to clear memory.\n'
          '- Close other applications running in the background.\n'
          '- Make sure your device has enough free storage space.\n'
          '- Update the app to the latest version.\n'
          '- Check if your device has any battery optimization settings that might be affecting the app\'s performance.\n\n'
          '**b. Can\'t find recovered files**\n'
          'If you can\'t locate your recovered files:\n\n'
          '- Check the destination folder specified during the recovery process.\n'
          '- Make sure you have the necessary permissions to access the folder.\n'
          '- Try searching by file type instead of specific file names.\n'
          '- Verify that the recovery process completed successfully without errors.\n\n'
          '**c. Low recovery success rate**\n'
          'Low recovery rates may occur due to:\n\n'
          '- Files being deleted long ago.\n'
          '- Storage space being overwritten with new data.\n'
          '- File system limitations on your device.\n'
          '- Files being securely deleted with specialized tools.\n\n'
          '**d. Permission issues**\n'
          'If experiencing permission problems:\n\n'
          '- Check your device settings to ensure the app has necessary storage permissions.\n'
          '- For Android 11+ devices, grant "All Files Access" permission in system settings.\n'
          '- Restart the app after granting permissions.',
    },
    {
      'title': '3. Using the App',
      'content': '**a. Starting a scan**\n'
          'To begin recovering files:\n\n'
          '- Launch the app and select the type of files you want to recover (images, videos, documents, etc.).\n'
          '- Tap "Start Scan" and wait for the process to complete.\n'
          '- Preview and select the files you want to recover.\n'
          '- Choose a destination folder and tap "Recover".\n\n'
          '**b. Optimizing scan results**\n'
          'For better results:\n\n'
          '- Be specific about file types to reduce scan time.\n'
          '- Stop using your device immediately after file deletion to prevent data overwriting.\n'
          '- Keep your device charged or plugged in during scanning.\n'
          '- Use advanced filters to narrow down results.\n\n'
    },
    {
      'title': '4. Tips for Better Recovery',
      'content': '**a. Act quickly**\n'
          'The sooner you attempt recovery after deletion, the higher the chances of success. When you realize files are missing, stop using your device immediately to prevent new data from overwriting the deleted files.\n\n'
          '**b. Avoid installing apps after deletion**\n'
          'Installing new applications after file deletion can overwrite deleted data and reduce recovery chances.\n\n'
          '**c. Keep device powered**\n'
          'Ensure your device has sufficient battery or is connected to a power source during scanning. Interruptions during the scan process can affect results.\n\n'
          '**d. Regular backups**\n'
          'While our app helps recover deleted files, maintaining regular backups of important data is the best protection against data loss.\n\n'
          '**e. Storage space**\n'
          'Having at least 20% free storage space on your device improves scanning efficiency and recovery results.',
    },
    {
      'title': '5. Common Error Messages',
      'content': '**a. "Insufficient Storage Space"**\n'
          'This error appears when your device doesn\'t have enough free space to complete the recovery process. Free up storage by deleting unnecessary files or moving them to external storage.\n\n'
          '**b. "Permission Denied"**\n'
          'The app requires specific permissions to function properly. Go to your device settings > Apps > Old File Recovery > Permissions, and ensure all necessary permissions are granted.\n\n'
          '**c. "Scan Interrupted"**\n'
          'This occurs when the scan process is unexpectedly stopped. Ensure your device has sufficient battery, isn\'t overheating, and has enough free memory.\n\n'
          '**d. "No Files Found"**\n'
          'If no files are found during scanning, it may mean that the deleted files have been completely overwritten or were deleted too long ago to recover.\n\n'
          '**e. "Process Timeout"**\n'
          'This error appears when the scan takes too long. Try scanning smaller areas or specific file types instead of the entire storage.',
    },
    {
      'title': '6. Contact Support',
      'content': 'If you need additional help or have questions not covered in our support sections, please reach out to our support team.\n\n'
          '**Email Support**\n'
          'For general inquiries and non-urgent issues, email us at: developers.nexquagen.tech@gmail.com\n\n'
          '**In-App Support**\n'
          'Use the "Report Issue" feature within the app to send us detailed information about any problems you\'re experiencing. This automatically includes technical details that help us diagnose the issue faster.\n\n'
          '**Response Time**\n'
          'We aim to respond to all support requests within 24-48 hours during business days. For urgent issues, please indicate "URGENT" in your email subject line.',
    },
    {
      'title': '7. Feature Requests',
      'content': 'We constantly strive to improve our app based on user feedback. If you have suggestions for new features or enhancements:\n\n'
          '**Submit Feature Request**\n'
          'Email your ideas to: developers.nexquagen.tech@gmail.com\n\n'
          '**What to Include**\n'
          'When submitting feature requests, please include:\n\n'
          '- A clear description of the proposed feature.\n'
          '- How you envision it working.\n'
          '- Why you believe it would be valuable.\n\n'
          '**Voting on Features**\n'
          'Join our beta testing program to vote on upcoming features and help shape the future of the app.',
    },
    {
      'title': '8. Updates & Compatibility',
      'content': '**a. Latest Version**\n'
          'Using the latest version ensures you have access to the most recent improvements and bug fixes. Check your app store regularly for updates.\n\n'
          '**b. Device Compatibility**\n'
          'Old File Recovery is compatible with:\n\n'
          '- Android devices running version 8.0 (Oreo) or newer.\n'
          '- Devices with at least 3GB of RAM for optimal performance.\n'

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
                _buildHelpHeader(),
                SizedBox(height: 30.h),
                _buildQuickNavigation(),
                SizedBox(height: 20.h),
                ..._buildHelpSections(),
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
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            // Implement search functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Searching help articles..."),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 1),
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

  Widget _buildHelpHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Help & Support',
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
              'Version 2.0.4',
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
                        Icons.help_outline,
                        color: CusColor.darkBlue3,
                        size: 18.h,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'How Can We Help?',
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
                  'Welcome to our Help & Support center! Here you\'ll find answers to common questions, troubleshooting tips, and guidance on how to get the most out of Old File Scan Recovery.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'If you can\'t find what you\'re looking for, don\'t hesitate to contact our support team directly through the "Contact Support" section.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 16.h),
                InkWell(
                  onTap: ()=> openEmail("developers.nexquagen.tech@gmail.com"),

                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: CusColor.darkBlue3,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Contact Support Team',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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
            'Quick Navigation',
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

  List<Widget> _buildHelpSections() {
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
  Future<void> openEmail(String emailAddress) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch $emailUri';
    }
  }

}