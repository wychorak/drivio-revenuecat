import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:drivio/screens/theory_exam/theory_practice_screen.dart';
import 'package:drivio/screens/theory_exam/theory_sections_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'theory_test_harness.dart';
import 'topics_test.dart' show topicBank;

List<RouteBase> routes() => [
  for (final mode in [PracticeMode.learn, PracticeMode.mistakes]) ...[
    GoRoute(
      path: '/theory/${mode.name}',
      builder: (_, _) => TheorySectionsScreen(mode: mode),
    ),
    GoRoute(
      path: '/theory/${mode.name}/:section',
      builder: (_, state) => TheoryPracticeScreen(
        mode: mode,
        section: LearnSection.fromKey(state.pathParameters['section']!),
      ),
    ),
  ],
];

Future<void> open(WidgetTester tester, Harness h, String path) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(h.app(path, routes()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('learning lists all questions, films and each topic', (
    tester,
  ) async {
    final h = Harness(
      bank: topicBank,
      progress: TheoryProgress.empty().recordAnswer(1, true, DateTime(2026)),
    );
    await open(tester, h, '/theory/learn');

    expect(find.text('Wszystkie pytania'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.text('Pytania z filmem'), findsOneWidget);
    expect(find.text('0 / 2'), findsOneWidget);
    expect(find.text('Zatrzymanie, parkowanie i manewry'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Znaki i sygnały'), findsOneWidget);
    // Topics without questions are not offered.
    expect(find.text('Pierwsza pomoc i wypadki'), findsNothing);
  });

  testWidgets('a topic tile opens learning with only that topic', (
    tester,
  ) async {
    final h = Harness(bank: topicBank);
    await open(tester, h, '/theory/learn');

    await tester.tap(find.text('Znaki i sygnały'));
    await tester.pumpAndSettle();
    expect(find.text('Pytanie 4?'), findsOneWidget);
    expect(find.text('Pytanie 1 z 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('answer-0')));
    await tester.pumpAndSettle();
    expect(h.repo.stored.learnCursorFor('signs'), 4);
    expect(h.repo.stored.learnCursorFor('all'), 0);
  });

  testWidgets('mistakes are grouped by topic', (tester) async {
    final h = Harness(
      bank: topicBank,
      progress: TheoryProgress.empty()
          .recordAnswer(3, false, DateTime(2026))
          .recordAnswer(4, false, DateTime(2026)),
    );
    await open(tester, h, '/theory/mistakes');

    expect(find.text('Wszystkie błędy'), findsOneWidget);
    expect(find.text('Zatrzymanie, parkowanie i manewry'), findsOneWidget);
    expect(find.text('Znaki i sygnały'), findsOneWidget);
    expect(find.text('Pierwszeństwo i skrzyżowania'), findsNothing);

    await tester.tap(find.text('Zatrzymanie, parkowanie i manewry'));
    await tester.pumpAndSettle();
    expect(find.text('Pytanie 3?'), findsOneWidget);
  });

  testWidgets('no mistakes: an empty state instead of tiles', (tester) async {
    final h = Harness(bank: topicBank);
    await open(tester, h, '/theory/mistakes');
    expect(find.text('Brak błędów do powtórki'), findsOneWidget);
    expect(find.text('Wszystkie błędy'), findsNothing);
  });
}
