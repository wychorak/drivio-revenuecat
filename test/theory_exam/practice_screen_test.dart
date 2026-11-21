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
    path: '/theory/learn',
    builder: (_, _) => const TheoryPracticeScreen(mode: PracticeMode.learn),
  ),
  GoRoute(
    path: '/theory/mistakes',
    builder: (_, _) => const TheoryPracticeScreen(mode: PracticeMode.mistakes),
  ),
];

TheoryQuestion basic(int id, {bool video = false}) => TheoryQuestion(
  id: id,
  text: 'Czy pytanie $id?',
  part: TheoryPart.basic,
  points: 3,
  answers: const ['TAK', 'NIE'],
  correctIndex: 1,
  video: video ? 'theory_exam/videos/2026-07/v$id.mp4' : null,
  videoBytes: video ? 1000 : null,
);

QuestionBank bankOf(List<TheoryQuestion> questions) =>
    QuestionBank(sourceVersion: '2026-07', questions: questions);

void main() {
  testWidgets('a video question plays and can be watched again', (
    tester,
  ) async {
    final h = Harness(bank: bankOf([basic(1, video: true)]));
    await tester.pumpWidget(h.app('/theory/learn', routes()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('video-view')), findsOneWidget);
    expect(h.controllers.single.plays, 1);
    expect(find.text('Odtwórz ponownie'), findsNothing);

    h.controllers.single.end();
    await tester.pump();
    await tester.tap(find.text('Odtwórz ponownie'));
    await tester.pump();
    expect(h.controllers.single.plays, 2);
  });

  testWidgets('offline, a video question that is not downloaded is skipped', (
    tester,
  ) async {
    final videos = FakeVideoStore()..offline.add(1);
    final h = Harness(
      bank: bankOf([basic(1, video: true), basic(2)]),
      videos: videos,
    );
    await tester.pumpWidget(h.app('/theory/learn', routes()));
    await tester.pumpAndSettle();

    expect(
      find.text('Brak internetu – pominięto pytanie z filmem'),
      findsOneWidget,
    );
    expect(find.text('Czy pytanie 2?'), findsOneWidget);
  });

  testWidgets('the next question video is fetched ahead', (tester) async {
    final h = Harness(bank: bankOf([basic(1), basic(2, video: true)]));
    await tester.pumpWidget(h.app('/theory/learn', routes()));
    await tester.pumpAndSettle();

    expect(find.text('Czy pytanie 1?'), findsOneWidget);
    expect(h.videos.ensured, contains(2));
  });

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
      find.textContaining('Filmy pobierają się przy pierwszym użyciu'),
      200,
    );
    expect(find.text(theorySourceNote), findsOneWidget);
  });
}
