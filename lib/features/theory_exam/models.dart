/// Data types of the theory exam section ("Egzamin Teoretyczny").
library;

/// Part of the official exam: basic (TAK/NIE) or specialist (A/B/C).
enum TheoryPart { basic, specialist }

class TheoryQuestion {
  const TheoryQuestion({
    required this.id,
    required this.text,
    required this.part,
    required this.points,
    required this.answers,
    required this.correctIndex,
    this.image,
  });

  /// "Numer pytania" from the Ministry of Infrastructure catalogue.
  final int id;
  final String text;
  final TheoryPart part;

  /// 1, 2 or 3 points.
  final int points;

  /// `['TAK', 'NIE']` for basic questions, three options for specialist ones.
  final List<String> answers;
  final int correctIndex;

  /// Asset path of the picture, if the question has one.
  final String? image;

  bool get isBasic => part == TheoryPart.basic;

  factory TheoryQuestion.fromJson(Map<String, dynamic> json) => TheoryQuestion(
    id: json['id'] as int,
    text: json['text'] as String,
    part: json['part'] == 'basic' ? TheoryPart.basic : TheoryPart.specialist,
    points: json['points'] as int,
    answers: List<String>.from(json['answers'] as List),
    correctIndex: json['correct'] as int,
    image: json['image'] as String?,
  );
}

class QuestionStats {
  const QuestionStats({
    this.attempts = 0,
    this.correct = 0,
    this.lastWrong = false,
    this.lastAnswered,
  });

  final int attempts;
  final int correct;
  final bool lastWrong;
  final DateTime? lastAnswered;

  Map<String, dynamic> toJson() => {
    'a': attempts,
    'c': correct,
    'w': lastWrong,
    if (lastAnswered != null) 't': lastAnswered!.millisecondsSinceEpoch,
  };

  factory QuestionStats.fromJson(Map<String, dynamic> json) => QuestionStats(
    attempts: json['a'] as int,
    correct: json['c'] as int,
    lastWrong: json['w'] as bool,
    lastAnswered: json['t'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json['t'] as int),
  );
}

class ExamRecord {
  const ExamRecord({
    required this.date,
    required this.score,
    required this.passed,
    required this.duration,
    required this.answers,
  });

  final DateTime date;
  final int score;
  final bool passed;
  final Duration duration;

  /// Question ids in exam order with the chosen answer (null = none).
  final List<(int, int?)> answers;

  Map<String, dynamic> toJson() => {
    'date': date.millisecondsSinceEpoch,
    'score': score,
    'passed': passed,
    'ms': duration.inMilliseconds,
    'answers': [
      for (final (id, answer) in answers) [id, answer],
    ],
  };

  factory ExamRecord.fromJson(Map<String, dynamic> json) => ExamRecord(
    date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
    score: json['score'] as int,
    passed: json['passed'] as bool,
    duration: Duration(milliseconds: json['ms'] as int),
    answers: [
      for (final pair in json['answers'] as List)
        ((pair as List)[0] as int, pair[1] as int?),
    ],
  );
}

class TheoryProgress {
  const TheoryProgress({
    required this.stats,
    required this.exams,
    this.learnCursor = 0,
  });

  factory TheoryProgress.empty() => const TheoryProgress(stats: {}, exams: []);

  static const maxExams = 30;

  final Map<int, QuestionStats> stats;

  /// Newest first, at most [maxExams].
  final List<ExamRecord> exams;

  /// Position in the learning mode's question list.
  final int learnCursor;

  Set<int> get mistakes => {
    for (final e in stats.entries)
      if (e.value.lastWrong) e.key,
  };

  int get seenCount => stats.length;

  /// Share of correct answers among all answers, 0 when nothing answered.
  double get accuracy {
    var attempts = 0, correct = 0;
    for (final s in stats.values) {
      attempts += s.attempts;
      correct += s.correct;
    }
    return attempts == 0 ? 0 : correct / attempts;
  }

  TheoryProgress copyWith({
    Map<int, QuestionStats>? stats,
    List<ExamRecord>? exams,
    int? learnCursor,
  }) => TheoryProgress(
    stats: stats ?? this.stats,
    exams: exams ?? this.exams,
    learnCursor: learnCursor ?? this.learnCursor,
  );

  TheoryProgress recordAnswer(int id, bool correct, DateTime at) {
    final old = stats[id] ?? const QuestionStats();
    return copyWith(
      stats: {
        ...stats,
        id: QuestionStats(
          attempts: old.attempts + 1,
          correct: old.correct + (correct ? 1 : 0),
          lastWrong: !correct,
          lastAnswered: at,
        ),
      },
    );
  }

  TheoryProgress addExam(ExamRecord record) =>
      copyWith(exams: [record, ...exams].take(maxExams).toList());

  Map<String, dynamic> toJson() => {
    'stats': {
      for (final e in stats.entries) '${e.key}': e.value.toJson(),
    },
    'exams': [for (final e in exams) e.toJson()],
    'learnCursor': learnCursor,
  };

  factory TheoryProgress.fromJson(Map<String, dynamic> json) => TheoryProgress(
    stats: {
      for (final e in (json['stats'] as Map<String, dynamic>).entries)
        int.parse(e.key): QuestionStats.fromJson(
          e.value as Map<String, dynamic>,
        ),
    },
    exams: [
      for (final e in json['exams'] as List)
        ExamRecord.fromJson(e as Map<String, dynamic>),
    ],
    learnCursor: json['learnCursor'] as int? ?? 0,
  );
}
