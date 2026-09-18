# Drivio

> Status: release candidate. The application code is implemented; store-console configuration and physical-device QA remain before release.

Drivio is a Flutter application that helps learners prepare for the Polish driving exam, discover nearby driving schools and share road-hazard knowledge.

## Highlights

- email, Google and Apple authentication through Firebase Auth
- maps, driving-school discovery and user-submitted road hazards
- moderated community content and an admin review queue
- RevenueCat subscriptions with weekly, monthly and lifetime products
- AdMob with UMP consent and an ad-free premium entitlement
- App Check-protected account deletion and default-deny Firestore/Storage rules
- authenticated, idempotent RevenueCat webhook syncing Premium to Firestore

## Stack

Flutter, Dart, Riverpod, Firebase Auth, Firestore, Storage, Functions, App Check, Google Maps, RevenueCat, AdMob and Codemagic.

## Local development

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=.env
```

Copy `.env.example` to `.env`. For iOS Maps, copy `ios/Flutter/Secrets.example.xcconfig` to `ios/Flutter/Secrets.xcconfig` and provide `GOOGLE_MAPS_API_KEY`. Secrets are intentionally excluded from version control.

## Quality and release status

The current source passes `flutter analyze`, 10 Flutter tests, 22 Firestore Rules tests and 7 RevenueCat backend tests. Store submission still requires the Firebase, Apple, RevenueCat, AdMob and App Store Connect steps documented in [`docs/app_store_launch_checklist.md`](docs/app_store_launch_checklist.md).

Additional documentation:

- [`docs/in_app_purchase_setup.md`](docs/in_app_purchase_setup.md)
- [`docs/CODEMAGIC_IOS.md`](docs/CODEMAGIC_IOS.md)
- [`docs/partner_handoff.md`](docs/partner_handoff.md)
- [`docs/security.md`](docs/security.md)
- [`docs/remaining_setup.md`](docs/remaining_setup.md)
