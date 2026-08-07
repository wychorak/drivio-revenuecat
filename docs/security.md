# Security notes

Last reviewed: 7 August 2026.

## Trust boundaries

The Flutter client is untrusted. Values supplied with `--dart-define`, Firebase mobile configuration, AdMob IDs and RevenueCat public SDK keys are embedded in the application and must be restricted at the provider level. They are identifiers, not a place for server secrets.

Privileged operations run through Firebase Admin SDK. Firestore/Storage rules grant admin access only when the verified Firebase ID token contains the backend-managed `admin=true` custom claim. The optional `ADMIN_EMAILS` client setting controls UI visibility only.

## Implemented controls

- default-deny Firestore and Storage fallbacks;
- ownership and immutable-field checks for user content;
- type, length, MIME and upload-size validation;
- Firebase App Check activation in the client;
- App Check enforcement and recent-authentication validation for account deletion;
- backend-only entitlement, purchase and daily-limit records;
- secret, signing-key, service-account and infrastructure-state ignore rules;
- emulator tests for important Firestore allow/deny paths.

## Account deletion

The callable `deleteAccount` function removes comments, reports and traps owned by the authenticated UID, recursively deletes the user document, removes files under `traps/{uid}/`, then deletes the Firebase Auth account. It accepts no target UID from the client, requires App Check and rejects authentication older than five minutes.

Deploy the function in `europe-west1` before shipping the client. Provider-side billing/transaction records may need separate retention where legally required and should be documented in the final privacy policy.

## Remaining production work

- restrict Firebase and Maps client keys by app/package and API;
- enable App Check enforcement after monitoring valid production-like traffic;
- add rate limits and abuse monitoring for comments and reports;
- configure RevenueCat webhook authorization and idempotency;
- protect service accounts with least-privilege IAM and MFA for provider consoles;
- add dependency and rules tests to CI;
- run a legal review after operator identity and real retention periods are known.

Report vulnerabilities privately through the contact address configured for the production application. Do not open a public issue containing credentials or personal data.
