import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Eased progress of [t] inside the [begin]..[end] window of a timeline.
double splashInterval(
  double t,
  double begin,
  double end, [
  Curve curve = Curves.linear,
]) {
  final local = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
  return curve.transform(local);
}

/// Draws the Drivio logo (steering wheel + location pin) as vectors and
/// choreographs its intro: a rev-counter needle sweeps the rim in over a
/// tachometer scale, the wheel fills, the spokes wipe out from the hub, the
/// wheel steers into a bend and settles, then the pin drops in like an
/// arrival marker, squashes on landing and sends out GPS pings.
///
/// [progress] runs 0..1 over the whole intro; 1 is the finished logo.
class DrivioLogoPainter extends CustomPainter {
  const DrivioLogoPainter({required this.progress});

  final double progress;

  /// Logo bounds in units of the 1024px source artwork.
  static const double logoWidth = 760;
  static const double logoHeight = 710;

  static const Color blue = Color(0xFF063E95);
  static const Color red = Color(0xFFCA0107);

  static const Offset _pinHead = Offset(0, -85);
  static const Offset _pinTip = Offset(0, 143);
  static final Rect _outer = Rect.fromCenter(
    center: Offset.zero,
    width: 756,
    height: 704,
  );
  static final Path _window = _buildWindow();
  static final Path _rim = Path()
    ..fillType = PathFillType.evenOdd
    ..addOval(_outer)
    ..addPath(_window, Offset.zero);
  static final Path _spokes = _buildSpokes();
  static final Path _pin = _buildPin();

  static Path _buildWindow() {
    return Path()
      ..moveTo(-290, 0)
      ..arcTo(
        Rect.fromCenter(center: Offset.zero, width: 580, height: 560),
        math.pi,
        math.pi,
        false,
      )
      ..arcTo(
        Rect.fromCenter(center: Offset.zero, width: 580, height: 524),
        0,
        math.pi,
        false,
      )
      ..close();
  }

  static Path _buildSpokes() {
    return Path()
      ..moveTo(-300, -60)
      ..cubicTo(-240, -62, -185, -68, -150, -80)
      ..lineTo(150, -80)
      ..cubicTo(185, -68, 240, -62, 300, -60)
      ..lineTo(300, 55)
      ..lineTo(235, 55)
      ..cubicTo(140, 62, 72, 140, 70, 250)
      ..lineTo(70, 290)
      ..lineTo(-70, 290)
      ..lineTo(-70, 250)
      ..cubicTo(-72, 140, -140, 62, -235, 55)
      ..lineTo(-300, 55)
      ..close();
  }

  static Path _buildPin() {
    return Path()
      ..moveTo(_pinTip.dx, _pinTip.dy)
      ..cubicTo(-40, 105, -91.9, 12.1, -110.1, -55.5)
      ..arcTo(
        Rect.fromCircle(center: _pinHead, radius: 114),
        165 * math.pi / 180,
        210 * math.pi / 180,
        false,
      )
      ..cubicTo(91.9, 12.1, 40, 105, _pinTip.dx, _pinTip.dy)
      ..close();
  }

  double get _rimSweep =>
      splashInterval(progress, 0.0, 0.30, Curves.easeInOutCubic);
  double get _fill => splashInterval(progress, 0.14, 0.34, Curves.easeOutCubic);
  double get _spokesWipe =>
      splashInterval(progress, 0.22, 0.42, Curves.easeOutCubic);
  double get _smile =>
      splashInterval(progress, 0.30, 0.48, Curves.easeInOutCubic);
  double get _ripple => splashInterval(progress, 0.68, 1.0);
  double get _dot => splashInterval(progress, 0.70, 0.84, Curves.elasticOut);
  double get _pinOpacity => splashInterval(progress, 0.54, 0.60);

  /// Steering angle in radians: a quick turn left, a small counter-steer,
  /// then straight. Shared with the road so it bends with the wheel.
  static double steeringAt(double progress) {
    final p = splashInterval(progress, 0.38, 0.66);
    return -0.42 * math.sin(2.5 * math.pi * p) * math.pow(1 - p, 2);
  }

  double get _turn => steeringAt(progress);

  /// Pin falls for the first 40% of its window, then squashes and wobbles.
  ({double drop, double squash}) get _pinMotion {
    final p = splashInterval(progress, 0.54, 0.74);
    if (p < 0.4) {
      final f = p / 0.4;
      return (drop: -650 * (1 - f * f), squash: -0.12 * f);
    }
    final q = (p - 0.4) / 0.6;
    return (
      drop: 0,
      squash: 0.28 * math.exp(-4 * q) * math.cos(3.5 * math.pi * q),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / logoWidth);

    _paintRipples(canvas);

    _paintGauge(canvas);

    canvas.save();
    canvas.rotate(_turn);
    _paintFill(canvas);
    _paintSpokes(canvas);
    _paintRim(canvas);
    _paintSmile(canvas);
    _paintNeedle(canvas);
    canvas.restore();

    _paintPin(canvas);
    canvas.restore();
  }

  void _paintRipples(Canvas canvas) {
    for (var i = 0; i < 2; i++) {
      final p = ((_ripple - i * 0.3) / 0.7).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;
      final grow = 1 + 0.55 * Curves.easeOutCubic.transform(p);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: _outer.width * grow,
          height: _outer.height * grow,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + 10 * (1 - p)
          ..color = red.withValues(alpha: 0.55 * (1 - p)),
      );
    }
  }

  void _paintFill(Canvas canvas) {
    final fill = _fill;
    if (fill <= 0) return;
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 400 * fill)),
    );
    canvas.drawPath(_window, Paint()..color = Colors.white);
    canvas.restore();
  }

  void _paintSpokes(Canvas canvas) {
    final wipe = _spokesWipe;
    if (wipe <= 0) return;
    canvas.save();
    canvas.clipPath(_window);
    canvas.clipPath(
      Path()..addOval(
        Rect.fromCircle(center: const Offset(0, -20), radius: 420 * wipe),
      ),
    );
    canvas.drawPath(_spokes, Paint()..color = blue);
    canvas.restore();
  }

  void _paintRim(Canvas canvas) {
    final sweep = _rimSweep;
    if (sweep <= 0) return;
    final paint = Paint()..color = blue;
    if (sweep >= 1) {
      canvas.drawPath(_rim, paint);
      return;
    }

    final angle = 2 * math.pi * sweep;
    canvas.save();
    canvas.clipPath(
      Path()
        ..moveTo(0, 0)
        ..arcTo(
          Rect.fromCircle(center: Offset.zero, radius: 500),
          -math.pi / 2,
          angle,
          false,
        )
        ..close(),
    );
    canvas.drawPath(_rim, paint);
    canvas.restore();

    // Glowing "headlight" leading the rim as it is drawn.
    final head = -math.pi / 2 + angle;
    canvas.drawCircle(
      Offset(334 * math.cos(head), 316 * math.sin(head)),
      60,
      Paint()
        ..color = const Color(
          0xFF6FA8FF,
        ).withValues(alpha: 0.8 * math.sin(math.pi * sweep))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
  }

  /// Tachometer ticks around the wheel; each lights up as the needle passes
  /// and the last stretch is the red line. The scale fades once revved.
  void _paintGauge(Canvas canvas) {
    final visible =
        splashInterval(progress, 0.0, 0.08) *
        (1 - splashInterval(progress, 0.36, 0.52, Curves.easeIn));
    if (visible <= 0) return;
    const ticks = 48;
    final sweep = _rimSweep;
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < ticks; i++) {
      final f = i / ticks;
      final angle = -math.pi / 2 + 2 * math.pi * f;
      final major = i % 4 == 0;
      final lit = f <= sweep;
      final redLine = f >= 0.8;
      final dir = Offset(math.cos(angle), math.sin(angle));
      const radii = Offset(410, 382);
      final outer = Offset(dir.dx * radii.dx, dir.dy * radii.dy);
      final inner = outer - dir * (major ? 34 : 18);
      final base = redLine ? red : blue;
      paint
        ..strokeWidth = major ? 9 : 5
        ..color = base.withValues(alpha: visible * (lit ? 0.95 : 0.18));
      canvas.drawLine(inner, outer, paint);
    }
  }

  /// Rev-counter needle that sweeps with the rim and fades as it finishes.
  void _paintNeedle(Canvas canvas) {
    final sweep = _rimSweep;
    if (sweep <= 0 || sweep >= 1) return;
    final angle = -math.pi / 2 + 2 * math.pi * sweep;
    final tip = Offset(300 * math.cos(angle), 280 * math.sin(angle));
    final alpha = math.sin(math.pi * sweep);
    canvas.drawLine(
      Offset.zero,
      tip,
      Paint()
        ..color = red.withValues(alpha: alpha)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset.zero,
      26,
      Paint()..color = blue.withValues(alpha: alpha),
    );
  }

  void _paintSmile(Canvas canvas) {
    final smile = _smile;
    if (smile <= 0) return;
    const halfSpan = 67 * math.pi / 180;
    canvas.drawArc(
      Rect.fromCenter(center: Offset.zero, width: 628, height: 578),
      math.pi / 2 - halfSpan * smile,
      2 * halfSpan * smile,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintPin(Canvas canvas) {
    final opacity = _pinOpacity;
    if (opacity <= 0) return;
    final motion = _pinMotion;

    canvas.save();
    canvas.translate(0, motion.drop);
    // Squash and stretch around the tip, where the pin "lands".
    canvas.translate(_pinTip.dx, _pinTip.dy);
    canvas.scale(1 + motion.squash * 0.6, 1 - motion.squash);
    canvas.translate(-_pinTip.dx, -_pinTip.dy);

    canvas.drawPath(
      _pin,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 44
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(_pin, Paint()..color = red.withValues(alpha: opacity));
    final dot = _dot;
    if (dot > 0) {
      canvas.drawCircle(
        _pinHead,
        44 * dot,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DrivioLogoPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
