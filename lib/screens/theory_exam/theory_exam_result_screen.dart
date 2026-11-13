import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:drivio/features/theory_exam/exam_engine.dart';
import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:drivio/screens/theory_exam/theory_exam_screen.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/widgets/ads/premium_aware_banner_ad.dart';

String answerLabel(TheoryQuestion q, int? answer) {
  if (answer == null) return 'brak odpowiedzi';
  return q.isBasic ? q.answers[answer] : 'ABC'[answer];
}

/// Score of a finished exam and a review of every question.
class TheoryExamResultScreen extends ConsumerStatefulWidget {
  const TheoryExamResultScreen({super.key, required this.record});

  final ExamRecord record;

  @override
  ConsumerState<TheoryExamResultScreen> createState() =>
      _TheoryExamResultScreenState();
}

class _TheoryExamResultScreenState
    extends ConsumerState<TheoryExamResultScreen> {
  bool _onlyMistakes = false;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final bank = ref.watch(theoryQuestionBankProvider).value;
    final color = record.passed ? AppTheme.successColor : AppTheme.errorColor;

    final items = <(int, TheoryQuestion, int?)>[
      if (bank != null)
        for (var i = 0; i < record.answers.length; i++)
          if (bank.tryById(record.answers[i].$1) case final q?)
            (i, q, record.answers[i].$2),
    ];
    final shown = _onlyMistakes
        ? items.where((e) => e.$3 != e.$2.correctIndex).toList()
        : items;

    return Scaffold(
      appBar: AppBar(title: const Text('Wynik egzaminu')),
      bottomNavigationBar: const PremiumAwareBannerAd(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 1.6),
            ),
            child: Column(
              children: [
                Icon(
                  record.passed
                      ? Icons.verified_rounded
                      : Icons.cancel_outlined,
                  color: color,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  '${record.score} / $examMaxScore',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  record.passed ? 'Egzamin zdany' : 'Egzamin niezdany',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Próg zdania: $examPassScore pkt · '
                  'czas: ${formatClock(record.duration)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => context.pushReplacement('/theory/exam'),
                  child: const Text('Nowy egzamin'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => context.pop(),
                  child: const Text('Wróć'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Wszystkie'),
                selected: !_onlyMistakes,
                onSelected: (_) => setState(() => _onlyMistakes = false),
              ),
              ChoiceChip(
                label: const Text('Tylko błędy'),
                selected: _onlyMistakes,
                onSelected: (_) => setState(() => _onlyMistakes = true),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final (index, question, answer) in shown)
            _ReviewTile(number: index + 1, question: question, answer: answer),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.number,
    required this.question,
    required this.answer,
  });

  final int number;
  final TheoryQuestion question;
  final int? answer;

  @override
  Widget build(BuildContext context) {
    final correct = answer == question.correctIndex;
    final color = correct ? AppTheme.successColor : AppTheme.errorColor;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: color,
        ),
        title: Text(
          '$number. ${question.text}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
        ),
        subtitle: Text(
          'Twoja odpowiedź: ${answerLabel(question, answer)}'
          '${correct ? '' : ' · poprawna: ${answerLabel(question, question.correctIndex)}'}'
          ' · ${question.points} pkt',
          style: GoogleFonts.poppins(fontSize: 12, color: color),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (question.image != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  question.image!,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          Text(
            question.text,
            style: GoogleFonts.poppins(color: AppTheme.textPrimary),
          ),
          if (!question.isBasic)
            for (var i = 0; i < question.answers.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${'ABC'[i]}. ${question.answers[i]}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: i == question.correctIndex
                        ? AppTheme.successColor
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
