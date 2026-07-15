import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/theme/app_theme.dart';

class DifficultyStars extends StatelessWidget {
  final int difficulty;
  final bool editable;
  final ValueChanged<int>? onChanged;
  final double size;
  final bool showLabel;

  const DifficultyStars({
    super.key,
    required this.difficulty,
    this.editable = false,
    this.onChanged,
    this.size = 20,
    this.showLabel = true,
  });

  String get _label {
    switch (difficulty) {
      case 1:
        return 'Bardzo łatwa';
      case 2:
        return 'Łatwa';
      case 3:
        return 'Średnia';
      case 4:
        return 'Trudna';
      case 5:
        return 'Bardzo trudna';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final star = i + 1;
          final filled = star <= difficulty;
          return GestureDetector(
            onTap: editable && onChanged != null
                ? () => onChanged!(star)
                : null,
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: filled ? AppTheme.primary : AppTheme.textSecondary,
                size: size,
              ),
            ),
          );
        }),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            _label,
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
