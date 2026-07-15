class AppConfig {
  static const String appName = 'Drivio';
  static const String defaultCity = 'Szczecin';
  static const int freeDailyTrapLimit = 5;

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

  // Trial days
  static const int trialDays = 2;
}
