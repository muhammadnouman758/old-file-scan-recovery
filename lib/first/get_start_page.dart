import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:old_file_recovery/first/splash_screen.dart';
import 'package:old_file_recovery/pages/color_lib.dart';
import '../pages/storage_analyzer/3d_drawer.dart';
import 'dart:math' as math;

class GetStartPage extends StatefulWidget {
  const GetStartPage({super.key});

  @override
  State<GetStartPage> createState() => _GetStartPageState();
}

class _GetStartPageState extends State<GetStartPage> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late AnimationController _buttonAnimationController;
  late AnimationController _titleAnimationController;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonGlowAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _titleFadeAnimation;

  final List<String> _pageTitles = [
    'Recover Your Deleted Files Easily',
    'Deep Scans For Efficient Results',
    'Secure and Encrypt Your Files Efficiently',
  ];
  final List<String> _imageAssets = [
    'assets/bg-get-page-1.png',
    'assets/page-2.png',
    'assets/page-3.png',
  ];

  final List<List<Color>> _gradientColors = [
    [
      const Color(0xff28487B),
      const Color(0xff4468a6),
      const Color(0xff6E94CF),
      const Color(0xffB9CDEE),
    ],
    [
      const Color(0xff2A4E8F),
      const Color(0xff5173A6),
      const Color(0xff7A9FD9),
      const Color(0xffC3D5F3),
    ],
    [
      const Color(0xff224277),
      const Color(0xff3E5F9E),
      const Color(0xff5D7FC5),
      const Color(0xffA9BFEB),
    ],
  ];
  List<Particle> particles = [];
  late AnimationController _particleAnimController;

  int particleCount = 30; // Increased from 12 to 30

  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _particleAnimController = AnimationController(
      duration: const Duration(milliseconds: 10000),
      vsync: this,
    )..repeat();
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _buttonGlowAnimation = Tween<double>(begin: 2.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: Curves.easeIn,
      ),
    );
    _initParticles();

    _controller.addListener(() {
      if (_controller.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _controller.page?.round() ?? 0;
        });
        _titleAnimationController.reset();
        _titleAnimationController.forward();
      }
    });
    _titleAnimationController.forward();


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
            (random.nextDouble() - 0.5) * 1.5,
            (random.nextDouble() - 0.5) * 1.5,
          ),
          radius: random.nextDouble() * 8 + 4,
          opacity: random.nextDouble() * 0.5 + 0.2,
        ),
      );
    }
  }

  void _pauseAnimations() {
    if (!_isPaused) {
      _isPaused = true;
      _buttonAnimationController.stop();
      _particleAnimController.stop();
    
    }
  }

  void _resumeAnimations() {
    if (_isPaused) {
      _isPaused = false;
      _buttonAnimationController.repeat(reverse: true);
      _particleAnimController.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _buttonAnimationController.dispose();
    _titleAnimationController.dispose();
    _particleAnimController.dispose();
    particles.clear();
    WidgetsBinding.instance.removeObserver(_onAppLifecycleListener);
    super.dispose();
  }

  final _onAppLifecycleListener = AppLifecycleListener(
      onHide: () {},
      onShow: () {}
  );

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: SafeArea(
          child: SizedBox(
            key: ValueKey<int>(_currentPage),
            height: 5.h,
            width: 120.w,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                      (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: index == _currentPage ? 18.0 : 8.0,
                    height: 8.0,
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color: index == _currentPage
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFFFFFFFF).withOpacity(0.4),
                      boxShadow: index == _currentPage
                          ? [
                        BoxShadow(
                          color: const Color(0xffB9CDEE).withOpacity(0.5),
                          blurRadius: 8.0,
                          spreadRadius: 1.0,
                        )
                      ]
                          : [],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact(); // Add haptic feedback
                      _controller.animateToPage(
                        2,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: CusColor.whiteDark,
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp,
                      ),
                    ),
                    child: const Text("Skip"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _particleAnimController,
            builder: (context, child) {
              if (!_isPaused) {
                return CustomPaint(
                  painter: ParticlePainter(
                    particles: particles,
                    animationValue: _particleAnimController.value,
                    gradientColors: _gradientColors[_currentPage],
                  ),
                  size: Size(1.sw, 1.sh),
                );
              } else {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomRight,
                      colors: _gradientColors[_currentPage],
                      stops: const [0.1, 0.4, 0.7, 0.9],
                    ),
                  ),
                );
              }
            },
          ),

          // Main content
          PageView.builder(
            controller: _controller,
            itemCount: 3,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
              HapticFeedback.selectionClick();
            },
            itemBuilder: (context, index) {
              return _buildAnimatedPage(index, isSmallScreen);
            },
          ),
          if (!isSmallScreen)
            Positioned(
              bottom: 20.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                      (index) => GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _controller.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    child: Container(
                      width: 10.w,
                      height: 10.h,
                      margin: EdgeInsets.symmetric(horizontal: 5.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedPage(int index, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: isSmallScreen ? 70.h : 100.h),

          SlideTransition(
            position: _titleSlideAnimation,
            child: FadeTransition(
              opacity: _titleFadeAnimation,
              child: Text(
                _pageTitles[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 24.sp : 28.sp,
                  shadows: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 30.h : 40.h),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut, // Changed from easeOutBack to avoid overshooting
              builder: (context, value, child) {
                final safeValue = value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: safeValue,
                  child: Opacity(
                    opacity: safeValue,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(_imageAssets[index]),
                          fit: BoxFit.contain,
                          onError: (exception, stackTrace) {
                            debugPrint('Failed to load image: ${_imageAssets[index]}');
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Animated button
          ScaleTransition(
            scale: _buttonScaleAnimation,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact(); // Add haptic feedback

                if (index < 2) {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                  );
                } else {
                  // Show a transition animation before navigation
                  try {
                    showGeneralDialog(
                      context: context,
                      pageBuilder: (_, animation1, __) => Container(),
                      transitionBuilder: (context, animation, secondaryAnimation, child) {
                        final curvedAnimation = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        );
                        return FadeTransition(
                          opacity: curvedAnimation,
                          child: ScaleTransition(
                            scale: curvedAnimation,
                            child: Container(
                              color: Colors.black,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: CusColor.whiteDark,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                    );

                    // Short delay before actual navigation
                    Future.delayed(const Duration(milliseconds: 800), () {
                      try {
                        FirstTime.insertKey();
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, animation, __) => FadeTransition(
                              opacity: animation,
                              child: const HomePageOriginal(),
                            ),
                            transitionDuration: const Duration(milliseconds: 800),
                          ),
                        );
                      } catch (e) {
                        // Error handling for navigation
                        debugPrint('Navigation error: $e');
                        Navigator.pop(context); // Close the dialog if navigation fails

                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('An error occurred. Please try again.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    });
                  } catch (e) {
                    debugPrint('Dialog error: $e');
                  }
                }
              },
              child: AnimatedBuilder(
                animation: _buttonGlowAnimation,
                builder: (context, child) {
                  return Container(
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 40.h : 60.h),
                    height: isSmallScreen ? 50.h : 60.h,
                    width: 260.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xffB9CDEE).withOpacity(0.8),
                          spreadRadius: _buttonGlowAnimation.value,
                          blurRadius: _buttonGlowAnimation.value * 2,
                        )
                      ],
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xff28487B),
                          Color(0xff4468a6),
                          Color(0xff6E94CF),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        index < 2 ? (index == 0 ? 'Get Started' : 'Next') : 'Launch App',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16.sp : 18.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Particle class for background animation
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

    // Bounce off edges
    if (position.dx < 0 || position.dx > size.width) {
      speed = Offset(-speed.dx, speed.dy);
    }

    if (position.dy < 0 || position.dy > size.height) {
      speed = Offset(speed.dx, -speed.dy);
    }

    // Keep particles within bounds
    position = Offset(
      position.dx.clamp(0, size.width),
      position.dy.clamp(0, size.height),
    );
  }
}

// Custom painter for particle animation - optimized and enhanced for larger bubbles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final List<Color> gradientColors;

  // Increased connection threshold for more visible connections
  final double connectionThreshold = 120.0; // Increased from 80.0 to 120.0

  ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint background gradient
    final Rect rect = Offset.zero & size;
    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomRight,
        colors: gradientColors,
        stops: const [0.1, 0.4, 0.7, 0.9],
      ).createShader(rect);

    canvas.drawRect(rect, gradientPaint);

    // Performance optimization - calculate pulse effect once
    final pulseEffect = math.sin(animationValue * 2 * math.pi) * 0.3 + 0.7;

    // Update and draw particles
    for (var particle in particles) {
      particle.update(size);

      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity * pulseEffect)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.radius, paint);

      // Enhanced glow effect for all particles
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity * 0.3) // Increased opacity
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8); // Increased blur

      // Add glow to all particles with enhanced size
      canvas.drawCircle(particle.position, particle.radius * 1.5, glowPaint);
    }

    // Draw connecting lines between particles - improved visibility
    for (int i = 0; i < particles.length - 1; i++) {
      // Check more connections for denser network
      for (int j = i + 1; j < particles.length; j++) {
        final distance = (particles[i].position - particles[j].position).distance;

        if (distance < connectionThreshold) {
          // Increased opacity for more visible connections
          final opacity = (1 - distance / connectionThreshold) * 0.25; // Increased from 0.15 to 0.25

          final linePaint = Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..strokeWidth = 1.2 // Thicker lines for better visibility
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