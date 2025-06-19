import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'dart:ui';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;
  late AnimationController _animationController;
  late List<GlobalKey> _sectionKeys;
  int _expandedSectionIndex = -1;

  final List<Map<String, String>> _sections = [
  {
   'title': '1. Introduction',
  'content': 'At Old File Scan Recovery, we prioritize your privacy and are committed to being transparent about how your data is handled. This policy explains:\n\n'
  '- What information we access and why.\n'
  '- How we use permissions.\n'
  '- How we ensure your data remains secure.\n'
  '- Your rights and controls over your data.\n\n'
  'We encourage you to read this policy carefully to understand our practices and how we protect your privacy.',
},
{
'title': '2. No Data Collection or Sharing',
'content': '**a. No Personal Data Collection**\n'
'Old File Scan Recovery does not collect, store, or transmit any personal data whatsoever. This includes, but is not limited to:\n\n'
'- Your name, email address, phone number, or any other identifiable information.\n'
'- Location data, device identifiers, or usage patterns.\n\n'
'The app operates entirely offline, and there is no chance of any kind of data collection. We do not require or access any personal information to provide our services.\n\n'
'**b. No File Data Sharing**\n'
'All file recovery operations are performed locally on your device. This means:\n\n'
'- We do not upload, share, or transmit any of your files, file metadata, or recovery results to external servers or third parties.\n'
'- Your files remain on your device at all times, and we do not have access to them beyond what is necessary for the recovery process.\n\n'
'**c. No Third-Party Services**\n'
'We do not use any third-party services, analytics tools, or advertising frameworks that might collect or share your data. This ensures that your information remains entirely under your control.',
},
{
'title': '3. Handling of Scan Results',
'content': '**a. Temporary Storage of Scan Results**\n'
'The app creates scan results for images, videos, audio, and documents, which are stored temporarily in the Android device\'s internal memory.\n\n'
'**b. No External Access**\n'
'The scan results are not shared, transmitted, or accessed by any external parties. They remain entirely within the app and are used only to help you recover your files.\n\n'
'**c. Automatic Deletion**\n'
'Once the app is closed or the recovery process is completed, all temporary data, including scan results and recovery logs, are automatically deleted.',
},
{
'title': '4. Permission Transparency',
'content': '**a. MANAGE_EXTERNAL_STORAGE Permission**\n'
'Purpose: This permission allows the app to scan your devices entire storage to locate and recover lost or deleted files. It is essential for accessing hidden or residual directories that standard APIs (like SAF or MediaStore) cannot reach.\n\n'
'Usage: The permission is used exclusively for file recovery. We do not access, modify, or share any files beyond what is necessary for the recovery process.\n\n'
"User Control: You can deny this permission, but doing so may limit the app's ability to recover files from certain directories.\n\n"
'**b. Storage Access Permission**\n'
"Purpose: This permission allows the app to read and recover files from your device's storage.\n\n"
'Usage: The app uses this permission to locate and restore lost files. No data is written to your storage unless you explicitly choose to save recovered files.\n\n'
'**c. Internet Access (if applicable)**\n'
'Purpose: If the app includes optional features like updates or support, internet access may be required.\n\n'
'Usage: This permission is not used for data collection or sharing. It is solely for providing app updates or user support.',
},
{
'title': '5. How We Ensure Your Privacy',
'content': '**a. Local-Only Operations**\n'
'All file scanning and recovery processes occur entirely on your device. No data leaves your device at any point. This ensures that your files and personal information remain private and secure.\n\n'
'**b. No Background Activity**\n'
'The app does not run in the background or perform any operations without your explicit action. This means that the app only accesses your data when you actively use it for file recovery.\n\n'
'**c. Secure and Isolated Environment**\n'
'All scan results and recovery operations are performed in a secure and isolated environment within the app. This ensures that your data is protected from unauthorized access or exposure.',
},
{
'title': '6. User Transparency and Control',
'content': '**a. Clear Explanations**\n'
'When you first launch the app, we explain why certain permissions are required and how they will be used. This ensures that you are fully informed before granting any permissions.\n\n'
'**b. Permission Management**\n'
"You can manage or revoke permissions at any time through your device's settings. However, revoking permissions may limit the app's functionality. We encourage you to review and adjust permissions based on your comfort level.\n\n"
'**c. No Hidden Features**\n'
'There are no hidden features or processes that collect or share your data. Everything the app does is clearly explained in this policy and within the app itself.',
},
{
'title': '7. Security Measures',
'content': '**a. Local Processing**\n'
'Since all operations are performed locally, your data never leaves your device, reducing the risk of unauthorized access.\n\n'
'**b. No External Servers**\n'
'We do not use external servers for file recovery or storage, ensuring that your data remains private and secure.\n\n'
'**c. Regular Updates**\n'
'We regularly update the app to address potential security vulnerabilities and improve performance. This ensures that your data is always protected.',
},
{
'title': "8. Children's Privacy",
'content': 'Old File Scan Recovery is not intended for use by children under the age of 13. We do not knowingly collect or store any information from children. If you believe a child has provided us with personal information, please contact us immediately so we can take appropriate action.',
},
{
'title': '9. Changes to This Privacy Policy',
'content': 'We may update this Privacy Policy from time to time to reflect changes in our practices or legal requirements. If we make significant changes, we will notify you through the app or via email (if applicable). Your continued use of the app after any changes indicates your acceptance of the updated policy.',
},
{
'title': '10. Contact Us',
'content': 'If you have any questions or concerns about this Privacy Policy or how we handle your data, please contact us at:\n'
'Email: developers.nexquagen.tech@gmail.com\n'
'We are here to help and value your feedback!',
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
              _buildPolicyHeader(),
              SizedBox(height: 30.h),
              _buildQuickNavigation(),
              SizedBox(height: 20.h),
              ..._buildPolicySections(),
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
        'Privacy Policy',
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
              content: Text("Sharing Privacy Policy..."),
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

Widget _buildPolicyHeader() {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Policy',
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
                      Icons.security,
                      color: CusColor.darkBlue3,
                      size: 18.h,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Our Commitment',
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
                'Welcome to Old File Scan Recovery! We are dedicated to protecting your privacy and ensuring that your data is handled with the utmost care and transparency.',
                style: TextStyle(
                  fontSize: 16.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'This Privacy Policy explains how we access, use, and safeguard your information when you use our app. By using Old File Scan Recovery, you agree to the terms outlined in this policy.',
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

List<Widget> _buildPolicySections() {
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