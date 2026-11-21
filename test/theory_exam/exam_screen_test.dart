import 'dart:async';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/screens/theory_exam/theory_exam_result_screen.dart';
import 'package:drivio/screens/theory_exam/theory_exam_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'theory_test_harness.dart';

List<RouteBase> routes() => [
  GoRoute(path: '/theory/exam', builder: (_, _) => const TheoryExamScreen()),
  GoRoute(
    path: '/theory/exam/result',
    builder: (_, state) =>
        TheoryExamResultScreen(record: state.extra! as ExamRecord),
  ),
];

Future<void> startExam(WidgetTester tester, Harness h) async {
  await tester.pumpWidget(h.app('/', routes()));
  GoRouter.of(tester.element(find.text('start'))).push('/theory/exam');
  await tester.pumpAndSettle();
}

/// Moves the fake clock and lets the exam ticker notice.
Future<void> wait(WidgetTester tester, Harness h, Duration d) async {
  h.advance(d);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

void main() {
  testWidgets('basic question goes on by itself after 20 s + 15 s', (
    tester,
  ) async {
    final h = Harness();
    await startExam(tester, h);

    expect(find.text('Pytanie 1/32'), findsOneWidget);
    expect(find.text('Czas na zapoznanie się'), findsOneWidget);
    await wait(tester, h, const Duration(seconds: 20));
    expect(find.text('Czas na odpowiedź'), findsOneWidget);
    await wait(tester, h, const Duration(seconds: 15));
    expect(find.text('Pytanie 2/32'), findsOneWidget);
  });

  testWidgets('no way back to a previous question', (tester) async {
    final h = Harness();
    await startExam(tester, h);
    await tester.tap(find.byKey(const Key('answer-0')));
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
    expect(find.text('Pytanie 2/32'), findsOneWidget);
    expect(find.text('Wstecz'), findsNothing);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
  });

  testWidgets('answering everything right ends with 74/74 and a pass', (
    tester,
  ) async {
    final h = Harness();
    await startExam(tester, h);
    for (var i = 0; i < 32; i++) {
      await tester.tap(find.byKey(const Key('answer-0')));
      await tester.tap(find.text(i == 31 ? 'Zakończ' : 'Dalej'));
      await tester.pumpAndSettle();
    }
    expect(find.text('74 / 74'), findsOneWidget);
    expect(find.text('Egzamin zdany'), findsOneWidget);
    expect(h.repo.stored.exams.single.score, 74);
    expect(h.repo.stored.exams.single.passed, isTrue);
  });

  testWidgets('wrong answers fail the exam and show in the review', (
    tester,
  ) async {
    final h = Harness();
    await startExam(tester, h);
    for (var i = 0; i < 32; i++) {
      // 8 wrong basic answers cost at least 8 points: at most 66/74.
      await tester.tap(find.byKey(Key('answer-${i < 8 ? 1 : 0}')));
      await tester.tap(find.text(i == 31 ? 'Zakończ' : 'Dalej'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Egzamin niezdany'), findsOneWidget);
    expect(h.repo.stored.exams.single.score, lessThanOrEqualTo(66));
    await tester.tap(find.text('Tylko błędy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Twoja odpowiedź: NIE'), findsWidgets);
    expect(find.textContaining('Twoja odpowiedź: TAK'), findsNothing);
  });

  testWidgets('leaving asks first and an abandoned exam is not saved', (
    tester,
  ) async {
    final h = Harness();
    await startExam(tester, h);
    await tester.tap(find.byTooltip('Przerwij egzamin'));
    await tester.pumpAndSettle();
    expect(find.text('Przerwać egzamin?'), findsOneWidget);
    await tester.tap(find.text('Przerwij'));
    await tester.pumpAndSettle();
    expect(find.text('start'), findsOneWidget);
    expect(h.repo.stored.exams, isEmpty);
  });

  testWidgets('the films are downloaded first, then the exam starts', (
    tester,
  ) async {
    final h = Harness(bank: videoBank());
    h.videos.hold = Completer<void>();
    await tester.pumpWidget(h.app('/', routes()));
    GoRouter.of(tester.element(find.text('start'))).push('/theory/exam');
    await tester.pump();
    await tester.pump();

    expect(find.text('Przygotowuję egzamin…'), findsOneWidget);
    expect(find.text('Pytanie 1/32'), findsNothing);

    h.videos.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Pytanie 1/32'), findsOneWidget);
    expect(h.videos.local, hasLength(20));
  });

  testWidgets('offline: retry, or an exam without films marked as such', (
    tester,
  ) async {
    final h = Harness(bank: videoBank(extraPlainBasics: 12));
    h.videos.offline.addAll([
      for (final q in h.bank.questions)
        if (q.hasVideo) q.id,
    ]);
    await startExam(tester, h);

    expect(find.text('Nie udało się pobrać filmów do egzaminu.'), findsOneWidget);
    await tester.tap(find.text('Spróbuj ponownie'));
    await tester.pumpAndSettle();
    expect(find.text('Spróbuj ponownie'), findsOneWidget);

    await tester.tap(find.text('Egzamin bez filmów'));
    await tester.pumpAndSettle();
    expect(find.text('Pytanie 1/32'), findsOneWidget);
    for (var i = 0; i < 32; i++) {
      await tester.tap(find.byKey(const Key('answer-0')));
      await tester.tap(find.text(i == 31 ? 'Zakończ' : 'Dalej'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Wersja bez filmów'), findsOneWidget);
    expect(h.repo.stored.exams.single.withoutVideo, isTrue);
  });

  testWidgets('a film question: reading, the film once, then 15 s to answer', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final h = Harness(bank: videoBank());
    await startExam(tester, h);

    expect(find.text('Czas na zapoznanie się'), findsOneWidget);
    expect(find.text('Start – odtwórz film'), findsOneWidget);
    expect(h.controllers.last.plays, 0);

    await wait(tester, h, const Duration(seconds: 20));
    expect(find.text('Odtwarzanie filmu'), findsOneWidget);
    expect(h.controllers.last.plays, 1);

    h.controllers.last.end();
    await wait(tester, h, Duration.zero);
    expect(find.text('Czas na odpowiedź'), findsOneWidget);
    expect(find.text('15 s'), findsOneWidget);
    expect(find.text('Odtwórz ponownie'), findsNothing);
  });

  testWidgets('the 25 minute limit ends the exam', (tester) async {
    final h = Harness();
    await startExam(tester, h);
    await wait(tester, h, const Duration(minutes: 25));
    await tester.pumpAndSettle();
    expect(find.text('0 / 74'), findsOneWidget);
    expect(h.repo.stored.exams.single.score, 0);
  });
}
