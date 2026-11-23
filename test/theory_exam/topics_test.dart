import 'dart:math';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/question_bank.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:flutter_test/flutter_test.dart';

TheoryQuestion tq(int id, TheoryTopic topic, {bool video = false}) =>
    TheoryQuestion(
      id: id,
      text: 'Pytanie $id?',
      part: TheoryPart.basic,
      points: 3,
      answers: const ['TAK', 'NIE'],
      correctIndex: 0,
      topic: topic,
      video: video ? 'theory_exam/videos/2026-07/v$id.mp4' : null,
      videoBytes: video ? 1000 : null,
    );

final topicBank = QuestionBank(
  sourceVersion: '2026-07',
  questions: [
    tq(1, TheoryTopic.parking),
    tq(2, TheoryTopic.priority, video: true),
    tq(3, TheoryTopic.parking, video: true),
    tq(4, TheoryTopic.signs),
  ],
);

void main() {
  test('reads the topic; an unknown or missing one is general', () {
    Map<String, dynamic> json(Object? topic) => {
      'id': 1,
      'text': 't',
      'part': 'basic',
      'points': 3,
      'answers': ['TAK', 'NIE'],
      'correct': 0,
      'topic': topic,
    };
    expect(TheoryQuestion.fromJson(json('first_aid')).topic, TheoryTopic.firstAid);
    expect(TheoryQuestion.fromJson(json('parking')).topic, TheoryTopic.parking);
    expect(TheoryQuestion.fromJson(json('new_thing')).topic, TheoryTopic.general);
    expect(TheoryQuestion.fromJson(json(null)).topic, TheoryTopic.general);
  });

  test('every topic has a Polish label and a unique key', () {
    expect(TheoryTopic.values.map((t) => t.key).toSet(),
        hasLength(TheoryTopic.values.length));
    expect(TheoryTopic.parking.label, 'Zatrzymanie, parkowanie i manewry');
    for (final t in TheoryTopic.values) {
      expect(t.label, isNotEmpty);
    }
  });

  test('sections: all, films, then each topic', () {
    expect(LearnSection.fromKey('all'), LearnSection.all);
    expect(LearnSection.fromKey('video').label, 'Pytania z filmem');
    expect(LearnSection.fromKey('parking').topic, TheoryTopic.parking);
    expect(LearnSection.fromKey('nonsense'), LearnSection.all);
    final q = topicBank.questions;
    expect(LearnSection.all.contains(q[0]), isTrue);
    expect(LearnSection.video.contains(q[0]), isFalse);
    expect(LearnSection.video.contains(q[1]), isTrue);
    expect(LearnSection.fromKey('parking').contains(q[2]), isTrue);
  });

  test('learning and mistakes queues keep to the chosen section', () {
    final progress = TheoryProgress.empty()
        .recordAnswer(3, false, DateTime(2026))
        .recordAnswer(4, false, DateTime(2026));
    List<int> ids(PracticeMode mode, String section) => practiceQueue(
      topicBank,
      progress,
      mode,
      PracticeFilter(section: LearnSection.fromKey(section)),
      Random(1),
    ).map((q) => q.id).toList();

    expect(ids(PracticeMode.learn, 'parking'), [1, 3]);
    expect(ids(PracticeMode.learn, 'video'), [2, 3]);
    expect(ids(PracticeMode.learn, 'all'), [1, 2, 3, 4]);
    expect(ids(PracticeMode.mistakes, 'parking'), [3]);
    expect(ids(PracticeMode.mistakes, 'all'), [3, 4]);
  });

  test('each section remembers where learning stopped', () {
    final p = TheoryProgress.empty()
        .withLearnCursor('parking', 3)
        .withLearnCursor('all', 2);
    expect(p.learnCursorFor('parking'), 3);
    expect(p.learnCursorFor('all'), 2);
    expect(p.learnCursorFor('signs'), 0);
    final back = TheoryProgress.fromJson(p.toJson());
    expect(back.learnCursorFor('parking'), 3);
  });

  test('progress saved by the previous version keeps its place', () {
    final old = TheoryProgress.fromJson({
      'stats': <String, dynamic>{},
      'exams': <dynamic>[],
      'learnCursor': 12,
    });
    expect(old.learnCursorFor('all'), 12);
  });
}
