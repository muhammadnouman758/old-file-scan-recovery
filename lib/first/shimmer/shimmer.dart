import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

class Particle {
  Offset position;
  Offset speed;
  double radius;
  double opacity;
  Color color;

  Particle({
    required this.position,
    required this.speed,
    required this.radius,
    required this.opacity,
    required this.color,
  });

  void update(Size size) {
    position += speed;

    if (position.dx < 0) {
      position = Offset(0, position.dy);
      speed = Offset(-speed.dx, speed.dy);
    } else if (position.dx > size.width) {
      position = Offset(size.width, position.dy);
      speed = Offset(-speed.dx, speed.dy);
    }

    if (position.dy < 0) {
      position = Offset(position.dx, 0);
      speed = Offset(speed.dx, -speed.dy);
    } else if (position.dy > size.height) {
      position = Offset(position.dx, size.height);
      speed = Offset(speed.dx, -speed.dy);
    }
  }
}
class VideoScannerPainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final double scanLinePosition;
  final double scanLineWidth;
  final double scanProgress;
  final bool isScanning;
  final double hexGridOpacity;
  final Color primaryColor;
  final Color accentColor;
  final Paint _backgroundPaint = Paint();
  final Paint _hexPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5;
  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;
  final Paint _glowPaint = Paint()..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _linePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0;
  final Paint _scanLinePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.0;
  final Paint _scanGlowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  final Paint _markerPaint = Paint()..style = PaintingStyle.fill;
  final Paint _trackPaint = Paint()..style = PaintingStyle.fill;
  final Paint _progressPaint = Paint();
  final Paint _progressGlowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _cornerPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5;
  final Paint _gridPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5;
  final Path _hexPath = Path();
  final TextPainter _textPainter = TextPainter(textDirection: TextDirection.ltr);

  final Map<int, List<int>> _connectionMap = {};
  final double _connectionThreshold = 120.0;

  VideoScannerPainter({
    required this.particles,
    required this.animationValue,
    required this.scanLinePosition,
    required this.scanLineWidth,
    required this.scanProgress,
    required this.isScanning,
    required this.hexGridOpacity,
    required this.primaryColor,
    required this.accentColor,
  }) {
    _precalculateConnections();
  }

  void _precalculateConnections() {
    _connectionMap.clear();
    for (int i = 0; i < particles.length - 1; i++) {
      _connectionMap[i] = [];
      for (int j = i + 1; j < particles.length; j++) {
        final distance = (particles[i].position - particles[j].position).distance;
        if (distance < _connectionThreshold) {
          _connectionMap[i]?.add(j);
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    _backgroundPaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF101823),
        Color(0xFF1A2536),
        Color(0xFF0A1218),
      ],
    ).createShader(rect);

    canvas.drawRect(rect, _backgroundPaint);
    _drawHexGrid(canvas, size);
    _drawParticlesAndConnections(canvas, size);

    if (isScanning) {
      _drawScanProgressBar(canvas, size);
    }


    if (isScanning) {
      _drawScanLine(canvas, size);
    }

    _drawScanningFocusArea(canvas, size);
  }

  void _drawHexGrid(Canvas canvas, Size size) {
    _hexPaint.color = primaryColor.withOpacity(hexGridOpacity * 0.05);

    final hexSize = size.width / 15;
    final horizontalSpacing = hexSize * 1.5;
    final verticalSpacing = hexSize * math.sqrt(3);


    const int startRow = -1;
    final int endRow = (size.height / verticalSpacing).ceil() + 1;
    const int startCol = -1;
    final int endCol = (size.width / horizontalSpacing).ceil() + 1;
    final List<double> angles = List.generate(
        6, (i) => (i * 60) * math.pi / 180);

    for (int row = startRow; row < endRow; row++) {
      for (int col = startCol; col < endCol; col++) {
        final xOffset = col * horizontalSpacing + (row % 2 == 0 ? 0 : horizontalSpacing / 2);
        final yOffset = row * verticalSpacing;

        _hexPath.reset();

        for (int i = 0; i < 6; i++) {
          final x = xOffset + hexSize * math.cos(angles[i]);
          final y = yOffset + hexSize * math.sin(angles[i]);

          if (i == 0) {
            _hexPath.moveTo(x, y);
          } else {
            _hexPath.lineTo(x, y);
          }
        }
        _hexPath.close();
        canvas.drawPath(_hexPath, _hexPaint);
      }
    }
  }

  void _drawParticlesAndConnections(Canvas canvas, Size size) {
    final pulseEffect = math.sin(animationValue * 2 * math.pi) * 0.3 + 0.7;
    _precalculateConnections();

    for (var particle in particles) {
      double scanLineEffect = 1.0;

      if (isScanning) {
        final distanceToScanLine = (particle.position.dy - scanLinePosition).abs();
        if (distanceToScanLine < scanLineWidth) {
          scanLineEffect = 2.0 + (1.0 - distanceToScanLine / scanLineWidth) * 2.0;
        }
      }

      final opacityValue = (particle.opacity * pulseEffect * scanLineEffect).clamp(0.0, 1.0);

      _particlePaint.color = particle.color.withOpacity(opacityValue);
      canvas.drawCircle(particle.position, particle.radius * scanLineEffect, _particlePaint);

      if (opacityValue > 0.2) {
        final glowOpacityValue = (particle.opacity * 0.3 * scanLineEffect).clamp(0.0, 1.0);
        _glowPaint.color = particle.color.withOpacity(glowOpacityValue);
        canvas.drawCircle(particle.position, particle.radius * 1.8 * scanLineEffect, _glowPaint);
      }
    }
    _connectionMap.forEach((i, connections) {
      for (int j in connections) {
        final distance = (particles[i].position - particles[j].position).distance;

        if (distance >= _connectionThreshold) continue;
        double scanLineEffect = 1.0;

        if (isScanning) {
          double particle1DistanceToScan = (particles[i].position.dy - scanLinePosition).abs();
          double particle2DistanceToScan = (particles[j].position.dy - scanLinePosition).abs();

          if (particle1DistanceToScan < scanLineWidth || particle2DistanceToScan < scanLineWidth) {
            scanLineEffect = 3.0;
          }
        }

        final baseOpacity = (1 - distance / _connectionThreshold) * 0.25;
        final opacity = (baseOpacity * scanLineEffect).clamp(0.0, 1.0);

        _linePaint.color = particles[i].color.withOpacity(opacity);
        canvas.drawLine(particles[i].position, particles[j].position, _linePaint);
      }
    });
  }

  void _drawScanLine(Canvas canvas, Size size) {
    _scanLinePaint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        accentColor.withOpacity(0.0),
        accentColor.withOpacity(0.6),
        accentColor,
        accentColor.withOpacity(0.6),
        accentColor.withOpacity(0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, 4));
    canvas.drawLine(
      Offset(0, scanLinePosition),
      Offset(size.width, scanLinePosition),
      _scanLinePaint,
    );
    _scanGlowPaint.shader = RadialGradient(
      center: Alignment.center,
      radius: 0.5,
      colors: [
        accentColor.withOpacity(0.3),
        accentColor.withOpacity(0.0),
      ],
    ).createShader(Rect.fromLTWH(0, scanLinePosition - scanLineWidth / 2, size.width, scanLineWidth));

    canvas.drawRect(
      Rect.fromLTWH(0, scanLinePosition - scanLineWidth / 2, size.width, scanLineWidth),
      _scanGlowPaint,
    );

    _markerPaint.color = accentColor;

    const markerWidth = 10.0;
    const markerHeight = 20.0;

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, scanLinePosition - markerHeight / 2, markerWidth, markerHeight),
        topRight: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      _markerPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(size.width - markerWidth, scanLinePosition - markerHeight / 2, markerWidth, markerHeight),
        topLeft: const Radius.circular(4),
        bottomLeft: const Radius.circular(4),
      ),
      _markerPaint,
    );
  }

  void _drawScanProgressBar(Canvas canvas, Size size) {
    const barHeight = 4.0;
    const barPadding = 20.0;
    const cornerRadius = 2.0;

    _trackPaint.color = Colors.white.withOpacity(0.15);

    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barPadding, size.height - barHeight - barPadding, size.width - (barPadding * 2), barHeight),
      const Radius.circular(cornerRadius),
    );
    canvas.drawRRect(trackRect, _trackPaint);
    final progressWidth = (size.width - (barPadding * 2)) * scanProgress;
    _progressPaint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        accentColor,
        primaryColor,
      ],
    ).createShader(Rect.fromLTWH(barPadding, size.height - barHeight - barPadding, progressWidth, barHeight));

    final progressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barPadding, size.height - barHeight - barPadding, progressWidth, barHeight),
      const Radius.circular(cornerRadius),
    );
    canvas.drawRRect(progressRect, _progressPaint);
    _progressGlowPaint.color = accentColor.withOpacity(0.3);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barPadding - 2, size.height - barHeight - barPadding - 2, progressWidth + 4, barHeight + 4),
        const Radius.circular(cornerRadius + 2),
      ),
      _progressGlowPaint,
    );
    final percentage = (scanProgress * 100).round();
    final textSpan = TextSpan(
      text: '$percentage%',
      style: TextStyle(
        color: Colors.white,
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
      ),
    );

    _textPainter.text = textSpan;
    _textPainter.layout();
    _textPainter.paint(
        canvas,
        Offset(
            barPadding,
            size.height - barHeight - barPadding - _textPainter.height - 8
        )
    );
  }

  void _drawScanningFocusArea(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final focusSize = size.width * 0.7;


    final cornerWidth = focusSize * 0.15;
    _cornerPaint.color = accentColor;

    void drawCorner(double x, double y, double xDir, double yDir) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x + cornerWidth * xDir, y),
        _cornerPaint,
      );
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + cornerWidth * yDir),
        _cornerPaint,
      );
    }
    drawCorner(centerX - focusSize / 2, centerY - focusSize / 2, 1, 1);  // Top-left
    drawCorner(centerX + focusSize / 2, centerY - focusSize / 2, -1, 1); // Top-right
    drawCorner(centerX - focusSize / 2, centerY + focusSize / 2, 1, -1); // Bottom-left
    drawCorner(centerX + focusSize / 2, centerY + focusSize / 2, -1, -1); // Bottom-right
    if (isScanning) {
      _gridPaint.color = accentColor.withOpacity(0.2);

      const gridCount = 8;
      final gridStep = focusSize / gridCount;

      for (int i = 1; i < gridCount; i++) {
        final offset = i * gridStep;

        canvas.drawLine(
          Offset(centerX - focusSize / 2, centerY - focusSize / 2 + offset),
          Offset(centerX + focusSize / 2, centerY - focusSize / 2 + offset),
          _gridPaint,
        );

        canvas.drawLine(
          Offset(centerX - focusSize / 2 + offset, centerY - focusSize / 2),
          Offset(centerX - focusSize / 2 + offset, centerY + focusSize / 2),
          _gridPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant VideoScannerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.scanLinePosition != scanLinePosition ||
        oldDelegate.scanProgress != scanProgress ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.hexGridOpacity != hexGridOpacity;
  }
}

class VideoScanningAnimation extends StatefulWidget {
  const VideoScanningAnimation({super.key});

  @override
  State<VideoScanningAnimation> createState() => _VideoScanningAnimationState();
}

class _VideoScanningAnimationState extends State<VideoScanningAnimation>
    with TickerProviderStateMixin {
  late AnimationController _particleAnimController;
  late AnimationController _scanLineAnimController;
  late AnimationController _scanProgressController;
  late AnimationController _hexGridController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _scanProgressAnimation;
  late Animation<double> _hexGridAnimation;

  List<Particle> particles = [];
  int particleCount = 20; // Reduced from 30 for better performance
  bool isScanning = true;
  bool _isPaused = false;
  final List<double> _progressSteps = [0.1, 0.22, 0.38, 0.45, 0.52, 0.65, 0.73, 0.8];
  int _currentProgressStep = 0;
  bool _isProgressAnimating = false;

  final Color primaryColor = const Color(0xFF00C6FF);
  final Color accentColor = const Color(0xFF7DF9FF);
  final List<Color> particleColors = const [
    Color(0xFF00C6FF),
    Color(0xFF7DF9FF),
    Color(0xFFB6FFFA),
    Color(0xFF64CCC5),
  ];
  Ticker? _particleTicker;
  double _lastTickTime = 0;

  @override
  void initState() {
    super.initState();
    _particleTicker = createTicker((elapsed) {

      if (elapsed.inMilliseconds - _lastTickTime >= 33) {
        _lastTickTime = elapsed.inMilliseconds.toDouble();
        _updateParticles();
      }
    });

    _particleAnimController = AnimationController(
      duration: const Duration(milliseconds: 10000),
      vsync: this,
    )..repeat();

    _scanLineAnimController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _scanProgressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _hexGridController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(
      begin: 0.25,
      end: 0.75,
    ).animate(
      CurvedAnimation(
        parent: _scanLineAnimController,
        curve: Curves.easeInOut,
      ),
    );
    _scanProgressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _scanProgressController,
        curve: Curves.easeOut,
      ),
    );
    _hexGridAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _hexGridController,
        curve: Curves.easeInOut,
      ),
    );
    _initParticles();
    _particleTicker?.start();
    _startSerializedProgress();
    WidgetsBinding.instance.addObserver(
      AppLifecycleListener(
          onPause: _pauseAnimations,
          onResume: _resumeAnimations
      ),
    );
  }

  void _initParticles() {
    final random = math.Random();
    particles.clear();

    for (int i = 0; i < particleCount; i++) {
      particles.add(
        Particle(
          position: Offset(
            random.nextDouble() * 1.sw,
            random.nextDouble() * 1.sh,
          ),
          speed: Offset(
            (random.nextDouble() - 0.5) * 0.8, // Slower particles for smoother look
            (random.nextDouble() - 0.5) * 0.8,
          ),
          radius: random.nextDouble() * 3 + 2, // Slightly smaller particles
          opacity: random.nextDouble() * 0.5 + 0.3,
          color: particleColors[random.nextInt(particleColors.length)],
        ),
      );
    }
  }

  void _updateParticles() {
    if (_isPaused) return;

    final size = Size(1.sw, 1.sh);
    for (var particle in particles) {
      particle.update(size);
    }

    setState(() {});
  }

  void _startSerializedProgress() {
    if (_currentProgressStep >= _progressSteps.length) {
      return;
    }

    _isProgressAnimating = true;
    double startValue = _currentProgressStep > 0 ? _progressSteps[_currentProgressStep - 1] : 0.0;
    double endValue = _progressSteps[_currentProgressStep];
    _scanProgressController.duration = Duration(
        milliseconds: 300 + (300 * math.Random().nextInt(4))
    );

    _scanProgressController.reset();
    _scanProgressAnimation = Tween<double>(
      begin: startValue,
      end: endValue,
    ).animate(
      CurvedAnimation(
        parent: _scanProgressController,
        curve: Curves.easeOut,
      ),
    );

    _scanProgressController.forward();

    _scanProgressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentProgressStep++;
        Future.delayed(Duration(milliseconds: 500 + (500 * math.Random().nextInt(4))), () {
          if (mounted && _currentProgressStep < _progressSteps.length) {
            _startSerializedProgress();
          } else if (mounted) {
            _isProgressAnimating = false;
          }
        });
      }
    });
  }

  void _pauseAnimations() {
    if (!_isPaused) {
      _isPaused = true;
      _particleTicker?.stop();
      _particleAnimController.stop();
      _scanLineAnimController.stop();
      _scanProgressController.stop();
      _hexGridController.stop();
    }
  }

  void _resumeAnimations() {
    if (_isPaused) {
      _isPaused = false;
      _particleTicker?.start();
      _particleAnimController.repeat();
      _scanLineAnimController.repeat(reverse: true);
      _hexGridController.repeat(reverse: true);
      if (isScanning && _isProgressAnimating) {
        _scanProgressController.forward();
      }
    }
  }

  @override
  void dispose() {
    _particleTicker?.dispose();
    _particleAnimController.dispose();
    _scanLineAnimController.dispose();
    _scanProgressController.dispose();
    _hexGridController.dispose();
    WidgetsBinding.instance.removeObserver(
      AppLifecycleListener(
          onPause: _pauseAnimations,
          onResume: _resumeAnimations
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _particleAnimController,
              _scanLineAnimation,
              _scanProgressAnimation,
              _hexGridAnimation
            ]),
            builder: (context, child) {
              return CustomPaint(
                painter: VideoScannerPainter(
                  particles: particles,
                  animationValue: _particleAnimController.value,
                  scanLinePosition: _scanLineAnimation.value * MediaQuery.of(context).size.height,
                  scanLineWidth: 60.0,
                  scanProgress: _scanProgressAnimation.value,
                  isScanning: isScanning,
                  hexGridOpacity: _hexGridAnimation.value,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                ),
                size: Size(1.sw, 1.sh),
              );
            },
          ),
        ),

        // Status overlay
        Positioned(
          top: 50.h,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    "Scanning in progress...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}