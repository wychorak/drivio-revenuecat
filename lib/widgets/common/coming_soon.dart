import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/theme/app_theme.dart';

/// Placeholder for a section that is not available yet.
class ComingSoon extends StatelessWidget {
  const ComingSoon({
    super.key,
    this.icon = Icons.school_rounded,
    this.message = 'Szkoły jazdy pojawią się w Drivio już wkrótce.',
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(22),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 38),
            ),
            const SizedBox(height: 18),
            Text(
              'Coming soon',
              style: GoogleFonts.poppins(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: colors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
