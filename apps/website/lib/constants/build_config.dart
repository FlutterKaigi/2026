/// Build-time configuration injected via `--dart-define`.
///
/// `BASE_HREF` is set to `/pr-preview/pr-<N>/` in PR preview builds and `/` (default) in production.
library;

const String baseHref = String.fromEnvironment('BASE_HREF', defaultValue: '/');

const bool isPreviewBuild = baseHref != '/';
