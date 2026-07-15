import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _taglineController;
  late AnimationController _linesController;
  late AnimationController _exitController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _taglineOpacity;
  late Animation<double> _linesOpacity;
  late Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _linesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );
    _linesOpacity = Tween<double>(
      begin: 0.0,
      end: 0.35,
    ).animate(CurvedAnimation(parent: _linesController, curve: Curves.easeIn));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _linesController.forward();
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _taglineController.forward();
    await Future.delayed(const Duration(milliseconds: 1600));
    await _exitController.forward();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => widget.nextScreen,
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    _linesController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) {
        return Opacity(opacity: _exitOpacity.value, child: child);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0C14),
        body: Stack(
          children: [
            // Speed lines background
            AnimatedBuilder(
              animation: _linesOpacity,
              builder: (context, _) {
                return Opacity(
                  opacity: _linesOpacity.value,
                  child: CustomPaint(
                    painter: _SpeedLinesPainter(),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 1.1,
                  colors: [Color(0xFF0F1629), Color(0xFF0A0C14)],
                ),
              ),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo icon
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2979FF), Color(0xFF00BCD4)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2979FF).withAlpha(100),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // App name
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF2979FF), Color(0xFF00BCD4)],
                        ).createShader(bounds),
                        child: const Text(
                          'drivio',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Tagline
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: const Text(
                      'Twoja droga. Twoje zasady.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF7B8BB2),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom loader dots
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _taglineOpacity,
                child: const _PulsingDots(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      final animation = Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
      _controllers.add(controller);
      _animations.add(animation);

      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) controller.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, _) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                const Color(0xFF2979FF).withAlpha(80),
                const Color(0xFF00BCD4),
                _animations[i].value,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SpeedLinesPainter extends CustomPainter {
  final List<_SpeedLine> lines = List.generate(28, (i) {
    final rng = math.Random(i * 17 + 3);
    return _SpeedLine(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      length: 0.05 + rng.nextDouble() * 0.12,
      thickness: 0.5 + rng.nextDouble() * 1.2,
      angle: -0.15 + rng.nextDouble() * 0.3,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final paint = Paint()
        ..color = const Color(0xFF2979FF)
        ..strokeWidth = line.thickness
        ..strokeCap = StrokeCap.round;

      final startX = line.x * size.width;
      final startY = line.y * size.height;
      final len = line.length * size.width;
      final dx = math.cos(line.angle) * len;
      final dy = math.sin(line.angle) * len;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + dx, startY + dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpeedLinesPainter oldDelegate) => false;
}

class _SpeedLine {
  final double x, y, length, thickness, angle;
  const _SpeedLine({
    required this.x,
    required this.y,
    required this.length,
    required this.thickness,
    required this.angle,
  });
}
