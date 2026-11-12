import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/question_bank.dart';
import 'package:drivio/providers/theory_ad_provider.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/widgets/ads/premium_aware_banner_ad.dart';
import 'package:drivio/widgets/common/loading_widget.dart';
import 'package:drivio/widgets/theory_exam/answer_buttons.dart';
import 'package:drivio/widgets/theory_exam/question_card.dart';

/// Untimed practice: random questions, learning in catalogue order with
/// filters, or a review of questions last answered wrong. Every answer is
/// checked at once.
class TheoryPracticeScreen extends ConsumerStatefulWidget {
  const TheoryPracticeScreen({super.key, required this.mode});

  final PracticeMode mode;

  @override
  ConsumerState<TheoryPracticeScreen> createState() =>
      _TheoryPracticeScreenState();
}

class _TheoryPracticeScreenState extends ConsumerState<TheoryPracticeScreen> {
  final _rng = Random();
  List<TheoryQuestion>? _queue;
  int _index = 0;
  int? _selected;
  int _answered = 0;
  int _correct = 0;
  bool _advancing = false;
  PracticeFilter _filter = const PracticeFilter();

  String get _title => switch (widget.mode) {
    PracticeMode.random => 'Losuj pytanie',
    PracticeMode.learn => 'Nauka',
    PracticeMode.mistakes => 'Powtórka błędów',
  };

  void _buildQueue(QuestionBank bank, TheoryProgress progress) {
    final queue = practiceQueue(bank, progress, widget.mode, _filter, _rng);
    var start = 0;
    if (widget.mode == PracticeMode.learn && progress.learnCursor > 0) {
      // Resume after the last question answered in learning mode.
      start = queue.indexWhere((q) => q.id > progress.learnCursor);
      if (start < 0) start = 0;
    }
    _queue = queue;
    _index = start;
    _selected = null;
  }

  Future<void> _select(int answer) async {
    if (_selected != null) return;
    final question = _queue![_index];
    final correct = answer == question.correctIndex;
    setState(() {
      _selected = answer;
      _answered++;
      if (correct) _correct++;
    });
    final progress = ref.read(theoryProgressProvider.notifier);
    await progress.recordAnswer(question.id, correct);
    if (widget.mode == PracticeMode.learn) {
      await progress.setLearnCursor(question.id);
    }
  }

  Future<void> _next() async {
    if (_advancing) return;
    _advancing = true;
    // A natural break: the ad controller decides whether an ad fits here.
    await ref.read(theoryAdControllerProvider.notifier).onAnswer();
    if (!mounted) return;
    setState(() {
      _advancing = false;
      _selected = null;
      _index++;
      if (widget.mode == PracticeMode.random && _index >= _queue!.length) {
        _queue!.shuffle(_rng);
        _index = 0;
      }
    });
  }

  Future<void> _editFilter(QuestionBank bank) async {
    final filter = await showModalBottomSheet<PracticeFilter>(
      context: context,
      backgroundColor: AppTheme.bgCard,
      builder: (_) => _FilterSheet(initial: _filter),
    );
    if (filter == null || !mounted) return;
    setState(() {
      _filter = filter;
      _buildQueue(bank, ref.read(theoryProgressProvider).requireValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bank = ref.watch(theoryQuestionBankProvider);
    final progress = ref.watch(theoryProgressProvider);

    if (bank is AsyncData<QuestionBank> &&
        progress is AsyncData<TheoryProgress> &&
        _queue == null) {
      _buildQueue(bank.value, progress.value);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (widget.mode == PracticeMode.learn && bank.hasValue)
            IconButton(
              tooltip: 'Filtry',
              icon: Icon(
                _filter.isEmpty
                    ? Icons.filter_list_rounded
                    : Icons.filter_alt_rounded,
              ),
              onPressed: () => _editFilter(bank.requireValue),
            ),
        ],
      ),
      bottomNavigationBar: const PremiumAwareBannerAd(),
      body: _body(),
    );
  }

  Widget _body() {
    final queue = _queue;
    if (queue == null) return const LoadingWidget();
    if (queue.isEmpty) {
      return _Message(
        icon: widget.mode == PracticeMode.mistakes
            ? Icons.celebration_rounded
            : Icons.search_off_rounded,
        title: widget.mode == PracticeMode.mistakes
            ? 'Brak błędów do powtórki'
            : 'Brak pytań dla tych filtrów',
      );
    }
    if (_index >= queue.length) {
      return _Message(
        icon: Icons.flag_rounded,
        title: 'Koniec!',
        subtitle: 'Dobre odpowiedzi: $_correct z $_answered',
      );
    }

    final question = queue[_index];
    final answered = _selected != null;
    final correct = _selected == question.correctIndex;
    final position = widget.mode == PracticeMode.random
        ? 'Odpowiedzi: $_answered · dobrze: $_correct'
        : 'Pytanie ${_index + 1} z ${queue.length}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                position,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            _PointsChip(points: question.points),
          ],
        ),
        const SizedBox(height: 12),
        QuestionCard(question: question),
        const SizedBox(height: 18),
        AnswerButtons(
          question: question,
          selected: _selected,
          reveal: answered,
          onSelect: answered ? null : _select,
        ),
        if (answered) ...[
          const SizedBox(height: 14),
          Text(
            correct
                ? 'Dobrze!'
                : 'Źle. Poprawna odpowiedź: '
                      '${question.isBasic ? question.answers[question.correctIndex] : 'ABC'[question.correctIndex]}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: correct ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _next,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Dalej'),
          ),
        ],
      ],
    );
  }
}

class _PointsChip extends StatelessWidget {
  const _PointsChip({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppTheme.bgElevated,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$points pkt',
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppTheme.primaryBright),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Wróć'),
          ),
        ],
      ),
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final PracticeFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TheoryPart? _part = widget.initial.part;
  late int? _points = widget.initial.points;
  late bool _onlyUnseen = widget.initial.onlyUnseen;

  Widget _chips<T>(String label, List<(String, T?)> options, T? value,
      ValueChanged<T?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final (text, option) in options)
              ChoiceChip(
                label: Text(text),
                selected: value == option,
                onSelected: (_) => onChanged(option),
              ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _chips<TheoryPart>(
              'Część egzaminu',
              const [
                ('Wszystkie', null),
                ('Podstawowe', TheoryPart.basic),
                ('Specjalistyczne', TheoryPart.specialist),
              ],
              _part,
              (v) => setState(() => _part = v),
            ),
            _chips<int>(
              'Punkty',
              const [('Wszystkie', null), ('3', 3), ('2', 2), ('1', 1)],
              _points,
              (v) => setState(() => _points = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tylko nowe pytania'),
              value: _onlyUnseen,
              onChanged: (v) => setState(() => _onlyUnseen = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () => Navigator.of(context).pop(
                PracticeFilter(
                  part: _part,
                  points: _points,
                  onlyUnseen: _onlyUnseen,
                ),
              ),
              child: const Text('Pokaż pytania'),
            ),
          ],
        ),
      ),
    );
  }
}
