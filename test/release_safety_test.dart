import 'package:flutter_test/flutter_test.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/services/content_moderation_service.dart';
import 'package:drivio/services/revenuecat_service.dart';

void main() {
  group('release configuration', () {
    test('RevenueCat product identifiers stay complete and ordered', () {
      expect(RevenueCatService.productOrder, hasLength(3));
      expect(
        RevenueCatService.productOrder.toSet(),
        RevenueCatService.productIds,
      );
      expect(AppConfig.revenueCatEntitlementId, 'drivio pro relase');
      expect(AppConfig.revenueCatOfferingId, 'driviooffers');
      expect(AppConfig.revenueCatIosPublicKey, startsWith('appl_'));
    });

    test('AdMob identifiers use the expected iOS application', () {
      expect(
        AppConfig.admobIosAppId,
        matches(RegExp(r'^ca-app-pub-\d{16}~\d{10}$')),
      );
      expect(
        AppConfig.admobIosBannerId,
        matches(RegExp(r'^ca-app-pub-\d{16}/\d{10}$')),
      );
      expect(
        AppConfig.admobIosRewardedId,
        matches(RegExp(r'^ca-app-pub-\d{16}/\d{10}$')),
      );
    });

    test('production limits are bounded', () {
      expect(AppConfig.freeDailyTrapLimit, 2);
      expect(AppConfig.rewardedDailyTrapLimit, 1);
      expect(AppConfig.maxSavedTraps, lessThanOrEqualTo(500));
      expect(AppConfig.maxSavedSchools, lessThanOrEqualTo(100));
    });
  });

  group('content moderation', () {
    test('accepts ordinary driving advice', () {
      expect(
        ContentModerationService.validateText(
          'Zwolnij przed skrzyżowaniem i sprawdź pierwszeństwo.',
        ),
        isNull,
      );
    });

    test('rejects empty, abusive and repeated-character spam', () {
      expect(ContentModerationService.validateText('   '), isNotNull);
      expect(
        ContentModerationService.validateText('To jest kurwa złe'),
        isNotNull,
      );
      expect(ContentModerationService.validateText('aaaaaaaaaaaa'), isNotNull);
    });

    test('rejects messages with multiple links', () {
      expect(
        ContentModerationService.validateText(
          'https://example.com i https://spam.example',
        ),
        isNotNull,
      );
    });
  });
}
