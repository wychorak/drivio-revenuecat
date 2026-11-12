import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ExamRecord exam(int score, DateTime date) => ExamRecord(
  date: date,
  score: score,
  passed: score >= 68,
  duration: const Duration(minutes: 20),
  answers: const [(1, 0), (2, null)],
);

void main() {
  final t0 = DateTime(2026, 11, 13, 12);

  test('a wrong answer adds the question to mistakes', () {
    final p = TheoryProgress.empty().recordAnswer(5, false, t0);
    expect(p.mistakes, {5});
    expect(p.stats[5]!.attempts, 1);
    expect(p.stats[5]!.correct, 0);
    expect(p.seenCount, 1);
  });

  test('a correct answer removes the question from mistakes', () {
    final p = TheoryProgress.empty()
        .recordAnswer(5, false, t0)
        .recordAnswer(5, true, t0.add(const Duration(minutes: 1)));
    expect(p.mistakes, isEmpty);
    expect(p.stats[5]!.attempts, 2);
    expect(p.stats[5]!.correct, 1);
    expect(p.accuracy, 0.5);
  });

  test('exam history keeps the 30 newest exams, newest first', () {
    var p = TheoryProgress.empty();
    for (var i = 0; i < 31; i++) {
      p = p.addExam(exam(40 + i, t0.add(Duration(days: i))));
    }
    expect(p.exams, hasLength(30));
    expect(p.exams.first.score, 70);
    expect(p.exams.last.score, 41);
  });

  test('progress survives a save and load', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = SharedPrefsTheoryProgressRepository();
    final p = TheoryProgress.empty()
        .recordAnswer(3, false, t0)
        .addExam(exam(70, t0))
        .copyWith(learnCursor: 12);

    await repo.save(p);
    final loaded = await repo.load();

    expect(loaded.mistakes, {3});
    expect(loaded.learnCursor, 12);
    expect(loaded.exams.single.score, 70);
    expect(loaded.exams.single.passed, isTrue);
    expect(loaded.exams.single.answers, const [(1, 0), (2, null)]);
    expect(loaded.stats[3]!.lastAnswered, t0);
  });

  test('corrupted stored progress loads as empty progress', () async {
    SharedPreferences.setMockInitialValues({
      SharedPrefsTheoryProgressRepository.storageKey: '{not json',
    });
    final loaded = await SharedPrefsTheoryProgressRepository().load();
    expect(loaded.seenCount, 0);
    expect(loaded.exams, isEmpty);
  });
}
