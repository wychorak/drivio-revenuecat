import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:drivio/config/app_config.dart';

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
          }
          if (!update.isCompleted) update.complete();
        });
      },
      (error) {
        debugPrint('AdMob consent update failed: ${error.message}');
        if (!update.isCompleted) update.complete();
      },
    );

    try {
      await update.future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      debugPrint('AdMob consent update timed out.');
    }

    _canRequestAds = await ConsentInformation.instance.canRequestAds();
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

  Future<bool> showRewardedTrapAd(String uid) async {
    if (!isSupported || !await initialize()) return false;
    final completed = Completer<bool>();
    var earnedReward = false;
    RewardedInterstitialAd.load(
      adUnitId: usesTestRewardedAd
          ? 'ca-app-pub-3940256099942544/6978759866'
          : AppConfig.admobIosRewardedId,
      request: const AdRequest(nonPersonalizedAds: true),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
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
              if (!completed.isCompleted) completed.complete(earnedReward);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdMob rewarded show failed: $error');
              ad.dispose();
              if (!completed.isCompleted) completed.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (_, _) => earnedReward = true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob rewarded load failed: $error');
          if (!completed.isCompleted) completed.complete(false);
        },
      ),
    );
    return completed.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => false,
    );
  }
}
