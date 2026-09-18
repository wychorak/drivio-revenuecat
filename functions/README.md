# Drivio Firebase Functions

Backend contains:

- `deleteAccount` — authenticated account and owned-data cleanup;
- `refreshAdminClaim` — grants the `admin` claim only to the verified release admin;
- `revenueCatWebhook` — idempotent RevenueCat-to-Firestore Premium sync.

Before deployment, configure the RevenueCat authorization header secret:

```sh
firebase functions:secrets:set REVENUECAT_WEBHOOK_AUTH
```

Deployments are intentionally not automatic. Build and test locally first with
`npm test`. After deployment, use the HTTPS URL of `revenueCatWebhook` in the
RevenueCat dashboard and configure exactly the same authorization header there.
