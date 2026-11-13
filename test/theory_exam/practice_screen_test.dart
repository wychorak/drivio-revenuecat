import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/question_bank.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:drivio/screens/theory_exam/theory_home_screen.dart';
import 'package:drivio/screens/theory_exam/theory_practice_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'theory_test_harness.dart';

final basicBank = QuestionBank(
  sourceVersion: '2026-07',
  questions: [
    for (var id = 1; id <= 3; id++)
      TheoryQuestion(
        id: id,
        text: 'Czy pytanie $id?',
        part: TheoryPart.basic,
        points: 3,
        answers: const ['TAK', 'NIE'],
        correctIndex: 1,
      ),
  ],
);

List<RouteBase> routes() => [
  GoRoute(path: '/theory', builder: (_, _) => const TheoryHomeScreen()),
  GoRoute(
    path: '/theory/random',
    builder: (_, _) => const TheoryPracticeScreen(mode: PracticeMode.random),
  ),
  GoRoute(
    path: '/theory/mistakes',
    builder: (_, _) => const TheoryPracticeScreen(mode: PracticeMode.mistakes),
  ),
];

void main() {
  testWidgets('wrong answer is marked and the correct one revealed', (
    tester,
  ) async {
    final h = Harness(bank: basicBank);
    await tester.pumpWidget(h.app('/theory/random', routes()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Czy pytanie'), findsOneWidget);
    await tester.tap(find.byKey(const Key('answer-0')));
    await tester.pumpAndSettle();

    expect(find.text('Źle. Poprawna odpowiedź: NIE'), findsOneWidget);
    expect(h.repo.stored.mistakes, hasLength(1));

    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
    expect(find.text('Źle. Poprawna odpowiedź: NIE'), findsNothing);
    expect(find.textContaining('Czy pytanie'), findsOneWidget);
  });

  testWidgets('correct answer says so', (tester) async {
    final h = Harness(bank: basicBank);
    await tester.pumpWidget(h.app('/theory/random', routes()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('answer-1')));
    await tester.pumpAndSettle();
    expect(find.text('Dobrze!'), findsOneWidget);
  });

  testWidgets('mistakes mode without mistakes shows an empty state', (
    tester,
  ) async {
    final h = Harness(bank: basicBank);
    await tester.pumpWidget(h.app('/theory/mistakes', routes()));
    await tester.pumpAndSettle();
    expect(find.text('Brak błędów do powtórki'), findsOneWidget);
  });

  testWidgets('home shows progress, modes and the source note', (
    tester,
  ) async {
    final h = Harness(
      bank: basicBank,
      progress: TheoryProgress.empty().recordAnswer(
        2,
        false,
        DateTime(2026),
      ),
    );
    await tester.pumpWidget(h.app('/theory', routes()));
    await tester.pumpAndSettle();

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Losuj pytanie'), findsOneWidget);
    expect(find.text('Pełny egzamin'), findsOneWidget);
    expect(find.text('Nauka'), findsOneWidget);
    expect(find.text('Powtórka błędów'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Pytania z filmami nie są uwzględnione'),
      200,
    );
    expect(
      find.text(
        'Pytania: Ministerstwo Infrastruktury, stan 07.2026. '
        'Pytania z filmami nie są uwzględnione.',
      ),
      findsOneWidget,
    );
  });
}
