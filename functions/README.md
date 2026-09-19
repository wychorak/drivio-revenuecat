# Drivio Firebase Functions

Backend contains:

- `deleteAccount` — App Check-protected account and owned-data cleanup;
- `refreshAdminClaim` — grants the `admin` claim only to a verified allowlisted
  account and marks that account Premium;
- `revenueCatWebhook` — idempotent RevenueCat-to-Firestore Premium sync.

Before deployment, configure the RevenueCat authorization header secret:

```sh
firebase functions:secrets:set REVENUECAT_WEBHOOK_AUTH
```

Deployments are intentionally not automatic. Build and test locally first with
`npm test`. After deployment, use the HTTPS URL of `revenueCatWebhook` in the
RevenueCat dashboard and configure exactly the same authorization header there.

Both callable functions enforce App Check. Register the local debug token in
Firebase before testing them on an emulator. Deploy Functions before deploying
rules that require the backend-managed `admin=true` custom claim.
