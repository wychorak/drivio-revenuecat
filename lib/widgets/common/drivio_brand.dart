import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/theme/app_theme.dart';

class DrivioBackdrop extends StatelessWidget {
  final Widget child;

  const DrivioBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.75, -0.85),
          radius: 1.25,
          colors: [Color(0xFF26060C), AppTheme.bgDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 80,
            right: -90,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.routeBlue.withAlpha(9),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.routeBlue.withAlpha(14),
                      blurRadius: 70,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withAlpha(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(14),
                      blurRadius: 80,
                      spreadRadius: 36,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class DrivioBrandMark extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool compact;

  const DrivioBrandMark({
    super.key,
    this.size = 68,
    this.showWordmark = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .31),
        gradient: AppTheme.brandGradient,
        border: Border.all(color: Colors.white.withAlpha(26)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(72),
            blurRadius: size * .42,
            offset: Offset(0, size * .14),
          ),
        ],
      ),
      child: Icon(
        Icons.directions_car_rounded,
        color: Colors.white,
        size: size * .49,
      ),
    );

    if (!showWordmark) return mark;

    final wordmark = Text(
      'drivio',
      style: GoogleFonts.poppins(
        color: AppTheme.primaryBright,
        fontSize: compact ? 23 : 29,
        fontWeight: FontWeight.w800,
        letterSpacing: compact ? 1.6 : 2.3,
        height: 1,
      ),
    );

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [mark, const SizedBox(width: 12), wordmark],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [mark, const SizedBox(height: 13), wordmark],
    );
  }
}
