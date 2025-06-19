import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
class VaultTrackingPage extends StatefulWidget {
  const VaultTrackingPage( {super.key});

  @override
  State<VaultTrackingPage> createState() => _VaultTrackingPageState();
}

class _VaultTrackingPageState extends State<VaultTrackingPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Vault Tracking"),
        backgroundColor: Colors.deepPurple,
      ),
      body: createWidgetCard(),
    );
  }
  Widget createWidgetCard(){
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),

      width: double.infinity,
      child: ScaleTransition(
        scale: _animation,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 8,
          color: CusColor.darkBlue3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 60, color: Colors.white),
                SizedBox(height: 10.h),
                const Text(
                  "Files Secured In Vault!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: CusColor.darkBlue3,
                  ),
                  child: const Text("OK"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
