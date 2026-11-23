/// Data types of the theory exam section ("Egzamin Teoretyczny").
library;

/// Part of the official exam: basic (TAK/NIE) or specialist (A/B/C).
enum TheoryPart { basic, specialist }

/// Learning category. The catalogue has none, so the bank builder assigns one
/// from the question's wording (tool/theory_exam/build_bank.py); [key] is the
/// value stored in questions_b.json. Listed in display order.
enum TheoryTopic {
  priority('priority', 'Pierwszeństwo i skrzyżowania'),
  overtaking('overtaking', 'Wyprzedzanie, wymijanie i pasy ruchu'),
  pedestrians('pedestrians', 'Piesi, rowerzyści i hulajnogi'),
  speed('speed', 'Prędkość i hamowanie'),
  parking('parking', 'Zatrzymanie, parkowanie i manewry'),
  signs('signs', 'Znaki i sygnały'),
  vehicle('vehicle', 'Pojazd, dokumenty i kary'),
  general('general', 'Jazda – zasady ogólne'),
  railway('railway', 'Przejazdy kolejowe i tramwaje'),
  conditions('conditions', 'Światła i warunki na drodze'),
  firstAid('first_aid', 'Pierwsza pomoc i wypadki'),
  motorway('motorway', 'Autostrady i drogi ekspresowe'),
  alcohol('alcohol', 'Alkohol, leki i uwaga kierowcy');

  const TheoryTopic(this.key, this.label);

  final String key;
  final String label;

  static TheoryTopic fromKey(String? key) => values.firstWhere(
    (t) => t.key == key,
    orElse: () => TheoryTopic.general,
  );
}

/// What a learning or mistakes session covers: everything, questions with a
/// film, or one topic. [key] is used in routes and to remember progress.
class LearnSection {
  const LearnSection._(this.key, this.label, this.topic);

  static const all = LearnSection._('all', 'Wszystkie pytania', null);
  static const video = LearnSection._('video', 'Pytania z filmem', null);

  factory LearnSection.topic(TheoryTopic topic) =>
      LearnSection._(topic.key, topic.label, topic);

  factory LearnSection.fromKey(String key) {
    if (key == video.key) return video;
    for (final t in TheoryTopic.values) {
      if (t.key == key) return LearnSection.topic(t);
    }
    return all;
  }

  final String key;
  final String label;
  final TheoryTopic? topic;

  bool contains(TheoryQuestion q) => switch (key) {
    'all' => true,
    'video' => q.hasVideo,
    _ => q.topic == topic,
  };

  @override
  bool operator ==(Object other) => other is LearnSection && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

class TheoryQuestion {
  const TheoryQuestion({
    required this.id,
    required this.text,
    required this.part,
    required this.points,
    required this.answers,
    required this.correctIndex,
    this.image,
    this.video,
    this.videoBytes,
    this.topic = TheoryTopic.general,
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

  /// Firebase Storage path of the MP4, for questions with a video.
  final String? video;

  /// Size of [video] in bytes, for download progress and storage totals.
  final int? videoBytes;

  final TheoryTopic topic;

  bool get isBasic => part == TheoryPart.basic;

  bool get hasVideo => video != null;

  factory TheoryQuestion.fromJson(Map<String, dynamic> json) => TheoryQuestion(
    id: json['id'] as int,
    text: json['text'] as String,
    part: json['part'] == 'basic' ? TheoryPart.basic : TheoryPart.specialist,
    points: json['points'] as int,
    answers: List<String>.from(json['answers'] as List),
    correctIndex: json['correct'] as int,
    image: json['image'] as String?,
    video: json['video'] as String?,
    videoBytes: json['videoBytes'] as int?,
    topic: TheoryTopic.fromKey(json['topic'] as String?),
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
    this.withoutVideo = false,
  });

  final DateTime date;
  final int score;
  final bool passed;
  final Duration duration;

  /// Question ids in exam order with the chosen answer (null = none).
  final List<(int, int?)> answers;

  /// Taken offline, drawn only from questions without a film.
  final bool withoutVideo;

  Map<String, dynamic> toJson() => {
    if (withoutVideo) 'nv': true,
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
    withoutVideo: json['nv'] as bool? ?? false,
  );
}

class TheoryProgress {
  const TheoryProgress({
    required this.stats,
    required this.exams,
    this.learnCursors = const {},
  });

  factory TheoryProgress.empty() => const TheoryProgress(stats: {}, exams: []);

  static const maxExams = 30;

  final Map<int, QuestionStats> stats;

  /// Newest first, at most [maxExams].
  final List<ExamRecord> exams;

  /// Per learning section ([LearnSection.key]): id of the last question
  /// answered there, so each category resumes where it stopped.
  final Map<String, int> learnCursors;

  int learnCursorFor(String section) => learnCursors[section] ?? 0;

  TheoryProgress withLearnCursor(String section, int questionId) =>
      copyWith(learnCursors: {...learnCursors, section: questionId});

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
    Map<String, int>? learnCursors,
  }) => TheoryProgress(
    stats: stats ?? this.stats,
    exams: exams ?? this.exams,
    learnCursors: learnCursors ?? this.learnCursors,
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
    'learnCursors': learnCursors,
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
    learnCursors: {
      // Saved before categories existed: one cursor for the whole bank.
      if (json['learnCursor'] is int) 'all': json['learnCursor'] as int,
      ...?(json['learnCursors'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as int),
      ),
    },
  );
}
