# Drivio

> Release candidate — the application and security controls are implemented. Production console configuration, legal-owner details and physical-device QA remain before store submission.

Drivio is a Flutter application for Polish learner drivers. It combines exam preparation, a map of difficult road situations, driving-school discovery and community moderation in one mobile product.

## Product highlights

- Firebase email, Google and Apple authentication
- map-based catalogue of road hazards and driving schools
- saved places, comments, reports and an admin moderation queue
- RevenueCat weekly, monthly and lifetime products
- consent-aware AdMob banner for free users; Premium remains ad-free
- in-app account deletion backed by a protected Cloud Function

## Architecture

| Area | Technology |
| --- | --- |
| Client | Flutter, Dart, Riverpod, GoRouter |
| Identity and data | Firebase Auth, Firestore, Storage |
| Backend | Firebase Functions (TypeScript, Node.js) |
| Integrity | Firebase App Check, Firestore and Storage Security Rules |
| Monetization | RevenueCat, StoreKit / Google Play Billing, AdMob + UMP |
| Delivery | Codemagic |

The client contains only public, platform-restricted identifiers. Service-account credentials, signing keys, private RevenueCat keys and other server secrets must stay in CI or provider consoles and are excluded by `.gitignore`.

## Security and privacy

- Firestore and Storage use default-deny rules with ownership, type and field validation.
- Administrator access is authorized server-side with the Firebase custom claim `admin=true`; an email allowlist only hides admin UI in the client and grants no backend permission.
- Account deletion requires a recent login and a valid App Check token. The backend removes owned content, uploads, the user document and Firebase Auth account.
- Purchase and entitlement fields are not writable by mobile clients.
- Ad requests are non-personalized and are made only after the UMP consent flow.
- Public `traps` and `schools` documents must never contain personal or moderation-only fields.

See [the security notes](docs/security.md) and [Firebase rules audit](docs/firebase_security_audit.json) for boundaries and remaining release work.

## Local setup

Requirements: Flutter compatible with Dart `^3.11.1`, Node.js 22, Java 21 and Firebase CLI for emulator tests.

```bash
flutter pub get
flutter analyze
flutter test

cd functions
npm ci
npm test

cd ../firebase/rules-tests
npm ci
npm run test:emulator
```

Copy `.env.example` to `.env` and provide the public Firebase/Maps/RevenueCat client configuration. For iOS Maps, copy `ios/Flutter/Secrets.example.xcconfig` to `ios/Flutter/Secrets.xcconfig`. Never place private `.p8` keys or service-account JSON in either file.

## Deployment

Build and deploy the backend before enabling account deletion in a release build:

```bash
firebase deploy --only functions,firestore:rules,firestore:indexes,storage \
  --project <FIREBASE_PROJECT_ID>
```

Enable App Check enforcement only after valid TestFlight/Play traffic has been observed. Restrict public API keys in the relevant provider consoles.

## Release status

The repository is a portfolio-quality release candidate, not a claim that the app is live in production. Before submission:

1. fill in the legal operator/controller identity in the in-app terms and privacy policy;
2. configure Firebase, App Check, Apple Sign-In, RevenueCat, AdMob and store products;
3. deploy the callable deletion function and security rules;
4. complete purchase, restore, consent and deletion tests on physical devices.

The detailed handoff is in [the launch checklist](docs/app_store_launch_checklist.md).

## Documentation

- [App Store launch checklist](docs/app_store_launch_checklist.md)
- [RevenueCat / IAP setup](docs/in_app_purchase_setup.md)
- [Codemagic iOS setup](docs/CODEMAGIC_IOS.md)
- [Partner handoff](docs/partner_handoff.md)

## License

Source available for portfolio review. No open-source license is granted.
