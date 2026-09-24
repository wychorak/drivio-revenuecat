import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'Drivio';
  static const String defaultCity = 'Szczecin';
  static const int freeDailyTrapLimit = 5;
  static const int maxSavedTraps = 500;
  static const int maxSavedSchools = 100;

  // Public build-time configuration. These values are not secrets.
  static String get adminEmailsRaw {
    const fromDefine = String.fromEnvironment('ADMIN_EMAILS');
    return fromDefine.isNotEmpty
        ? fromDefine
        : dotenv.env['ADMIN_EMAILS'] ?? '';
  }

  static String get contactEmail {
    const fromDefine = String.fromEnvironment('CONTACT_EMAIL');
    return fromDefine.isNotEmpty
        ? fromDefine
        : dotenv.env['CONTACT_EMAIL'] ?? 'kontakt@drivio.pl';
  }

  static Set<String> get adminEmails => adminEmailsRaw
      .split(RegExp(r'[,;\s]+'))
      .map((email) => email.trim().toLowerCase())
      .where((email) => email.isNotEmpty)
      .toSet();

  // AdMob public identifiers (iOS app only for this release).
  static const String admobIosAppId = 'ca-app-pub-8263324816746737~5489467107';
  static const String admobIosBannerId =
      'ca-app-pub-8263324816746737/9237140422';

  // RevenueCat / App Store
  static const String revenueCatOfferingId = 'driviooffers';
  static const String revenueCatEntitlementId = 'drivio pro relase';
  static const String revenueCatIosPublicKey =
      'appl_FnzZiSQvkgunTrxBSImJzGzmKHU';
  static const String iapWeekly = 'drivioweek';
  static const String iapMonthly = 'driviomonth';
  static const String iapLifetime = 'driviolifetime';

  // Stripe payment links (web fallback)
  static const String stripeWeekly =
      'https://buy.stripe.com/cNi9AU9Yp96S70J1dt1Nu00';
  static const String stripeMonthly =
      'https://buy.stripe.com/8x200k8Ul96S4SB1dt1Nu02';
  static const String stripeYearly =
      'https://buy.stripe.com/fZucN63A13MyfxfbS71Nu01';

  // WORD - exam registration system
  static const String wordUrl = 'https://word.szczecin.pl';

  // Szczecin center coordinates
  // ignore: constant_identifier_names
  static const double szczecin_lat = 53.4289;
  // ignore: constant_identifier_names
  static const double szczecin_lng = 14.5530;

  // Premium pricing display
  static const String priceWeekly = '5,99 zł';
  static const String priceMonthly = '20,99 zł';
  static const String priceLifetime = 'Cena w App Store';
  static const String priceYearly = '190,99 zł';
}
