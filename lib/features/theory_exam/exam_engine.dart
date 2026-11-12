import 'dart:math';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/question_bank.dart';

// Rules of the state theory test, § 19 of the Minister of Infrastructure
// regulation of 24 November 2023 (Dz.U. 2023 poz. 2659).

/// Questions drawn per part and point value.
const Map<TheoryPart, Map<int, int>> examBlueprint = {
  TheoryPart.basic: {3: 10, 2: 6, 1: 4},
  TheoryPart.specialist: {3: 6, 2: 4, 1: 2},
};
const int examMaxScore = 74;
const int examPassScore = 68;
const Duration examTotalLimit = Duration(minutes: 25);
const Duration basicReadingTime = Duration(seconds: 20);
const Duration basicAnswerTime = Duration(seconds: 15);
const Duration specialistAnswerTime = Duration(seconds: 50);

bool isPassing(int score) => score >= examPassScore;

/// 32 questions: 20 basic, then 12 specialist, each part shuffled.
/// Throws [StateError] when the bank cannot fill the blueprint.
List<TheoryQuestion> generateExam(QuestionBank bank, Random rng) {
  final exam = <TheoryQuestion>[];
  for (final part in TheoryPart.values) {
    final picked = <TheoryQuestion>[];
    for (final MapEntry(key: points, value: count)
        in examBlueprint[part]!.entries) {
      final pool = bank.questions
          .where((q) => q.part == part && q.points == points)
          .toList();
      if (pool.length < count) {
        throw StateError('Bank has ${pool.length} $part/$points questions');
      }
      pool.shuffle(rng);
      picked.addAll(pool.take(count));
    }
    picked.shuffle(rng);
    exam.addAll(picked);
  }
  return exam;
}

/// Points for correct answers; a missing answer scores 0.
int scoreExam(List<TheoryQuestion> questions, List<int?> answers) {
  var score = 0;
  for (var i = 0; i < questions.length; i++) {
    if (i < answers.length && answers[i] == questions[i].correctIndex) {
      score += questions[i].points;
    }
  }
  return score;
}

enum QuestionPhase { reading, answering, done }

/// Exam timing derived from wall-clock time, so a locked phone or a paused
/// ticker cannot stretch the limits.
class ExamClock {
  ExamClock({required DateTime Function() now})
    : _now = now,
      _examStart = now();

  final DateTime Function() _now;
  final DateTime _examStart;
  DateTime _questionStart = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _readingSkippedAt;
  bool _basic = false;

  void startQuestion(TheoryQuestion question) {
    _questionStart = _now();
    _readingSkippedAt = null;
    _basic = question.isBasic;
  }

  /// Ends the reading time of a basic question early.
  void skipReading() {
    if (_basic && phase == QuestionPhase.reading) _readingSkippedAt = _now();
  }

  DateTime get _answerStart => !_basic
      ? _questionStart
      : _readingSkippedAt ?? _questionStart.add(basicReadingTime);

  DateTime get _answerEnd =>
      _answerStart.add(_basic ? basicAnswerTime : specialistAnswerTime);

  Duration get remainingTotal {
    final left = examTotalLimit - _now().difference(_examStart);
    return left.isNegative ? Duration.zero : left;
  }

  bool get timeUp =>
      !_now().isBefore(_answerEnd) || remainingTotal == Duration.zero;

  QuestionPhase get phase {
    if (timeUp) return QuestionPhase.done;
    return _now().isBefore(_answerStart)
        ? QuestionPhase.reading
        : QuestionPhase.answering;
  }

  Duration get remainingInPhase => switch (phase) {
    QuestionPhase.reading => _answerStart.difference(_now()),
    QuestionPhase.answering => _answerEnd.difference(_now()),
    QuestionPhase.done => Duration.zero,
  };

  /// Length of the current phase, for progress bars.
  Duration get phaseLength => switch (phase) {
    QuestionPhase.reading => basicReadingTime,
    _ => _basic ? basicAnswerTime : specialistAnswerTime,
  };

  Duration get elapsed => _now().difference(_examStart);
}
