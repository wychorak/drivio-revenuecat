import 'package:drivio/features/theory_exam/ad_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final entered = DateTime(2026, 11, 13, 10);
  DateTime at(Duration d) => entered.add(d);
  const later = Duration(minutes: 5);

  bool answer(TheoryAdPolicy p, int times, DateTime now) {
    var shown = false;
    for (var i = 0; i < times; i++) {
      shown = p.onAnswer(now, premium: false);
    }
    return shown;
  }

  test('10th answer after the warm-up asks for an ad, 9th does not', () {
    final policy = TheoryAdPolicy(sectionEnteredAt: entered);
    expect(answer(policy, 9, at(later)), isFalse);
    expect(policy.onAnswer(at(later), premium: false), isTrue);
  });

  test('no ad in the first 2 minutes of the section', () {
    final policy = TheoryAdPolicy(sectionEnteredAt: entered);
    expect(answer(policy, 10, at(const Duration(minutes: 1))), isFalse);
    // The count is kept, so the next answer after the warm-up shows it.
    expect(policy.onAnswer(at(const Duration(minutes: 2)), premium: false),
        isTrue);
  });

  test('at least 3 minutes between ads', () {
    final policy = TheoryAdPolicy(sectionEnteredAt: entered);
    expect(answer(policy, 10, at(later)), isTrue);
    policy.markShown(at(later));
    expect(
      answer(policy, 10, at(later + const Duration(minutes: 2))),
      isFalse,
    );
    expect(
      policy.onAnswer(at(later + const Duration(minutes: 3)), premium: false),
      isTrue,
    );
  });

  test('showing an ad restarts the answer count', () {
    final policy = TheoryAdPolicy(sectionEnteredAt: entered);
    answer(policy, 10, at(later));
    policy.markShown(at(later));
    final next = at(later + const Duration(minutes: 10));
    expect(answer(policy, 9, next), isFalse);
    expect(policy.onAnswer(next, premium: false), isTrue);
  });

  test('premium users never get ads', () {
    final policy = TheoryAdPolicy(sectionEnteredAt: entered);
    for (var i = 0; i < 30; i++) {
      expect(policy.onAnswer(at(later), premium: true), isFalse);
    }
    expect(policy.onExamFinished(at(later), premium: true), isFalse);
  });

  test('finishing an exam asks for an ad after the warm-up and gap', () {
    final policy = TheoryAdPolicy(sectionEnteredAt: entered);
    expect(policy.onExamFinished(at(const Duration(minutes: 1)),
        premium: false), isFalse);
    expect(policy.onExamFinished(at(later), premium: false), isTrue);
    policy.markShown(at(later));
    expect(policy.onExamFinished(at(later + const Duration(minutes: 1)),
        premium: false), isFalse);
  });
}
