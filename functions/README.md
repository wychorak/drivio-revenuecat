# Drivio Firebase Functions

Backend contains:

- `deleteAccount` — App Check-protected account and owned-data cleanup;
- `refreshAdminClaim` — grants the `admin` claim only to a verified allowlisted
  account and marks that account Premium;
- `revenueCatWebhook` — idempotent RevenueCat-to-Firestore Premium sync.
- `getTrapViewStatus` and `consumeDailyTrapView` — App Check-protected daily
  allowance (2 free views, 1 after reward), reset at midnight Europe/Warsaw;
- `admobRewardSsv` — validates Google's ECDSA-signed AdMob callback before
  granting the one rewarded view for the day.

Before deployment, configure the RevenueCat authorization header secret:

```sh
firebase functions:secrets:set REVENUECAT_WEBHOOK_AUTH
```

Deployments are intentionally not automatic. Build and test locally first with
`npm test`. After deployment, use the HTTPS URL of `revenueCatWebhook` in the
RevenueCat dashboard and configure exactly the same authorization header there.
Use the standard `Bearer <REVENUECAT_WEBHOOK_AUTH>` format. The function trims
accidental trailing newlines from the Secret Manager value before comparing it.

All callable functions enforce App Check. Register the local debug token in
Firebase before testing them on an emulator. Deploy Functions before deploying
rules that require the backend-managed `admin=true` custom claim.

## Rewarded trap view (iOS)

The iOS rewarded interstitial unit is
`ca-app-pub-8263324816746737/8516770878`. The deployed SSV callback URL is
`https://europe-west1-drivio-a7d9c.cloudfunctions.net/admobRewardSsv`.
Copy it into this unit's AdMob
server-side verification (SSV) settings. Without that callback, watching the
ad cannot grant a view. The ordinary full-screen/interstitial unit is not a
substitute. Do not add a query string or secret to the callback URL; the
function verifies Google's signature and checks the configured ad unit.

The Flutter debug build uses Google's sample ad unit, which does not send SSV
to Drivio. To test end to end, register the physical iPhone as an AdMob test
device and build with `--dart-define=USE_LIVE_REWARDED_AD=true`; confirm the
ad is labelled Test. Never click production ads on a non-test device during
development.

Deploy the new Functions before the updated Firestore rules and app build.
The new rules stop legacy clients from writing `users/{uid}/usage/trapViews`;
coordinate the rollout if any older app builds are still in use. Android needs
its own production AdMob app and rewarded unit before this reward is available
there. Do not report the feature as live until the SSV callback and a physical
iPhone test succeed.
