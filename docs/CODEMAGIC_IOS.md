# Codemagic iOS setup

The root codemagic.yaml contains the ios-release workflow for a signed Drivio IPA and TestFlight upload.

## Required Codemagic setup

1. Connect the GitHub repository wychorak/drivio-revenuecat and select codemagic.yaml.
2. Keep an App Store Connect integration named wychor appstoreconnectkey.
3. The integration must use an App Store Connect API key with access to certificates, profiles and TestFlight. Do not use the Sign in with Apple key driviokey or the RevenueCat In-App Purchase key here.
4. Create an environment-variable group named drivio_secrets.
5. Add these values to the group and mark sensitive values Secure:
   - GOOGLE_MAPS_API_KEY
   - FIREBASE_IOS_API_KEY
   - FIREBASE_IOS_APP_ID
   - FIREBASE_MESSAGING_SENDER_ID
   - FIREBASE_PROJECT_ID
   - FIREBASE_STORAGE_BUCKET
   - REVENUECAT_IOS_API_KEY (optional because the public iOS SDK key has a code fallback)
6. Keep an Apple Distribution certificate and an App Store provisioning profile for com.drivio.app available to Codemagic automatic signing.
7. Run the ios-release workflow.

## Fixed identifiers

- Bundle ID: com.drivio.app
- App Store Apple ID: 6776345734
- RevenueCat offering: driviooffers
- RevenueCat entitlement: drivio pro relase

The workflow validates required variables, installs CocoaPods, analyzes and tests Flutter, creates a signed IPA and uploads it to TestFlight. It does not submit the app for App Review.