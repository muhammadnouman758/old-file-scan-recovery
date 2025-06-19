import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/first/get_start_page.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../pages/storage_analyzer/3d_drawer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;
  late AnimationController _textController;
  late Animation<Offset> _textAnimation;

  late AnimationController _particleAnimController;
  List<Particle> particles = [];
  int particleCount = 25; // Number of particles

  final List<Color> _gradientColors = [
    const Color(0xff28487B),
    const Color(0xff4468a6),
    const Color(0xff6E94CF),
    const Color(0xffB9CDEE),
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    loadFirstTime();

    // Icon Animation (Scale & Fade)
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _iconAnimation = CurvedAnimation(parent: _iconController, curve: Curves.easeOut);

    // Text Animation (Slide Up)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _textAnimation = Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0)).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Pulse animation for logo glow effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    // Particle animation for background
    _particleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();

    // Initialize particles
    _initParticles();

    // Start animations sequentially
    _iconController.forward().then((_) {
      _textController.forward();
    });

    // Navigate to Home Screen after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if(FirstTime.pref?.containsKey('Opened_app') == false) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => FadeTransition(
              opacity: animation,
              child: const GetStartPage(),
            ),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => FadeTransition(
              opacity: animation,
              child: const HomePageOriginal(),
            ),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
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
            (random.nextDouble() - 0.5) * 1.2,
            (random.nextDouble() - 0.5) * 1.2,
          ),
          radius: random.nextDouble() * 8 + 3, // Particle sizes between 3-11
          opacity: random.nextDouble() * 0.5 + 0.2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    _particleAnimController.dispose();
    particles.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background with particles
          AnimatedBuilder(
            animation: _particleAnimController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: particles,
                  animationValue: _particleAnimController.value,
                  gradientColors: _gradientColors,
                ),
                size: Size(1.sw, 1.sh),
              );
            },
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _iconAnimation,
                  child: FadeTransition(
                    opacity: _iconAnimation,
                    child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 170.w,
                            height: 150.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xffB9CDEE).withOpacity(0.7),
                                  blurRadius: _pulseAnimation.value,
                                  spreadRadius: _pulseAnimation.value / 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(250),
                              child: Image.asset(
                                'assets/icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }
                    ),
                  ),
                ),
                SizedBox(height: 30.h),

                SlideTransition(
                  position: _textAnimation,
                  child: Column(
                    children: [
                      Text(
                        "Old File Scan",
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        "Recover Deleted Files Easily",
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  loadFirstTime() async {
    await FirstTime.init();
  }
}

class Particle {
  Offset position;
  Offset speed;
  double radius;
  double opacity;

  Particle({
    required this.position,
    required this.speed,
    required this.radius,
    required this.opacity,
  });

  void update(Size size) {
    position += speed;

    if (position.dx < 0 || position.dx > size.width) {
      speed = Offset(-speed.dx, speed.dy);
    }

    if (position.dy < 0 || position.dy > size.height) {
      speed = Offset(speed.dx, -speed.dy);
    }
    position = Offset(
      position.dx.clamp(0, size.width),
      position.dy.clamp(0, size.height),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final List<Color> gradientColors;

  final double connectionThreshold = 100.0;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomRight,
        colors: gradientColors,
        stops: const [0.1, 0.4, 0.7, 0.9],
      ).createShader(rect);

    canvas.drawRect(rect, gradientPaint);
    final pulseEffect = math.sin(animationValue * 2 * math.pi) * 0.3 + 0.7;


    for (var particle in particles) {
      particle.update(size);

      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity * pulseEffect)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.radius, paint);

      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(particle.position, particle.radius * 1.5, glowPaint);
    }
    for (int i = 0; i < particles.length - 1; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final distance = (particles[i].position - particles[j].position).distance;

        if (distance < connectionThreshold) {
          final opacity = (1 - distance / connectionThreshold) * 0.2;

          final linePaint = Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;

          canvas.drawLine(particles[i].position, particles[j].position, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class FirstTime {
  static var _obj;
  static Future init() async {
    _obj = await SharedPreferences.getInstance();
  }
  static Future<void> insertKey() async {
    final object = await SharedPreferences.getInstance();
    object.setBool('Opened_app', true);
  }
  static SharedPreferences? get pref => _obj;
}