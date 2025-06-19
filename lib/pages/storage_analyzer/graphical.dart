import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
class StorageRadialBarChart extends StatelessWidget {
  final Map<String, int> storageData;

  const StorageRadialBarChart({super.key,required this.storageData});

  @override
  Widget build(BuildContext context) {
    double totalSize = storageData.values.fold(0, (a, b) => a + b).toDouble();
    if (totalSize == 0) {
      return const Center(child: Text("No storage data available"));
    }

    return Column(
      children: [
        Wrap(
          spacing: 50,
          runSpacing: 26,
          children: storageData.entries.map((entry) {
            double valueInGB = entry.value / (1024 * 1024 * 1024);
            double percentage = (valueInGB / (totalSize / (1024 * 1024 * 1024)));

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(
                        value: percentage,
                        strokeWidth: 8,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(_getColor(entry.key)),
                      ),
                    ),
                    Text(
                      "${(percentage * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  '${entry.key}\n${valueInGB.toStringAsFixed(2)} GB',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12,color: CusColor.darkBlue3, fontWeight: FontWeight.bold),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getColor(String category) {
    switch (category) {
      case 'Images': return CusColor.darkPurple;
      case 'Videos': return CusColor.darkRed2;
      case 'Documents': return CusColor.darkRed;
      case 'Audio': return CusColor.offWhite3;
      case 'Compressed': return CusColor.lightYellow2;
      case 'APK': return CusColor.darkPink2;
      case 'Other': return CusColor.darkBlue3;
      default: return Colors.grey;
    }
  }
}

