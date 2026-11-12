import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drivio/features/theory_exam/ad_policy.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/services/ad_service.dart';
import 'package:drivio/services/analytics_service.dart';

/// Loads and shows interstitials; replaced by a fake in tests.
class TheoryInterstitial {
  const TheoryInterstitial({required this.preload, required this.show});

  final Future<void> Function() preload;

  /// Resolves when the ad is closed; false when no ad could be shown.
  final Future<bool> Function() show;
}

final theoryInterstitialProvider = Provider<TheoryInterstitial>(
  (ref) => TheoryInterstitial(
    preload: AdService.instance.preloadInterstitial,
    show: () async {
      final shown = await AdService.instance.showInterstitial();
      if (shown) AnalyticsService.instance.theoryInterstitialShown();
      return shown;
    },
  ),
);

/// No ads for premium users, nor while their status is still unknown.
final theoryAdsPremiumProvider = Provider<bool>(
  (ref) =>
      ref.watch(isPremiumProvider) ||
      !ref.watch(premiumStatusResolvedProvider),
);

final theoryAdControllerProvider = NotifierProvider<TheoryAdController, void>(
  TheoryAdController.new,
);

class TheoryAdController extends Notifier<void> {
  /// The exam result must never wait on an ad longer than this.
  static const maxWait = Duration(seconds: 5);

  late TheoryAdPolicy _policy;

  @override
  void build() {
    _policy = TheoryAdPolicy(sectionEnteredAt: _now());
    if (!ref.read(theoryAdsPremiumProvider)) {
      unawaited(ref.read(theoryInterstitialProvider).preload());
    }
  }

  DateTime _now() => ref.read(theoryClockProvider)();

  bool get _premium => ref.read(theoryAdsPremiumProvider);

  Future<void> onAnswer() async {
    if (_policy.onAnswer(_now(), premium: _premium)) await _show();
  }

  Future<void> onExamFinished() async {
    if (_policy.onExamFinished(_now(), premium: _premium)) await _show();
  }

  Future<void> _show() async {
    final ads = ref.read(theoryInterstitialProvider);
    var shown = false;
    try {
      shown = await ads.show().timeout(maxWait, onTimeout: () => false);
    } catch (error) {
      // Ads are optional: a plugin failure must not stop the user.
      debugPrint('Theory interstitial failed: $error');
    }
    if (shown) _policy.markShown(_now());
    unawaited(ads.preload().catchError((Object _) {}));
  }
}
