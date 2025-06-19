import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateScreen extends StatelessWidget {
  const AppUpdateScreen({super.key});
  Future<void> _launchPlayStore() async {
    const String packageName = 'com.old.file_recovery';
    final Uri url = Uri.parse(
        "https://play.google.com/store/apps/details?id=$packageName"
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                _buildAnimatedUpdateIcon(),
                SizedBox(height: 10.h),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.25),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                                spreadRadius: 0,
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFEFF6FF),
                              width: 4,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset(
                              'assets/icon.png',
                              width: 100,
                              height: 80,
                              fit: BoxFit.cover,errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.folder_open,
                                size: 40.w,
                                color: const Color(0xFF3B82F6),
                              );
                            },

                            ),
                          ),
                        ),

                       const Spacer(),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Update Required',
                              style: TextStyle(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Your File Recovery app needs to be updated to continue using all recovery features and access the latest security improvements.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: const Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),

                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'Current',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'v2.0.4',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                    Text(
                                      'Expired',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 40.h,
                                width: 1,
                                color: const Color(0xFFE2E8F0),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'Latest',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'v2.0.6',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF22C55E),
                                      ),
                                    ),
                                    Text(
                                      'Available',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: const Color(0xFF22C55E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 10,),
                        ElevatedButton(
                          onPressed: _launchPlayStore,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 58.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.r),
                            ),
                            elevation: 10,
                            shadowColor: const Color(0xFF3B82F6).withOpacity(0.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.system_update_alt, size: 24.w),
                              SizedBox(width: 12.w),
                              Text(
                                'UPDATE NOW',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6.h),
                        TextButton(
                          onPressed: () {
                            SystemNavigator.pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                          ),
                          child: Text(
                            'Exit App',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Animated update icon widget
  Widget _buildAnimatedUpdateIcon() {
    return Container(
      height: 100.h,
      width: 100.w,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Icon(
        Icons.update,
        size: 50.w,
        color: const Color(0xFF3B82F6),
      ),
    );
  }

  // Feature item widget
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              size: 22.w,
              color: const Color(0xFF3B82F6),
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}