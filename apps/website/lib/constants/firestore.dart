/// Firestore project the browser reads `counters/profileExchanges` from
/// (see `ExchangeCounterSection`) via the public REST API — no SDK, no
/// auth, matching `firestore.rules`' `counters/{counterId}` being
/// `allow read: if true`.
///
/// Overridable at build time via `--dart-define=FIRESTORE_PROJECT_ID=...`.
/// The production deploy uses the default (the prod project, matching
/// `PROD_FIREBASE_PROJECT_ID` in `.github/APP_DELIVERY.md`); PR previews
/// pass the STG project id so the preview reflects STG data, the same
/// project every other generator (`tool/generate_sponsors.dart` etc.)
/// already reads for a preview build.
///
/// A Firestore project id is a public identifier, not a secret — see
/// `.github/APP_DELIVERY.md`'s note on Firebase API keys / app ids — so
/// baking it into the shipped JS is the same trust boundary every other
/// Firebase client config in this repo already relies on.
const String firestoreProjectId = String.fromEnvironment(
  'FIRESTORE_PROJECT_ID',
  defaultValue: 'flutterkaigi-2026-283db',
);
