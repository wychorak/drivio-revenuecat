# RevenueCat / In-App Purchase Setup

Drivio uses RevenueCat offering `driviooffers` and these App Store products:

| Access | Product ID | RevenueCat package |
| --- | --- | --- |
| Weekly | `drivioweek` | `$rc_weekly` |
| Monthly | `driviomonth` | `$rc_monthly` |
| Lifetime | `driviolifetime` | `$rc_lifetime` |

## RevenueCat

1. Keep `driviooffers` as the current offering.
2. Attach all three products to an entitlement named drivio pro relase.
3. The dashboard REST API identifier entl4135ffeea9 is not used by the mobile SDK; the app checks the entitlement identifier drivio pro relase.
4. Use the iOS public SDK key configured in the Flutter app. It can be overridden with --dart-define=REVENUECAT_IOS_API_KEY=appl_....
5. Add the App Store Connect In-App Purchase key in RevenueCat so RevenueCat can validate StoreKit transactions.
6. Never put an App Store `.p8` private key in the mobile app or repository.

The client reads prices and periods from StoreKit through RevenueCat. It purchases the package, restores purchases on user request, and treats RevenueCat `CustomerInfo` as the immediate Premium source of truth. The Firebase UID is used as RevenueCat `appUserID`.

## App Store Connect

1. `drivioweek` and `driviomonth` should be auto-renewable subscriptions in one subscription group.
2. `driviolifetime` should be a non-consumable lifetime unlock.
3. Complete localization, pricing, review screenshots, tax agreements, and availability for every product.
4. Test purchase, cancellation, renewal, lifetime access, and restore with a Sandbox Tester on a physical iPhone/TestFlight build.

## Firestore

The existing Firestore Premium fields remain as a migration/backend fallback. The Flutter purchase flow does not write entitlement fields directly. If Firestore must mirror RevenueCat, the backend partner should configure RevenueCat webhooks or the RevenueCat Firebase extension and keep security rules blocking client writes to Premium fields.

## Sign in with Apple

Before TestFlight:

1. Enable the Sign in with Apple capability for App ID `com.drivio.app`.
2. Enable Apple in Firebase Authentication with key name driviokey and Key ID 6D43VGP33F. Add the Team ID and private .p8 key when available; configure the Service ID/redirect URI where required.
3. Verify first sign-in, repeat sign-in (Apple may hide name/email), sign-out, and account switching on a physical device.
