/// Public store listing URLs for the FlutterKaigi 2026 app.
///
/// `null` until each store listing is public — see `.github/APP_DELIVERY.md`
/// (`Deploy App iOS` / `Deploy App Android` currently ship to TestFlight /
/// Google Play Internal Testing only, not a public listing). The share-link
/// fallback page (`ShareLinkFallbackPage`) shows a "coming soon" notice
/// instead of a store button while its URL is `null`.
library;

const String? iosAppStoreUrl = null;

const String? androidPlayStoreUrl = null;
