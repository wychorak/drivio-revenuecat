import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  Future<bool>? _initializing;
  bool _canRequestAds = false;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> initialize() => _initializing ??= _initialize();

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
}
