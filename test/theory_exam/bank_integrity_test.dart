import 'dart:io';

import 'package:drivio/features/theory_exam/exam_engine.dart';
import 'package:drivio/features/theory_exam/question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the generated asset that ships in the app.
void main() {
  final bank = QuestionBank.fromJsonString(
    File(QuestionBank.assetPath).readAsStringSync(),
  );

  test('bank comes from the 07.2026 catalogue and has ~1100 questions', () {
    expect(bank.sourceVersion, '2026-07');
    expect(bank.questions.length, greaterThan(1000));
  });

  test('ids are unique and answers are consistent', () {
    expect(bank.questions.map((q) => q.id).toSet(), hasLength(
      bank.questions.length,
    ));
    for (final q in bank.questions) {
      expect(q.correctIndex, lessThan(q.answers.length), reason: '${q.id}');
      expect(q.answers, hasLength(q.isBasic ? 2 : 3), reason: '${q.id}');
      expect(q.text.trim(), isNotEmpty, reason: '${q.id}');
    }
  });

  test('every referenced picture is bundled', () {
    for (final q in bank.questions.where((q) => q.image != null)) {
      expect(File(q.image!).existsSync(), isTrue, reason: q.image);
    }
  });

  test('every exam group has plenty of questions', () {
    for (final MapEntry(key: part, value: groups) in examBlueprint.entries) {
      for (final MapEntry(key: points, value: needed) in groups.entries) {
        final available = bank.questions
            .where((q) => q.part == part && q.points == points)
            .length;
        expect(available, greaterThanOrEqualTo(needed * 3),
            reason: '$part/$points');
      }
    }
  });
}
