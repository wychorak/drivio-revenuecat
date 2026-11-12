import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/theme/app_theme.dart';

/// TAK/NIE buttons for basic questions, A/B/C for specialist ones.
///
/// With [reveal] the correct answer turns green and a wrong choice red.
class AnswerButtons extends StatelessWidget {
  const AnswerButtons({
    super.key,
    required this.question,
    this.selected,
    this.reveal = false,
    this.onSelect,
  });

  final TheoryQuestion question;
  final int? selected;
  final bool reveal;
  final ValueChanged<int>? onSelect;

  static const _letters = ['A', 'B', 'C'];

  Color _border(int i) {
    if (reveal && i == question.correctIndex) return AppTheme.successColor;
    if (reveal && i == selected) return AppTheme.errorColor;
    if (i == selected) return AppTheme.primaryBright;
    return AppTheme.dividerColor;
  }

  Color _fill(int i) {
    if (reveal && i == question.correctIndex) {
      return AppTheme.successColor.withAlpha(40);
    }
    if (reveal && i == selected) return AppTheme.errorColor.withAlpha(40);
    if (i == selected) return AppTheme.primary.withAlpha(45);
    return AppTheme.bgCard;
  }

  Widget _button(int i, Widget child) => Material(
    key: Key('answer-$i'),
    color: _fill(i),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: _border(i), width: 1.6),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onSelect == null ? null : () => onSelect!(i),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (question.isBasic) {
      return Row(
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _button(
                i,
                SizedBox(
                  height: 58,
                  child: Center(
                    child: Text(
                      question.answers[i],
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < question.answers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _button(
              i,
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_letters[i]}.',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBright,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question.answers[i],
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
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
