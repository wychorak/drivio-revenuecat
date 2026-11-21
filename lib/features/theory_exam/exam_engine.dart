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

/// A film that has not started this long after the reading time is treated
/// as failed, so a broken player never eats the answer time.
const Duration videoStartTimeout = Duration(seconds: 3);

bool isPassing(int score) => score >= examPassScore;

/// 32 questions: 20 basic, then 12 specialist, each part shuffled.
/// [withoutVideo] draws only questions that work offline.
/// Throws [StateError] when the bank cannot fill the blueprint.
List<TheoryQuestion> generateExam(
  QuestionBank bank,
  Random rng, {
  bool withoutVideo = false,
}) {
  final exam = <TheoryQuestion>[];
  for (final part in TheoryPart.values) {
    final picked = <TheoryQuestion>[];
    for (final MapEntry(key: points, value: count)
        in examBlueprint[part]!.entries) {
      final pool = bank.questions
          .where(
            (q) =>
                q.part == part &&
                q.points == points &&
                !(withoutVideo && q.hasVideo),
          )
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

/// Basic question with a film: reading, then video, then answering.
enum QuestionPhase { reading, video, answering, done }

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
  bool _video = false;
  DateTime? _videoEnd;
  Duration? _videoLength;

  void startQuestion(TheoryQuestion question) {
    _questionStart = _now();
    _readingSkippedAt = null;
    _basic = question.isBasic;
    _video = question.isBasic && question.hasVideo;
    _videoEnd = null;
    _videoLength = null;
  }

  /// Ends the reading time of a basic question early.
  void skipReading() {
    if (_basic && phase == QuestionPhase.reading) _readingSkippedAt = _now();
  }

  /// The film started playing and lasts [length].
  void startVideo(Duration length) {
    if (!_video || phase != QuestionPhase.video) return;
    _videoLength = length;
    _videoEnd = _now().add(length);
  }

  /// The film finished (or will not play): the answer time starts now.
  void videoEnded() {
    if (_video && phase == QuestionPhase.video) _videoEnd = _now();
  }

  void videoFailed() => videoEnded();

  DateTime get _readingEnd =>
      _readingSkippedAt ?? _questionStart.add(basicReadingTime);

  DateTime get _answerStart {
    if (!_basic) return _questionStart;
    if (!_video) return _readingEnd;
    return _videoEnd ?? _readingEnd.add(videoStartTimeout);
  }

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
    final now = _now();
    if (!now.isBefore(_answerStart)) return QuestionPhase.answering;
    if (_video && !now.isBefore(_readingEnd)) return QuestionPhase.video;
    return QuestionPhase.reading;
  }

  Duration get remainingInPhase => switch (phase) {
    QuestionPhase.reading =>
      (_video ? _readingEnd : _answerStart).difference(_now()),
    QuestionPhase.video => _answerStart.difference(_now()),
    QuestionPhase.answering => _answerEnd.difference(_now()),
    QuestionPhase.done => Duration.zero,
  };

  /// Length of the current phase, for progress bars.
  Duration get phaseLength => switch (phase) {
    QuestionPhase.reading => basicReadingTime,
    QuestionPhase.video => _videoLength ?? videoStartTimeout,
    _ => _basic ? basicAnswerTime : specialistAnswerTime,
  };

  Duration get elapsed => _now().difference(_examStart);
}
