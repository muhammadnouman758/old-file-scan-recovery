import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'dart:ui';

class DataCollectionScreen extends StatefulWidget {
  const DataCollectionScreen({super.key});

  @override
  State<DataCollectionScreen> createState() => _DataCollectionScreenState();
}

class _DataCollectionScreenState extends State<DataCollectionScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;
  late AnimationController _animationController;
  late List<GlobalKey> _sectionKeys;
  int _expandedSectionIndex = -1;

  final List<Map<String, String>> _sections = [
    {
      'title': '1. No Personal Data Collection',
      'content': 'Old File Scan Recovery is designed with your privacy as the top priority. We believe your data belongs to you, not us.\n\n'
          '**Complete Privacy Guarantee**\n'
          'We do not collect, store, or transmit any of your personal data. This includes, but is not limited to:\n\n'
          '- Names, email addresses, or contact information\n'
          '- Location data or GPS coordinates\n'
          '- Device identifiers or unique IDs\n'
          '- IP addresses or network information\n'
          '- Browsing history or usage patterns\n'
          '- Demographic information\n\n'
          '**No Account Required**\n'
          'Our app works completely without requiring you to create an account or provide any personal information whatsoever.',
    },
    {
      'title': '2. Locally Processed Files',
      'content': '**100% On-Device Processing**\n'
          'All file scanning and recovery operations happen entirely on your device. This means:\n\n'
          '- Your files never leave your device\n'
          '- No data is uploaded to any servers\n'
          '- No cloud storage is used for any part of the process\n'
          '- All temporary scan data remains local\n\n'
          '**Temporary Cache Only**\n'
          'The app creates temporary cache files during the scanning process, but these are:\n\n'
          '- Stored only in your device\'s local storage\n'
          '- Automatically deleted when you close the app\n'
          '- Never shared with any third parties',
    },
    {
      'title': '3. No Analytics or Tracking',
      'content': '**Zero Usage Tracking**\n'
          'Unlike many apps, we do not implement any analytics or tracking tools. This means:\n\n'
          '- We don\'t know how you use the app\n'
          '- We don\'t track which features you use most\n'
          '- We don\'t collect crash reports automatically\n'
          '- We don\'t monitor your in-app behavior\n\n'
          '**No Third-Party Analytics**\n'
          'We have deliberately chosen not to integrate any third-party analytics services such as Google Analytics, Firebase, or any other tracking SDKs that might compromise your privacy.',
    },
    {
      'title': '4. No Advertisements',
      'content': '**Ad-Free Experience**\n'
          'Our app does not display any advertisements. This means:\n\n'
          '- No ad networks are integrated into our app\n'
          '- No ad trackers are monitoring your activity\n'
          '- No user profiling for targeted advertising\n'
          '- No sharing of information with advertisers\n\n'
          '**No Revenue from Your Data**\n'
          'We generate revenue solely through app purchases, not by monetizing your personal data or behavior.',
    },
    {
      'title': '5. No Network Communication',
      'content': '**Offline Functionality**\n'
          'Old File Scan Recovery functions completely offline. The app:\n\n'
          '- Does not require internet access for its core functions\n'
          '- Does not send any data over the network\n'
          '- Does not communicate with any external servers\n'
          '- Does not download content from the internet\n\n'
          '**Optional Internet Permission**\n'
          'If the app requests internet permission, it is solely for optional features like checking for updates or sending support requests. Even with this permission, no personal data or file information is ever transmitted.',
    },
    {
      'title': '6. Permissions Explained',
      'content': '**Storage Access**\n'
          'The only critical permission we request is storage access (MANAGE_EXTERNAL_STORAGE). This is essential because:\n\n'
          '- File recovery requires access to your device storage\n'
          '- We need to scan for deleted and recoverable files\n'
          '- We need permission to save recovered files\n\n'
          '**How We Use Storage Access**\n'
          'This permission is used exclusively for:\n\n'
          '- Scanning your device for recoverable files\n'
          '- Creating temporary scan results in local storage\n'
          '- Saving recovered files to  selected location\n'
          '- No other data is accessed, modified, or shared',
    },
    {
      'title': '7. Your Data Control',
      'content': '**Full User Control**\n'
          'You maintain complete control over your data at all times:\n\n'
          '- You decide which folders to scan\n'
          '- You choose which files to recover\n'
          '**No Background Processing**\n'
          'The app only scans or accesses files when you explicitly request it to do so. It does not run any background processes that might access your data when you\'re not using the app.',
    },
    {
      'title': '8. Independent Verification',
      'content': '**Open to Scrutiny**\n'
          'We welcome privacy-conscious users to verify our claims:\n\n'
          '- Use network monitoring tools to confirm no data is sent\n'
          '- Check system logs to verify no background processes\n'
          '- Review app permissions to confirm limited access\n\n'
          '**Privacy Certifications**\n'
          'We are actively pursuing independent privacy certifications to further validate our commitment to protecting your data.',
    },
    {
      'title': '9. Our Privacy Commitment',
      'content': '**Privacy by Design**\n'
          'Old File Scan Recovery was built from the ground up with privacy as a core principle, not an afterthought. This means:\n\n'
          '- Privacy-preserving architecture\n'
          '- Minimal permissions model\n'
          '- No unnecessary features that might compromise privacy\n'
          '- Regular privacy-focused code reviews\n\n'
          '**Transparent Development**\n'
          'We believe in being completely transparent about our practices. If any aspect of our data handling changes, we will notify users prominently and provide clear explanations.',
    },
    {
      'title': '10. Questions & Feedback',
      'content': 'We welcome any questions or feedback about our data practices. If you have concerns about privacy or data handling, please contact us at:\n\n'
          'Email: developers.nexquagen.tech@gmail.com\n\n'
          'We are committed to addressing any privacy concerns and continuously improving our practices to better protect your data.',
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
          'Data Collection',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            // Implement sharing functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Sharing Data Collection Policy..."),
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

  Widget _buildPageHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Collection',
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
                        Icons.shield,
                        color: CusColor.darkBlue3,
                        size: 18.h,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Zero Data Collection',
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
                  'Old File Scan Recovery is designed with a strict no-data-collection policy. We prioritize your privacy above all else.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'We do not collect, store, or share ANY of your personal information or file data. Our app works 100% locally on your device, with no data ever being transmitted elsewhere.',
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