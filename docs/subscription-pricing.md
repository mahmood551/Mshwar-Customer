# Server subscription quotes

The subscription form now sends both selected coordinates and the schedule to the server. It uses the returned route distance, zone breakdown and total without a local fare or distance calculation. The previous custom square-root approximation returned 24.90 km for subscription #447's coordinates; the server's road-route result was 1.60 km.

## Server contract

The matching backend endpoints are deployed under the existing authenticated API prefix:

- `POST /api/v1/subscription/quote`: accepts `home_latitude`, `home_longitude`, `destination_latitude`, `destination_longitude`, `trip_type`, `start_date`, `end_date`, `working_days`.
- `POST /api/v1/subscription/create-quoted`: accepts the existing creation fields plus `quote_token` from the latest successful quote.

Quote responses retain the existing success/data envelope and add `pickup_zone_fare`, `dropoff_zone_fare`, `zone_fare`, `km_fare`, `quote_token`, and `quote_expires_at`. A quote lasts 15 minutes and is bound to the authenticated customer, coordinates and schedule. Creation persists the quoted pricing snapshot. Changed/expired/tampered quotes fail validation before any subscription is inserted. Pricing components round to KWD fils before multiplying by trip count.

Both Kuwait zone charges remain included, including trips inside the same zone. For #447's inputs and the historical server route result: `(1.6 × 0.150 + 1.150 + 1.150) × 44 = 111.760 KWD`.

The old preview/create endpoints remain available for installed older app versions. Those versions still have the original pricing mismatch; users need a build containing this change to receive the fix. No automatic fallback to the old endpoints is used by this build.

## UI behavior

Changing either location, dates, working days or trip type invalidates the previous quote. Late responses cannot restore an old quote. Missing, failed and expired quotes disable creation and provide a refresh action. A refreshed quote is displayed for review; the app never automatically submits after a price refresh. Zone charges and kilometre charges appear separately in English and Arabic.

## Verification

- `flutter test --no-pub test/subscription_quote_test.dart`: 8 tests pass, covering coordinates, authoritative server values, out-of-order responses, failed/expired quotes, form reset, serialization, and the creation request's quote token.
- Targeted Dart analysis: no errors; existing unused-helper, print and deprecated-withOpacity findings remain in these files.
- Backend: 31 isolated quote/validation checks and 16 SQLite-in-memory controller/persistence checks pass. No live subscriptions or payments were created during tests.
- Flutter 3.47.5 / Dart 3.13.4 used for validation. Dependency lockfile unchanged.

A signed Android/iOS release and device acceptance check are still required. No app-store upload or device installation is performed by this change. Payment, assignment, historical subscriptions and admin-created subscription pricing are outside this patch.
