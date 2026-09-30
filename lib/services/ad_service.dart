import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:drivio/config/app_config.dart';

/// How a rewarded ad attempt ended.
enum RewardedAdOutcome {
  /// The user watched to the end; AdMob confirms the reward to the backend.
  rewarded,

  /// The ad was shown but closed before the reward.
  closedEarly,

  /// No ad could be shown: no consent, no fill or a network error.
  unavailable,
}

class AdService {
  AdService._();

  static final AdService instance = AdService._();
  static const _useLiveRewardedAd = bool.fromEnvironment(
    'USE_LIVE_REWARDED_AD',
    defaultValue: false,
  );

  bool get usesTestRewardedAd => kDebugMode && !_useLiveRewardedAd;

  Future<bool>? _initializing;
  bool _canRequestAds = false;

  /// Short reason for the last failed ad request, shown next to the
  /// "unavailable" message so failures can be diagnosed on real devices.
  String? lastAdIssue;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> initialize() async {
    final inProgress = _initializing ??= _initialize();
    try {
      final ready = await inProgress;
      if (!ready) _initializing = null;
      return ready;
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  Future<bool> _initialize() async {
    if (!isSupported) return false;

    final update = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      _requestParameters(),
      () async {
        ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) {
            debugPrint('AdMob consent form failed: ${error.message}');
            lastAdIssue = 'zgoda-formularz ${error.errorCode}';
          }
          if (!update.isCompleted) update.complete();
        });
      },
      (error) {
        debugPrint('AdMob consent update failed: ${error.message}');
        lastAdIssue = 'zgoda ${error.errorCode}: ${error.message}';
        if (!update.isCompleted) update.complete();
      },
    );

    try {
      await update.future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      debugPrint('AdMob consent update timed out.');
      lastAdIssue = 'zgoda-timeout';
    }

    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (!_canRequestAds) lastAdIssue ??= 'brak-zgody';
    if (_canRequestAds) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.pg,
          ageRestrictedTreatment: AgeRestrictedTreatment.unspecified,
        ),
      );
      await MobileAds.instance.initialize();
    }
    return _canRequestAds;
  }

  ConsentRequestParameters _requestParameters() {
    if (!kDebugMode) return ConsentRequestParameters();

    const geography = String.fromEnvironment(
      'EXPO_PUBLIC_ADMOB_DEBUG_GEOGRAPHY',
      defaultValue: 'DISABLED',
    );
    const testDeviceId = String.fromEnvironment('ADMOB_TEST_DEVICE_ID');
    if (testDeviceId.isEmpty || geography.toUpperCase() == 'DISABLED') {
      return ConsentRequestParameters();
    }

    final debugGeography = switch (geography.toUpperCase()) {
      'EEA' => DebugGeography.debugGeographyEea,
      'NOT_EEA' => DebugGeography.debugGeographyOther,
      'REGULATED_US_STATE' => DebugGeography.debugGeographyRegulatedUsState,
      _ => DebugGeography.debugGeographyDisabled,
    };
    return ConsentRequestParameters(
      consentDebugSettings: ConsentDebugSettings(
        debugGeography: debugGeography,
        testIdentifiers: const [testDeviceId],
      ),
    );
  }

  Future<bool> isPrivacyOptionsRequired() async {
    await initialize();
    if (!isSupported) return false;
    return await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  }

  Future<void> showPrivacyOptions() async {
    if (!isSupported) return;
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) {
        debugPrint('AdMob privacy options failed: ${error.message}');
      }
      completer.complete();
    });
    await completer.future;
  }

  Future<RewardedAdOutcome> showRewardedTrapAd(String uid) async {
    lastAdIssue = null;
    if (!isSupported || !await initialize()) {
      return RewardedAdOutcome.unavailable;
    }
    final completed = Completer<RewardedAdOutcome>();
    var earnedReward = false;
    RewardedAd.load(
      adUnitId: usesTestRewardedAd
          ? 'ca-app-pub-3940256099942544/1712485313'
          : AppConfig.admobIosRewardedId,
      request: const AdRequest(nonPersonalizedAds: true),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.setServerSideOptions(
            ServerSideVerificationOptions(
              userId: uid,
              customData: 'trap-view-v1',
            ),
          );
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completed.isCompleted) {
                completed.complete(
                  earnedReward
                      ? RewardedAdOutcome.rewarded
                      : RewardedAdOutcome.closedEarly,
                );
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdMob rewarded show failed: $error');
              lastAdIssue = 'wyswietlenie ${error.code}';
              ad.dispose();
              if (!completed.isCompleted) {
                completed.complete(RewardedAdOutcome.unavailable);
              }
            },
          );
          ad.show(onUserEarnedReward: (_, _) => earnedReward = true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob rewarded load failed: $error');
          lastAdIssue = 'ladowanie ${error.code}: ${error.message}';
          if (!completed.isCompleted) {
            completed.complete(RewardedAdOutcome.unavailable);
          }
        },
      ),
    );
    return completed.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => RewardedAdOutcome.unavailable,
    );
  }
}
