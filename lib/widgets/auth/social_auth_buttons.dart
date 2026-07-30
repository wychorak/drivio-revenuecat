import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/theme/app_theme.dart';

class SocialAuthButtons extends StatelessWidget {
  final bool enabled;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final String googleLabel;
  final String appleLabel;

  const SocialAuthButtons({
    super.key,
    required this.enabled,
    required this.onGoogle,
    required this.onApple,
    required this.googleLabel,
    required this.appleLabel,
  });

  bool get _showApple =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppTheme.dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'lub',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppTheme.dividerColor)),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: enabled ? onGoogle : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: AppTheme.dividerColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                'G',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4285F4),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            label: Text(
              googleLabel,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (_showApple) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: enabled ? onApple : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.apple, size: 25),
              label: Text(
                appleLabel,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
