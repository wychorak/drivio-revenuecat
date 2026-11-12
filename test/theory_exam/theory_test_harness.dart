import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/progress_repository.dart';
import 'package:drivio/features/theory_exam/question_bank.dart';
import 'package:drivio/providers/theory_ad_provider.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MemoryRepo implements TheoryProgressRepository {
  MemoryRepo([TheoryProgress? initial])
    : stored = initial ?? TheoryProgress.empty();
  TheoryProgress stored;
  @override
  Future<TheoryProgress> load() async => stored;
  @override
  Future<void> save(TheoryProgress progress) async => stored = progress;
}

/// Bank with enough questions for a full exam. Basic questions: correct
/// answer is TAK (index 0); specialist: A (index 0).
QuestionBank harnessBank({int perGroup = 12}) {
  final questions = <TheoryQuestion>[];
  var id = 1;
  for (final part in TheoryPart.values) {
    for (final points in [3, 2, 1]) {
      for (var i = 0; i < perGroup; i++) {
        questions.add(
          TheoryQuestion(
            id: id,
            text: 'Pytanie numer $id?',
            part: part,
            points: points,
            answers: part == TheoryPart.basic
                ? const ['TAK', 'NIE']
                : ['Odp A$id', 'Odp B$id', 'Odp C$id'],
            correctIndex: 0,
          ),
        );
        id++;
      }
    }
  }
  return QuestionBank(questions: questions, sourceVersion: '2026-07');
}

class Harness {
  Harness({QuestionBank? bank, TheoryProgress? progress})
    : bank = bank ?? harnessBank(),
      repo = MemoryRepo(progress);

  final QuestionBank bank;
  final MemoryRepo repo;
  DateTime now = DateTime(2026, 11, 13, 10);

  void advance(Duration d) => now = now.add(d);

  Widget app(String initialLocation, List<RouteBase> routes) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('start')),
        ...routes,
      ],
    );
    return ProviderScope(
      overrides: [
        theoryQuestionBankProvider.overrideWith((ref) async => bank),
        theoryProgressRepositoryProvider.overrideWithValue(repo),
        theoryClockProvider.overrideWithValue(() => now),
        theoryAdsPremiumProvider.overrideWithValue(true),
        isPremiumProvider.overrideWithValue(true),
        premiumStatusResolvedProvider.overrideWithValue(true),
        theoryInterstitialProvider.overrideWithValue(
          TheoryInterstitial(preload: () async {}, show: () async => false),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }
}
