import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';


import '../../first/shimmer/graphical_shimmer.dart';
import 'back_process.dart';
import 'graphical.dart';

class StorageAnalysisScreen extends StatefulWidget {
  const StorageAnalysisScreen({super.key});

  @override
  State<StorageAnalysisScreen> createState() {
    return _StorageAnalysisScreenState();
  }
}

class _StorageAnalysisScreenState extends State<StorageAnalysisScreen> {
  Map<String, int> storageData = {};

  @override
  void initState() {
    super.initState();
    loadStorageData();
  }

  Future<void> loadStorageData() async {
    Map<String, int> data = await StorageAnalyzer.analyzeStorage();
    if(mounted){
      setState(() {
        storageData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CusColor.decentWhite,
      appBar: AppBar(
        title: const Text(
          "Storage Analyzer",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(onPressed: ()=> Navigator.pop(context), icon: const Icon(Icons.arrow_back,color: Colors.white,)),
        backgroundColor: CusColor.darkBlue3,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        alignment: Alignment.center,
        child: storageData.isEmpty
            ? const CustomShimmerGraph()
            : Container(
                height: double.infinity,
                width: double.infinity,
                alignment: Alignment.topCenter,
                margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
                child: SingleChildScrollView(child: StorageRadialBarChart(storageData: storageData))),
      ),
    );
  }
}
