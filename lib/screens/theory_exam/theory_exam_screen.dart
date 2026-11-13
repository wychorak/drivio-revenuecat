import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:drivio/features/theory_exam/exam_engine.dart';
import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/providers/theory_ad_provider.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:drivio/services/analytics_service.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/widgets/common/loading_widget.dart';
import 'package:drivio/widgets/theory_exam/answer_buttons.dart';
import 'package:drivio/widgets/theory_exam/question_card.dart';

String formatClock(Duration d) {
  final s = d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Full exam as in WORD: 32 questions, per-question time limits, no going
/// back, 25 minutes in total. No banner here: ads never sit next to a timer.
class TheoryExamScreen extends ConsumerStatefulWidget {
  const TheoryExamScreen({super.key});

  @override
  ConsumerState<TheoryExamScreen> createState() => _TheoryExamScreenState();
}

class _TheoryExamScreenState extends ConsumerState<TheoryExamScreen> {
  List<TheoryQuestion>? _questions;
  late List<int?> _answers;
  late ExamClock _clock;
  Timer? _ticker;
  int _index = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start(List<TheoryQuestion> questions) {
    _questions = questions;
    _answers = List<int?>.filled(questions.length, null);
    _clock = ExamClock(now: ref.read(theoryClockProvider));
    _clock.startQuestion(questions.first);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _finishing) return;
    if (_clock.timeUp) {
      _next();
    } else {
      setState(() {});
    }
  }

  void _next() {
    if (_finishing) return;
    final last = _index >= _questions!.length - 1;
    if (last || _clock.remainingTotal == Duration.zero) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _clock.startQuestion(_questions![_index]);
    });
  }

  Future<void> _finish() async {
    _finishing = true;
    _ticker?.cancel();
    final questions = _questions!;
    final score = scoreExam(questions, _answers);
    final record = ExamRecord(
      date: ref.read(theoryClockProvider)(),
      score: score,
      passed: isPassing(score),
      duration: _clock.elapsed > examTotalLimit
          ? examTotalLimit
          : _clock.elapsed,
      answers: [
        for (var i = 0; i < questions.length; i++)
          (questions[i].id, _answers[i]),
      ],
    );
    await ref.read(theoryProgressProvider.notifier).addExam(record);
    AnalyticsService.instance.theoryExamFinished(
      score: score,
      passed: record.passed,
    );
    await ref.read(theoryAdControllerProvider.notifier).onExamFinished();
    if (mounted) context.pushReplacement('/theory/exam/result', extra: record);
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Przerwać egzamin?'),
        content: const Text('Wynik nie zostanie zapisany.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Kontynuuj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Przerwij'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      _ticker?.cancel();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = ref.watch(theoryQuestionBankProvider);
    if (_questions == null && bank is AsyncData) {
      _start(generateExam(bank.requireValue, Random()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_finishing) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Przerwij egzamin',
            icon: const Icon(Icons.close_rounded),
            onPressed: _confirmLeave,
          ),
          title: _questions == null
              ? const Text('Egzamin')
              : Text(formatClock(_clock.remainingTotal)),
        ),
        body: switch (bank) {
          AsyncError() => const Center(
            child: Text('Nie udało się wczytać pytań.'),
          ),
          _ when _questions == null => const LoadingWidget(),
          _ => _body(),
        },
      ),
    );
  }

  Widget _body() {
    final question = _questions![_index];
    final phase = _clock.phase;
    final reading = phase == QuestionPhase.reading;
    final left = _clock.remainingInPhase;
    final total = _clock.phaseLength;
    final isLast = _index == _questions!.length - 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pytanie ${_index + 1}/${_questions!.length}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Text(
              '${question.points} pkt · '
              '${question.isBasic ? 'podstawowe' : 'specjalistyczne'}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                reading ? 'Czas na zapoznanie się' : 'Czas na odpowiedź',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: reading
                      ? AppTheme.textSecondary
                      : AppTheme.primaryBright,
                ),
              ),
            ),
            Text(
              '${left.inSeconds + (left.inMilliseconds % 1000 > 0 ? 1 : 0)} s',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total.inMilliseconds == 0
                ? 0
                : left.inMilliseconds / total.inMilliseconds,
            minHeight: 6,
            backgroundColor: AppTheme.bgElevated,
            color: reading ? AppTheme.routeBlue : AppTheme.primary,
          ),
        ),
        const SizedBox(height: 14),
        QuestionCard(question: question),
        const SizedBox(height: 18),
        if (reading) ...[
          OutlinedButton(
            onPressed: () => setState(_clock.skipReading),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Start – przejdź do odpowiedzi'),
          ),
          const SizedBox(height: 12),
        ],
        AnswerButtons(
          question: question,
          selected: _answers[_index],
          onSelect: (answer) => setState(() => _answers[_index] = answer),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _next,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            minimumSize: const Size.fromHeight(52),
          ),
          child: Text(isLast ? 'Zakończ' : 'Dalej'),
        ),
      ],
    );
  }
}
