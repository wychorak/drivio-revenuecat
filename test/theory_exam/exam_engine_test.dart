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

TheoryQuestion q(TheoryPart part, {String? video}) => TheoryQuestion(
  id: 1,
  text: 'x',
  part: part,
  points: 3,
  answers: const ['TAK', 'NIE'],
  correctIndex: 0,
  video: video,
  videoBytes: video == null ? null : 100,
);

/// Like [fakeBank], with every other basic question carrying a video.
QuestionBank bankWithVideos({int perGroup = 15}) => QuestionBank(
  sourceVersion: 'test',
  questions: [
    for (final x in fakeBank(perGroup: perGroup).questions)
      TheoryQuestion(
        id: x.id,
        text: x.text,
        part: x.part,
        points: x.points,
        answers: x.answers,
        correctIndex: x.correctIndex,
        video: x.isBasic && x.id.isEven ? 'v/${x.id}.mp4' : null,
        videoBytes: x.isBasic && x.id.isEven ? 100 : null,
      ),
  ],
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

    test('the variant without videos never draws a video question', () {
      final exam = generateExam(
        bankWithVideos(perGroup: 25),
        Random(3),
        withoutVideo: true,
      );
      expect(exam, hasLength(32));
      expect(exam.where((q) => q.hasVideo), isEmpty);
      expect(exam.fold<int>(0, (s, q) => s + q.points), examMaxScore);
    });

    test('the full exam draws video questions too', () {
      final withVideo = [
        for (var seed = 0; seed < 5; seed++)
          ...generateExam(bankWithVideos(), Random(seed)),
      ].where((q) => q.hasVideo);
      expect(withVideo, isNotEmpty);
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

    test('video question: 20 s reading, the film, then 15 s answering', () {
      clock.startQuestion(q(TheoryPart.basic, video: 'v/1.mp4'));
      expect(clock.phase, QuestionPhase.reading);
      now = now.add(const Duration(seconds: 20));
      expect(clock.phase, QuestionPhase.video);

      clock.startVideo(const Duration(seconds: 9));
      expect(clock.phase, QuestionPhase.video);
      expect(clock.phaseLength, const Duration(seconds: 9));
      now = now.add(const Duration(seconds: 8));
      expect(clock.phase, QuestionPhase.video);
      expect(clock.remainingInPhase, const Duration(seconds: 1));

      now = now.add(const Duration(seconds: 1));
      expect(clock.phase, QuestionPhase.answering);
      expect(clock.remainingInPhase, const Duration(seconds: 15));
      now = now.add(const Duration(seconds: 15));
      expect(clock.timeUp, isTrue);
    });

    test('Start skips the reading and the film begins at once', () {
      clock.startQuestion(q(TheoryPart.basic, video: 'v/1.mp4'));
      now = now.add(const Duration(seconds: 4));
      clock.skipReading();
      expect(clock.phase, QuestionPhase.video);
    });

    test('a film that never starts gives way to answering after 3 s', () {
      clock.startQuestion(q(TheoryPart.basic, video: 'v/1.mp4'));
      clock.skipReading();
      now = now.add(const Duration(seconds: 2));
      expect(clock.phase, QuestionPhase.video);
      now = now.add(const Duration(seconds: 1));
      expect(clock.phase, QuestionPhase.answering);
      expect(clock.remainingInPhase, const Duration(seconds: 15));
    });

    test('a failed or finished film starts the answer time at once', () {
      clock.startQuestion(q(TheoryPart.basic, video: 'v/1.mp4'));
      clock.skipReading();
      clock.startVideo(const Duration(seconds: 10));
      now = now.add(const Duration(seconds: 2));
      clock.videoEnded();
      expect(clock.phase, QuestionPhase.answering);
      expect(clock.remainingInPhase, const Duration(seconds: 15));

      clock.startQuestion(q(TheoryPart.basic, video: 'v/2.mp4'));
      clock.skipReading();
      clock.videoFailed();
      expect(clock.phase, QuestionPhase.answering);
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
