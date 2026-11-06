import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/theme/app_theme.dart';
import 'drivio_logo_painter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _tileSize = 176.0;
  static const _logoWidth = 148.0;
  static const _wordmark = 'drivio';

  /// Where the logo tile sits, as a fraction of the screen height.
  static const _tileCenterY = 0.40;

  /// Alignment of the pin head inside the tile, the target of the exit zoom.
  static const _pinAlignment = Alignment(
    0,
    -85 * (_logoWidth / DrivioLogoPainter.logoWidth) / (_tileSize / 2),
  );

  // One timeline drives the whole intro so every element moves in sync.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startSequence();
    });
  }

  Future<void> _startSequence() async {
    if (MediaQuery.of(context).disableAnimations) {
      _intro.value = 1;
    } else {
      await _intro.forward();
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _exit.forward();
    if (!mounted) return;
    // The router sends signed-in users on to the map (or city selection).
    context.go('/login');
  }

  @override
  void dispose() {
    _intro.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final tileCenter = Offset(size.width / 2, size.height * _tileCenterY);
          return AnimatedBuilder(
            animation: Listenable.merge([_intro, _exit]),
            builder: (context, _) {
              final t = _intro.value;
              final exitRaw = _exit.value;
              final exit = Curves.easeInCubic.transform(exitRaw);
              return Opacity(
                opacity: 1 - splashInterval(exitRaw, 0.4, 1, Curves.easeIn),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CityMapPainter(
                          progress: t,
                          exit: exit,
                          destination: tileCenter,
                          tileSize: _tileSize,
                        ),
                      ),
                    ),
                    Positioned(
                      left: tileCenter.dx - _tileSize / 2,
                      top: tileCenter.dy - _tileSize / 2,
                      child: _buildTile(t, exit),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: tileCenter.dy + _tileSize / 2 + 30,
                      child: Opacity(
                        opacity: 1 - splashInterval(exitRaw, 0, 0.35),
                        child: Column(
                          children: [
                            _buildWordmark(t),
                            const SizedBox(height: 6),
                            _buildTagline(t),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// The app-icon tile pops in where the route ends, flinches when the pin
  /// lands, and on exit the camera "drives into" the pin.
  Widget _buildTile(double t, double exit) {
    final pop = splashInterval(t, 0.27, 0.42, Curves.easeOutBack);
    final appear = splashInterval(t, 0.27, 0.31);
    final logoProgress = splashInterval(t, 0.32, 1.0);
    final thud = splashInterval(logoProgress, 0.62, 0.74);
    final bloom =
        splashInterval(t, 0.27, 0.36) -
        0.45 * splashInterval(t, 0.36, 0.6, Curves.easeOut);

    return Transform.scale(
      scale: 1 + 7 * exit,
      alignment: _pinAlignment,
      child: Opacity(
        opacity: appear,
        child: Transform.rotate(
          angle: -0.25 * (1 - pop),
          child: Transform.scale(
            scale: (0.4 + 0.6 * pop) * (1 - 0.04 * math.sin(math.pi * thud)),
            child: Container(
              width: _tileSize,
              height: _tileSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_tileSize * 0.23),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.6 * bloom),
                    blurRadius: 60,
                    spreadRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: SizedBox(
                width: _logoWidth,
                height:
                    _logoWidth *
                    DrivioLogoPainter.logoHeight /
                    DrivioLogoPainter.logoWidth,
                child: CustomPaint(
                  painter: DrivioLogoPainter(progress: logoProgress),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Letters pull in from the left leaning forward, brake upright, and a
  /// headlight glint sweeps across the finished wordmark.
  Widget _buildWordmark(double t) {
    final glint = -0.2 + 1.4 * splashInterval(t, 0.86, 1.0, Curves.easeInOut);
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: const [
          AppTheme.primary,
          AppTheme.primary,
          Color(0xFFFFD6D6),
          AppTheme.primary,
          AppTheme.primary,
        ],
        stops: [
          0,
          (glint - 0.12).clamp(0.0, 1.0),
          glint.clamp(0.0, 1.0),
          (glint + 0.12).clamp(0.0, 1.0),
          1,
        ],
      ).createShader(bounds),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _wordmark.length; i++)
            _buildLetter(_wordmark[i], t, 0.66 + i * 0.03),
        ],
      ),
    );
  }

  Widget _buildLetter(String letter, double t, double start) {
    final v = splashInterval(t, start, start + 0.16, Curves.easeOutBack);
    final opacity = splashInterval(t, start, start + 0.08);
    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.translationValues(-70 * (1 - v), 0, 0)
          ..multiply(Matrix4.skewX(-0.45 * (1 - v))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Text(
            letter,
            style: GoogleFonts.poppins(
              fontSize: 58,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.15,
              shadows: [
                Shadow(
                  color: Colors.white.withValues(alpha: 0.55),
                  blurRadius: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagline(double t) {
    final v = splashInterval(t, 0.86, 1.0, Curves.easeOutCubic);
    return Opacity(
      opacity: v,
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - v)),
        child: Text(
          'Twoja droga. Twoje zasady.',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: AppTheme.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Night city map: dim streets with a little traffic, and a red navigation
/// route that drives across the city and ends at the logo tile.
class _CityMapPainter extends CustomPainter {
  _CityMapPainter({
    required this.progress,
    required this.exit,
    required this.destination,
    required this.tileSize,
  });

  final double progress;
  final double exit;
  final Offset destination;
  final double tileSize;

  static const _street = Color(0xFF3A1C24);
  static const _routeCore = Color(0xFFFF2D2D);

  static final List<_Car> _cars = List.generate(9, (i) {
    final rng = math.Random(i * 31 + 7);
    return _Car(
      street: rng.nextInt(8),
      offset: rng.nextDouble(),
      speed: 0.12 + rng.nextDouble() * 0.18,
      direction: rng.nextBool() ? 1 : -1,
    );
  });

  /// Main streets as (start, end) pairs; the route runs along some of them.
  List<(Offset, Offset)> _mainStreets(Size size) {
    final w = size.width;
    final h = size.height;
    return [
      (Offset(w * 0.08, 0), Offset(w * 0.08, h)),
      (Offset(w * 0.80, 0), Offset(w * 0.80, h)),
      (Offset(w * 0.55, 0), Offset(w * 0.55, h)),
      (Offset(0, destination.dy), Offset(w, destination.dy)),
      (Offset(0, h * 0.86), Offset(w, h * 0.86)),
      (Offset(0, h * 0.14), Offset(w, h * 0.14)),
      (Offset(0, h * 0.34), Offset(w, h * 0.04)),
      (Offset(w * 0.2, h), Offset(w, h * 0.64)),
    ];
  }

  Path _route(Size size) {
    final w = size.width;
    final h = size.height;
    final points = [
      Offset(w * 0.80, h + 20),
      Offset(w * 0.80, h * 0.86),
      Offset(w * 0.08, h * 0.86),
      Offset(w * 0.08, destination.dy),
      destination,
    ];
    const radius = 22.0;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final corner = points[i];
      final inDir = _unit(corner - points[i - 1]);
      final outDir = _unit(points[i + 1] - corner);
      final before = corner - inDir * radius;
      final after = corner + outDir * radius;
      path
        ..lineTo(before.dx, before.dy)
        ..quadraticBezierTo(corner.dx, corner.dy, after.dx, after.dy);
    }
    return path..lineTo(points.last.dx, points.last.dy);
  }

  static Offset _unit(Offset o) => o / o.distance;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            destination.dx / size.width * 2 - 1,
            destination.dy / size.height * 2 - 1,
          ),
          radius: 0.9,
          colors: const [Color(0xFF1C0B10), AppTheme.bgDark],
        ).createShader(rect),
    );

    final mapOpacity = splashInterval(progress, 0.0, 0.12);
    if (mapOpacity <= 0) return;
    final streets = _mainStreets(size);
    _paintStreets(canvas, size, streets, mapOpacity);
    _paintTraffic(canvas, streets, mapOpacity);
    _paintRoute(canvas, size);
  }

  void _paintStreets(
    Canvas canvas,
    Size size,
    List<(Offset, Offset)> streets,
    double opacity,
  ) {
    final w = size.width;
    final h = size.height;
    final minor = Paint()
      ..color = _street.withValues(alpha: 0.5 * opacity)
      ..strokeWidth = 0.7;
    for (final x in [0.19, 0.31, 0.42, 0.68, 0.92]) {
      canvas.drawLine(Offset(w * x, 0), Offset(w * x, h), minor);
    }
    for (final y in [0.07, 0.24, 0.52, 0.62, 0.74, 0.95]) {
      canvas.drawLine(Offset(0, h * y), Offset(w, h * y), minor);
    }
    final major = Paint()
      ..color = _street.withValues(alpha: opacity)
      ..strokeWidth = 1.6;
    for (final (start, end) in streets) {
      canvas.drawLine(start, end, major);
    }
  }

  /// Cars as headlight + taillight pairs gliding along the main streets.
  void _paintTraffic(
    Canvas canvas,
    List<(Offset, Offset)> streets,
    double opacity,
  ) {
    final drive = progress * 3 + exit * 2;
    final head = Paint()
      ..color = Colors.white.withValues(alpha: 0.7 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final tail = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.8 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (final car in _cars) {
      final (start, end) = streets[car.street];
      final s = (car.offset + car.direction * car.speed * drive) % 1.0;
      final pos = Offset.lerp(start, end, s)!;
      final dir = _unit(end - start) * car.direction.toDouble();
      canvas.drawCircle(pos, 2.2, head);
      canvas.drawCircle(pos - dir * 9, 2.6, tail);
    }
  }

  void _paintRoute(Canvas canvas, Size size) {
    final drive = splashInterval(progress, 0.02, 0.32, Curves.easeInOutCubic);
    if (drive <= 0) return;
    final metric = _route(size).computeMetrics().first;
    final length = metric.length * drive;
    final travelled = metric.extractPath(0, length);
    final settled = 1 - 0.45 * splashInterval(progress, 0.34, 0.6);

    canvas.drawPath(
      travelled,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = AppTheme.primary.withValues(alpha: 0.45 * settled)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      travelled,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = _routeCore.withValues(alpha: settled),
    );

    // The car leading the route, with a headlight beam, until it parks
    // behind the tile.
    final carOpacity = 1 - splashInterval(progress, 0.29, 0.33);
    final tangent = metric.getTangentForOffset(length);
    if (carOpacity <= 0 || tangent == null) return;
    final pos = tangent.position;
    final dir = tangent.vector;
    final normal = Offset(-dir.dy, dir.dx);
    final beam = Path()
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(
        (pos + dir * 70 + normal * 22).dx,
        (pos + dir * 70 + normal * 22).dy,
      )
      ..lineTo(
        (pos + dir * 70 - normal * 22).dx,
        (pos + dir * 70 - normal * 22).dy,
      )
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.35 * carOpacity),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: pos, radius: 70)),
    );
    canvas.drawCircle(
      pos,
      16,
      Paint()
        ..color = AppTheme.primary.withValues(alpha: 0.7 * carOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      pos,
      4.5,
      Paint()..color = Colors.white.withValues(alpha: carOpacity),
    );
  }

  @override
  bool shouldRepaint(_CityMapPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.exit != exit ||
      oldDelegate.destination != destination;
}

class _Car {
  final int street;
  final double offset, speed;
  final int direction;
  const _Car({
    required this.street,
    required this.offset,
    required this.speed,
    required this.direction,
  });
}
