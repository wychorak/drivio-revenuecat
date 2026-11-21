import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:drivio/features/theory_exam/exam_engine.dart';
import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/question_bank.dart';
import 'package:drivio/providers/theory_ad_provider.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:drivio/services/analytics_service.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/widgets/common/loading_widget.dart';
import 'package:drivio/widgets/theory_exam/answer_buttons.dart';
import 'package:drivio/widgets/theory_exam/question_card.dart';
import 'package:drivio/widgets/theory_exam/question_video.dart';

String formatClock(Duration d) {
  final s = d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Full exam as in WORD: 32 questions, per-question time limits, no going
/// back, 25 minutes in total. No banner here: ads never sit next to a timer.
///
/// Before the clock starts, every film of the drawn questions is put on the
/// device, so the exam itself never waits for the network. Offline, the
/// learner can take an exam drawn from film-free questions instead.
class TheoryExamScreen extends ConsumerStatefulWidget {
  const TheoryExamScreen({super.key});

  @override
  ConsumerState<TheoryExamScreen> createState() => _TheoryExamScreenState();
}

class _TheoryExamScreenState extends ConsumerState<TheoryExamScreen> {
  /// Drawn exam whose films are being downloaded.
  List<TheoryQuestion>? _drawn;
  double _prepareProgress = 0;
  bool _prepareFailed = false;
  StreamSubscription<double>? _preparing;
  bool _withoutVideo = false;
  final _videoFiles = <int, File>{};

  List<TheoryQuestion>? _questions;
  late List<int?> _answers;
  late ExamClock _clock;
  Timer? _ticker;
  int _index = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _ticker?.cancel();
    _preparing?.cancel();
    super.dispose();
  }

  void _draw(QuestionBank bank) {
    _drawn = generateExam(bank, Random());
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  void _prepare() {
    final drawn = _drawn!;
    final store = ref.read(theoryVideoCacheProvider);
    setState(() {
      _prepareFailed = false;
      _prepareProgress = 0;
    });
    _preparing?.cancel();
    _preparing = store
        .prepare(drawn)
        .listen(
          (p) {
            if (mounted) setState(() => _prepareProgress = p);
          },
          onError: (Object error) {
            debugPrint('Theory exam films failed: $error');
            if (mounted) setState(() => _prepareFailed = true);
          },
          onDone: () async {
            if (_prepareFailed || !mounted) return;
            for (final q in drawn.where((q) => q.hasVideo)) {
              final file = await store.localFile(q);
              if (file != null) _videoFiles[q.id] = file;
            }
            // The learner may have left while the files were looked up.
            if (!mounted) return;
            ref.invalidate(theoryVideoCacheSizeProvider);
            setState(() => _start(drawn));
          },
          cancelOnError: true,
        );
  }

  void _startWithoutVideo() {
    _preparing?.cancel();
    final bank = ref.read(theoryQuestionBankProvider).requireValue;
    setState(() {
      _withoutVideo = true;
      _start(generateExam(bank, Random(), withoutVideo: true));
    });
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
      withoutVideo: _withoutVideo,
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
    if (_drawn == null && bank is AsyncData<QuestionBank>) _draw(bank.value);

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
          _ when _drawn == null => const LoadingWidget(),
          _ when _questions == null => _preparationView(),
          _ => _body(),
        },
      ),
    );
  }

  Widget _preparationView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _prepareFailed
            ? [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nie udało się pobrać filmów do egzaminu.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sprawdź internet albo zrób egzamin złożony z pytań '
                  'bez filmów.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _prepare,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Spróbuj ponownie'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _startWithoutVideo,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Egzamin bez filmów'),
                ),
              ]
            : [
                Text(
                  'Przygotowuję egzamin…',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pobieram filmy do pytań. Każdy film pobiera się tylko raz.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _prepareProgress,
                    minHeight: 8,
                    backgroundColor: AppTheme.bgElevated,
                    color: AppTheme.primary,
                  ),
                ),
              ],
      ),
    ),
  );

  Widget? _media(TheoryQuestion question, QuestionPhase phase) {
    if (!question.hasVideo) return null;
    final file = _videoFiles[question.id];
    if (file == null) {
      // Removed from the device mid-exam: the clock's 3 s start timeout
      // moves on to the answer time.
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Icon(
            Icons.videocam_off_outlined,
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }
    return QuestionVideo(
      key: ValueKey('exam-video-$_index'),
      file: file,
      play: phase != QuestionPhase.reading,
      controls: false,
      onStarted: (length) => setState(() => _clock.startVideo(length)),
      onEnded: () => setState(_clock.videoEnded),
      onFailed: () => setState(_clock.videoFailed),
    );
  }

  Widget _body() {
    final question = _questions![_index];
    final phase = _clock.phase;
    final reading = phase == QuestionPhase.reading;
    final film = phase == QuestionPhase.video;
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
                reading
                    ? 'Czas na zapoznanie się'
                    : film
                    ? 'Odtwarzanie filmu'
                    : 'Czas na odpowiedź',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: reading || film
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
            color: reading || film ? AppTheme.routeBlue : AppTheme.primary,
          ),
        ),
        const SizedBox(height: 14),
        QuestionCard(question: question, media: _media(question, phase)),
        const SizedBox(height: 18),
        if (reading) ...[
          OutlinedButton(
            onPressed: () => setState(_clock.skipReading),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(
              question.hasVideo
                  ? 'Start – odtwórz film'
                  : 'Start – przejdź do odpowiedzi',
            ),
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
