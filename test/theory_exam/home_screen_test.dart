import 'package:drivio/screens/theory_exam/theory_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'theory_test_harness.dart';

List<RouteBase> routes() => [
  GoRoute(path: '/theory', builder: (_, _) => const TheoryHomeScreen()),
];

void main() {
  testWidgets('shows the space taken by films and clears them', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final h = Harness();
    h.videos.local.addAll(['a.mp4', 'b.mp4']);
    await tester.pumpWidget(h.app('/theory', routes()));
    await tester.pumpAndSettle();

    expect(find.text('Pobrane filmy: 2 MB'), findsOneWidget);
    await tester.tap(find.text('Usuń pobrane filmy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usuń'));
    await tester.pumpAndSettle();

    expect(h.videos.local, isEmpty);
    expect(find.textContaining('Pobrane filmy'), findsNothing);
  });

  testWidgets('no film storage row before any film is downloaded', (
    tester,
  ) async {
    final h = Harness();
    await tester.pumpWidget(h.app('/theory', routes()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pobrane filmy'), findsNothing);
  });

  test('the source note no longer says films are left out', () {
    expect(theorySourceNote, isNot(contains('filmami')));
    expect(theorySourceNote, contains('07.2026'));
  });
}
