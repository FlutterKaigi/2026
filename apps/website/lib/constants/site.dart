import 'generated_link_origins.dart';

/// Canonical production origin, used to build absolute URLs such as the OGP
/// `og:image` / `og:url`. Defined in `tool/app_link_hosts.json`.
///
/// Overridable at build time via `--dart-define=SITE_ORIGIN=...`. The production
/// deploy uses the default (the custom domain); PR previews pass an **empty**
/// value so the OGP `og:image`/`og:url` become host-relative and resolve against
/// whatever origin actually serves the preview (a per-version `*.workers.dev`
/// URL). Without this, a preview's `og:image` points at the production domain,
/// where the (git-ignored, build-time-generated) per-sponsor image does not yet
/// exist — so the card image 404s and the OGP appears broken.
const String siteOrigin = String.fromEnvironment(
  'SITE_ORIGIN',
  defaultValue: officialWebsiteOrigin,
);
