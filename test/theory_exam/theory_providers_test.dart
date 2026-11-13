import 'dart:math';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/progress_repository.dart';
import 'package:drivio/features/theory_exam/question_bank.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryRepo implements TheoryProgressRepository {
  TheoryProgress stored = TheoryProgress.empty();
  int saves = 0;
  @override
  Future<TheoryProgress> load() async => stored;
  @override
  Future<void> save(TheoryProgress progress) async {
    saves++;
    stored = progress;
  }
}

TheoryQuestion question(int id, TheoryPart part, int points) => TheoryQuestion(
  id: id,
  text: 'Q$id',
  part: part,
  points: points,
  answers: const ['TAK', 'NIE'],
  correctIndex: 0,
);

final bank = QuestionBank(
  sourceVersion: 'test',
  questions: [
    question(4, TheoryPart.basic, 3),
    question(1, TheoryPart.basic, 1),
    question(3, TheoryPart.specialist, 3),
    question(2, TheoryPart.specialist, 2),
  ],
);

void main() {
  final t0 = DateTime(2026, 11, 13);

  test('random mode returns every question once', () {
    final queue = practiceQueue(
      bank,
      TheoryProgress.empty(),
      PracticeMode.random,
      const PracticeFilter(),
      Random(3),
    );
    expect(queue.map((q) => q.id).toSet(), {1, 2, 3, 4});
  });

  test('learn mode filters by part and points, sorted by id', () {
    List<int> ids(PracticeFilter f) => practiceQueue(
      bank,
      TheoryProgress.empty(),
      PracticeMode.learn,
      f,
      Random(1),
    ).map((q) => q.id).toList();

    expect(ids(const PracticeFilter()), [1, 2, 3, 4]);
    expect(ids(const PracticeFilter(part: TheoryPart.specialist)), [2, 3]);
    expect(ids(const PracticeFilter(points: 3)), [3, 4]);
  });

  test('learn mode can skip questions already answered', () {
    final progress = TheoryProgress.empty().recordAnswer(1, true, t0);
    final queue = practiceQueue(
      bank,
      progress,
      PracticeMode.learn,
      const PracticeFilter(onlyUnseen: true),
      Random(1),
    );
    expect(queue.map((q) => q.id), [2, 3, 4]);
  });

  test('mistakes mode returns only the last-wrong questions', () {
    final progress = TheoryProgress.empty()
        .recordAnswer(3, false, t0)
        .recordAnswer(1, true, t0);
    final queue = practiceQueue(
      bank,
      progress,
      PracticeMode.mistakes,
      const PracticeFilter(),
      Random(1),
    );
    expect(queue.map((q) => q.id), [3]);
    expect(
      practiceQueue(
        bank,
        TheoryProgress.empty(),
        PracticeMode.mistakes,
        const PracticeFilter(),
        Random(1),
      ),
      isEmpty,
    );
  });

  test('notifier persists answers and finished exams only', () async {
    final repo = MemoryRepo();
    final container = ProviderContainer(
      overrides: [
        theoryProgressRepositoryProvider.overrideWithValue(repo),
        theoryClockProvider.overrideWithValue(() => t0),
      ],
    );
    addTearDown(container.dispose);

    await container.read(theoryProgressProvider.future);
    final notifier = container.read(theoryProgressProvider.notifier);
    await notifier.recordAnswer(4, false);
    expect(repo.stored.mistakes, {4});
    expect(repo.stored.stats[4]!.lastAnswered, t0);
    expect(repo.stored.exams, isEmpty);

    await notifier.addExam(
      ExamRecord(
        date: t0,
        score: 70,
        passed: true,
        duration: const Duration(minutes: 9),
        answers: const [(4, 0)],
      ),
    );
    expect(repo.stored.exams.single.score, 70);

    await notifier.setLearnCursor(2);
    expect(container.read(theoryProgressProvider).value!.learnCursor, 2);
    expect(repo.stored.learnCursor, 2);
  });
}
