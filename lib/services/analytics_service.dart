import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Google Analytics for Firebase.
///
/// No advertising identifiers or personal data: IDFA collection is off in
/// Info.plist, ad-related consent signals default to denied, and no user ID or
/// e-mail is ever set. Debug builds don't send events, so the dashboards only
/// show real usage (use `-FIRDebugEnabled` with DebugView for testing).
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  String? _lastScreen;

  Future<void> initialize() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
      await _analytics.setConsent(
        analyticsStorageConsentGranted: true,
        adStorageConsentGranted: false,
        adUserDataConsentGranted: false,
        adPersonalizationSignalsConsentGranted: false,
      );
      await _analytics.logAppOpen();
    } catch (error) {
      debugPrint('Analytics init failed: $error');
    }
  }

  /// Logs a screen view for every route change, using the route template
  /// (e.g. `/trap/:id`) so content IDs never end up in screen names.
  void attachToRouter(GoRouter router) {
    void onChange() {
      final screen = router.routerDelegate.currentConfiguration.fullPath;
      if (screen.isEmpty || screen == _lastScreen) return;
      _lastScreen = screen;
      _log(
        () => _analytics.logScreenView(screenName: screen, screenClass: screen),
      );
    }

    router.routerDelegate.addListener(onChange);
  }

  void login(String method) =>
      _log(() => _analytics.logLogin(loginMethod: method));

  void signUp(String method) =>
      _log(() => _analytics.logSignUp(signUpMethod: method));

  void trapView({required String trapId, required bool premium}) =>
      _event('trap_view', {'trap_id': trapId, 'premium': premium ? 1 : 0});

  void trapVideoPlay({required String trapId, required bool freeVideo}) =>
      _event('trap_video_play', {
        'trap_id': trapId,
        'free_video': freeVideo ? 1 : 0,
      });

  void dailyLimitReached() => _event('daily_limit_reached');

  void rewardedAdResult(String outcome) =>
      _event('rewarded_ad', {'outcome': outcome});

  void examBookingOpen() => _event('exam_booking_open');

  void _event(String name, [Map<String, Object>? parameters]) =>
      _log(() => _analytics.logEvent(name: name, parameters: parameters));

  void _log(Future<void> Function() send) {
    send().catchError(
      (Object error) => debugPrint('Analytics event failed: $error'),
    );
  }
}
