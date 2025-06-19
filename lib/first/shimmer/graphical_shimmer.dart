import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class CustomShimmerGraph extends StatefulWidget {
  final int itemCount;

  const CustomShimmerGraph({this.itemCount = 7, super.key});

  @override
  State<CustomShimmerGraph> createState() => _CustomShimmerGraphState();
}

class _CustomShimmerGraphState extends State<CustomShimmerGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Smooth shimmer animation
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3,end:  1.0).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 10.w,vertical: 30.h),
      alignment: Alignment.topCenter,
      child: Wrap(
        spacing: 50,
        runSpacing: 46,
        children: List.generate(widget.itemCount, (index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(100.w, 100.h),
                    painter: ShimmerCircularPainter(_animation.value),
                  );
                },
              ),
              const SizedBox(height: 6),
              Container(
                width: 80.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ShimmerCircularPainter extends CustomPainter {
  final double opacity;

  ShimmerCircularPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey.withOpacity(opacity)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final Paint backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final Rect rect = Rect.fromCircle(center: size.center(Offset.zero), radius: 45);
    canvas.drawCircle(size.center(Offset.zero), 45, backgroundPaint);
    canvas.drawArc(rect, -pi / 2, pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
