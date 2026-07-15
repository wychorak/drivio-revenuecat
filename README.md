# Drivio

Flutter app for driving exam preparation and local driving-school discovery.

## Local configuration

Secrets are not committed. Copy `.env.example` to `.env` for local Flutter runs,
or pass the same values with `--dart-define` in CI/release builds.

For iOS maps, copy `ios/Flutter/Secrets.example.xcconfig` to
`ios/Flutter/Secrets.xcconfig` and set `GOOGLE_MAPS_API_KEY`.

## App Store

See `docs/app_store_launch_checklist.md` for the current launch checklist.
See `docs/in_app_purchase_setup.md` for Premium product IDs and store setup.
