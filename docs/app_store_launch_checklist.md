# Drivio App Store Launch Checklist

## Done in this branch

- iOS bundle identifier changed from `com.example.drivio` to `com.drivio.com`.
- Android application id changed from `com.example.drivio` to `com.drivio.app`.
- `.env` loading is optional and `.env` is no longer bundled as a Flutter asset.
- Firebase config now reads from `--dart-define` or local `.env` instead of committed placeholders.
- Google Maps API key was removed from source code and Android manifest.
- iOS permission descriptions were added for location, camera, and photo library.
- iOS `PrivacyInfo.xcprivacy` was added to the Runner target.
- Mobile Premium purchase flow no longer falls back to Stripe when App Store / Play products are missing.
- Basic UGC safeguards were added: client-side text filtering, reporting, blocking authors, and filtering blocked users.
- Default Flutter app icon was replaced with a temporary Drivio icon.
- Legal copy was aligned with the current no-ads implementation and mobile IAP flow.

## Required before TestFlight / App Store submission

- Create the Apple Developer App ID for `com.drivio.com`.
- Set the real Xcode development team and signing profiles.
- Create App Store Connect app record, SKU, category, age rating, screenshots, support URL, marketing URL, and privacy policy URL.
- Finish the App Store products `drivioweek`, `driviomonth`, and `driviolifetime`.
- Keep RevenueCat offering driviooffers current and attach every product to the drivio pro relase entitlement.
- Configure RevenueCat with the App Store Connect In-App Purchase key for server-side transaction validation.
- Enable Sign in with Apple for App ID com.drivio.com and in Firebase Authentication using Apple key ID 6D43VGP33F (driviokey).
- Test weekly/monthly renewal, lifetime purchase, cancellation, restore, and account switching on a physical iPhone.
- Create a real Firebase project and configure Firebase Auth, Firestore, Storage, and production security rules.
- Supply Firebase values using `--dart-define` or local `.env`.
- Copy `ios/Flutter/Secrets.example.xcconfig` to `ios/Flutter/Secrets.xcconfig` and fill `GOOGLE_MAPS_API_KEY`.
- Add Android `GOOGLE_MAPS_API_KEY` to Gradle properties for Android builds.
- Replace the `GOOGLE_MAPS_API_KEY` placeholder in `web/index.html` during a production web build.
- Replace the temporary generated icon with final brand artwork.
- Review `PrivacyInfo.xcprivacy` against the final SDK list and the final App Store privacy questionnaire.
- Add moderation operations for admins: queue review, hide/delete content, block users, and respond to reports quickly.
- Run a real archive on macOS with Xcode, upload to TestFlight, and test purchases with sandbox testers.
