import 'dart:math';

import 'package:drivio/features/theory_exam/exam_engine.dart';
import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

QuestionBank fakeBank({int perGroup = 15}) {
  final questions = <TheoryQuestion>[];
  var id = 1;
  for (final part in TheoryPart.values) {
    for (final points in [1, 2, 3]) {
      for (var i = 0; i < perGroup; i++) {
        questions.add(
          TheoryQuestion(
            id: id++,
            text: 'Q$id',
            part: part,
            points: points,
            answers: part == TheoryPart.basic
                ? const ['TAK', 'NIE']
                : const ['a', 'b', 'c'],
            correctIndex: 0,
          ),
        );
      }
    }
  }
  return QuestionBank(questions: questions, sourceVersion: 'test');
}

TheoryQuestion q(TheoryPart part) => TheoryQuestion(
  id: 1,
  text: 'x',
  part: part,
  points: 3,
  answers: const ['TAK', 'NIE'],
  correctIndex: 0,
);

void main() {
  group('generateExam', () {
    test('draws 10/6/4 basic then 6/4/2 specialist without repeats', () {
      final bank = fakeBank();
      for (var seed = 0; seed < 100; seed++) {
        final exam = generateExam(bank, Random(seed));
        expect(exam, hasLength(32));
        expect(exam.map((q) => q.id).toSet(), hasLength(32));

        final basic = exam.take(20).toList();
        final specialist = exam.skip(20).toList();
        expect(basic.every((q) => q.part == TheoryPart.basic), isTrue);
        expect(
          specialist.every((q) => q.part == TheoryPart.specialist),
          isTrue,
        );
        int count(List<TheoryQuestion> l, int p) =>
            l.where((q) => q.points == p).length;
        expect([count(basic, 3), count(basic, 2), count(basic, 1)], [
          10,
          6,
          4,
        ]);
        expect([
          count(specialist, 3),
          count(specialist, 2),
          count(specialist, 1),
        ], [6, 4, 2]);
      }
    });

    test('same seed gives the same exam', () {
      final bank = fakeBank();
      expect(
        generateExam(bank, Random(4)).map((q) => q.id),
        generateExam(bank, Random(4)).map((q) => q.id),
      );
    });

    test('a bank too small for the blueprint throws', () {
      expect(
        () => generateExam(fakeBank(perGroup: 5), Random(1)),
        throwsStateError,
      );
    });
  });

  group('scoreExam', () {
    test('all correct gives 74 and passes', () {
      final exam = generateExam(fakeBank(), Random(1));
      final score = scoreExam(exam, List.filled(32, 0));
      expect(score, examMaxScore);
      expect(examMaxScore, 74);
      expect(isPassing(score), isTrue);
    });

    test('no answer scores 0', () {
      final exam = generateExam(fakeBank(), Random(1));
      expect(scoreExam(exam, List.filled(32, null)), 0);
    });

    test('68 passes, 67 fails', () {
      expect(examPassScore, 68);
      expect(isPassing(68), isTrue);
      expect(isPassing(67), isFalse);
    });
  });

  group('ExamClock', () {
    late DateTime now;
    late ExamClock clock;
    setUp(() {
      now = DateTime(2026, 11, 13, 10);
      clock = ExamClock(now: () => now);
    });

    test('basic question: 20 s reading then 15 s answering', () {
      clock.startQuestion(q(TheoryPart.basic));
      expect(clock.phase, QuestionPhase.reading);
      expect(clock.remainingInPhase, const Duration(seconds: 20));

      now = now.add(const Duration(seconds: 20));
      expect(clock.phase, QuestionPhase.answering);
      expect(clock.remainingInPhase, const Duration(seconds: 15));
      expect(clock.timeUp, isFalse);

      now = now.add(const Duration(seconds: 15));
      expect(clock.timeUp, isTrue);
      expect(clock.phase, QuestionPhase.done);
    });

    test('skipping the reading starts the 15 s answer time at once', () {
      clock.startQuestion(q(TheoryPart.basic));
      now = now.add(const Duration(seconds: 5));
      clock.skipReading();
      expect(clock.phase, QuestionPhase.answering);
      expect(clock.remainingInPhase, const Duration(seconds: 15));
      now = now.add(const Duration(seconds: 15));
      expect(clock.timeUp, isTrue);
    });

    test('specialist question: 50 s answering', () {
      clock.startQuestion(q(TheoryPart.specialist));
      expect(clock.phase, QuestionPhase.answering);
      expect(clock.remainingInPhase, const Duration(seconds: 50));
      now = now.add(const Duration(seconds: 49));
      expect(clock.timeUp, isFalse);
      now = now.add(const Duration(seconds: 1));
      expect(clock.timeUp, isTrue);
    });

    test('time spent in the background counts against the 25 min', () {
      clock.startQuestion(q(TheoryPart.specialist));
      now = now.add(const Duration(minutes: 10));
      expect(clock.remainingTotal, const Duration(minutes: 15));
      expect(clock.timeUp, isTrue);

      now = now.add(const Duration(minutes: 15));
      clock.startQuestion(q(TheoryPart.specialist));
      expect(clock.remainingTotal, Duration.zero);
      expect(clock.timeUp, isTrue);
    });
  });
}
