import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/build_config.dart';
import '../constants/site.dart';
import '../l10n/strings.dart';

/// A single Open Graph `<meta property=... content=...>` element.
///
/// OGP uses the `property` attribute (not `name`), so these are emitted as
/// raw-attribute metas rather than via `Document.head(meta: ...)`.
Component ogMeta(String property, String content) => meta(attributes: {'property': property, 'content': content});

const String _defaultDescription =
    '2026年、日本国内でFlutterをメインに扱う技術カンファレンス。'
    'FlutterやDartの深い知見を持つ開発者によるセッションを多数企画します。';

/// Default site-wide OGP + description for the home page.
///
/// Page-specific routes (e.g. the sponsor detail page) mount their own
/// `Document.head()` instead of this; since every route renders independently
/// during SSG, exactly one of these is present per generated page (no
/// duplicate `og:*` tags).
class SiteHead extends StatelessComponent {
  const SiteHead({super.key});

  @override
  Component build(BuildContext context) {
    final locale = LocaleScope.of(context);
    // Absolute URLs honor baseHref so they resolve on PR previews too
    // (e.g. .../pr-preview/pr-N/) — not just on production.
    return Document.head(
      meta: const {'description': _defaultDescription},
      children: [
        ogMeta('og:title', 'FlutterKaigi 2026'),
        ogMeta('og:description', _defaultDescription),
        ogMeta('og:image', '$siteOrigin${baseHref}images/ogp.png'),
        ogMeta('og:type', 'website'),
        ogMeta('og:url', '$siteOrigin${locale.linkHref}'),
      ],
    );
  }
}
