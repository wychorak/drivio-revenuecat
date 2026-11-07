import 'package:drivio/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const Text('login')),
  ],
);

void main() {
  testWidgets('splash plays the intro and then opens login', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));

    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byType(SplashScreen), findsOneWidget);

    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('tapping the splash skips the intro straight away', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.tap(find.byType(SplashScreen));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('login'), findsOneWidget);

    // The rest of the intro must not navigate a second time.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('login'), findsOneWidget);
  });
}
