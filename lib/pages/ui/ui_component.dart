import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../color_lib.dart';

class CusItemCard{
  static Widget historyItem(String title, String time, IconData icon,GestureTapCallback fun) {
    return GestureDetector(
      onTap: fun,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        subtitle: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
      ),
    );
  }

  /// Box Decoration for Sections
  static BoxDecoration boxDecoration() {
    return BoxDecoration(
      color: CusColor.darkBlue3,
      borderRadius: BorderRadius.circular(16),

      boxShadow: const[
         BoxShadow(
          color: Colors.black26,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  /// Button Style
  static ButtonStyle buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: CusColor.decentWhite,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  /// Title Style
  static TextStyle titleStyle() {
    return const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }

  /// Subtitle Style
  static TextStyle subtitleStyle() {
    return const TextStyle(
      fontSize: 14,
      color: Colors.white70,
    );
  }
  static Widget buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required IconData iconButton,
    required String titleButton,
    required VoidCallback onTap,

  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 270.w,
        padding: const EdgeInsets.all(15),
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [ CusColor.darkBlue3,CusColor.darkBlue3,CusColor.darkBlue3,CusColor.darkBlue.withOpacity(.4),CusColor.darkBlue3,CusColor.darkBlue3,],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(4, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(-4, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, size: 50, color: Colors.white),
            ),
            SizedBox(height: 15.h),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(iconButton, color: Colors.white),
              label: Text(titleButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}