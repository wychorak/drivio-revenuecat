import 'dart:async';

import 'package:drivio/providers/theory_ad_provider.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late int shows;

  ProviderContainer make({
    required bool premium,
    required Future<bool> Function() show,
  }) {
    final c = ProviderContainer(
      overrides: [
        theoryClockProvider.overrideWithValue(() => now),
        theoryAdsPremiumProvider.overrideWithValue(premium),
        theoryInterstitialProvider.overrideWithValue(
          TheoryInterstitial(
            preload: () async {},
            show: () {
              shows++;
              return show();
            },
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    now = DateTime(2026, 11, 13, 10);
    shows = 0;
  });

  test('shows an interstitial on the 10th answer after the warm-up', () async {
    final c = make(premium: false, show: () async => true);
    final ads = c.read(theoryAdControllerProvider.notifier);
    now = now.add(const Duration(minutes: 3));
    for (var i = 0; i < 9; i++) {
      await ads.onAnswer();
    }
    expect(shows, 0);
    await ads.onAnswer();
    expect(shows, 1);
  });

  test('premium users get no interstitial', () async {
    final c = make(premium: true, show: () async => true);
    final ads = c.read(theoryAdControllerProvider.notifier);
    now = now.add(const Duration(minutes: 3));
    await ads.onExamFinished();
    expect(shows, 0);
  });

  test('a failing ad plugin never breaks the flow', () async {
    final c = make(premium: false, show: () => Future.error('plugin crash'));
    final ads = c.read(theoryAdControllerProvider.notifier);
    now = now.add(const Duration(minutes: 3));
    await ads.onExamFinished();
    expect(shows, 1);
  });

  test('a hanging ad never blocks the exam result for more than 5 s', () {
    final c = make(premium: false, show: () => Completer<bool>().future);
    final ads = c.read(theoryAdControllerProvider.notifier);
    now = now.add(const Duration(minutes: 3));

    final stopwatch = Stopwatch()..start();
    return ads.onExamFinished().then((_) {
      expect(shows, 1);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 6)));
    });
  }, timeout: const Timeout(Duration(seconds: 10)));
}
