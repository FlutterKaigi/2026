import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/app_delivery.dart';
import '../constants/theme.dart';
import '../l10n/strings.dart';

/// Fallback page for `https://2026.flutterkaigi.jp/x/<token>` opened in a
/// browser instead of the app (no app installed, so the Universal Link /
/// App Link didn't intercept it).
///
/// One static page serves every token — `apps/website/worker.js` routes
/// every `/x/*` request here (see its doc comment). The token itself is
/// never read or rendered: whoever opened this link already has it in the
/// URL bar, and there's nothing this page could usefully do with it (the
/// actual exchange only happens inside the app), so echoing it back would
/// only add a second place it's visible to anyone looking over the visitor's
/// shoulder or screen-sharing.
///
/// The full URL — token included — is also kept from leaving the browser by
/// other means: `_ShareLinkFallbackShell` omits `Analytics` (its
/// `gtag('config', ...)` would otherwise fire an automatic `page_view`
/// carrying `page_location`) and sets `<meta name="referrer"
/// content="no-referrer">` so no request this page makes carries the URL out
/// as a Referer header either.
class ShareLinkFallbackPage extends StatelessComponent {
  const ShareLinkFallbackPage({super.key});

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);

    return section(classes: 'share-link-fallback', [
      div(classes: 'share-link-fallback__card', [
        h1(classes: 'share-link-fallback__title', [.text(strings.shareLinkPageTitle)]),
        p(classes: 'share-link-fallback__lead', [.text(strings.shareLinkPageLead)]),
        p(classes: 'share-link-fallback__hint', [.text(strings.shareLinkPageAppInstalledHint)]),
        if (iosAppStoreUrl case final url?)
          a(href: url, classes: 'share-link-fallback__store', [.text(strings.shareLinkPageGetIos)]),
        if (androidPlayStoreUrl case final url?)
          a(href: url, classes: 'share-link-fallback__store', [.text(strings.shareLinkPageGetAndroid)]),
        if (iosAppStoreUrl == null && androidPlayStoreUrl == null)
          p(classes: 'share-link-fallback__coming-soon', [.text(strings.shareLinkPageComingSoon)]),
        a(href: strings.locale.linkHref, classes: 'share-link-fallback__back', [
          .text(strings.shareLinkPageBackHome),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.share-link-fallback', [
      css('&').styles(
        display: .flex,
        flex: const Flex(grow: 1),
        alignItems: .center,
        justifyContent: .center,
        width: 100.percent,
        padding: .symmetric(horizontal: 24.px, vertical: 64.px),
        backgroundColor: const Color('#FDF7FF'),
      ),
      css('.share-link-fallback__card').styles(
        display: .flex,
        flexDirection: .column,
        alignItems: .center,
        gap: Gap.row(16.px),
        maxWidth: 480.px,
        padding: .all(40.px),
        backgroundColor: onBrand,
        radius: .circular(24.px),
        border: Border.all(style: BorderStyle.solid, color: outlineColor, width: 1.px),
        textAlign: .center,
      ),
      css('.share-link-fallback__title').styles(
        color: onSurface,
        fontFamily: displayFontFamily,
        fontWeight: .w700,
        raw: const {'font-size': '1.75rem', 'margin': '0'},
      ),
      css('.share-link-fallback__lead').styles(
        color: onSurface,
        fontFamily: uiFontFamily,
        raw: const {'font-size': '1rem', 'line-height': '1.6', 'margin': '0'},
      ),
      css('.share-link-fallback__hint').styles(
        color: onSurfaceVariant,
        fontFamily: uiFontFamily,
        raw: const {'font-size': '0.875rem', 'line-height': '1.6', 'margin': '0'},
      ),
      css('.share-link-fallback__coming-soon').styles(
        color: onSurfaceVariant,
        fontFamily: uiFontFamily,
        raw: const {'font-size': '0.875rem', 'margin': '8px 0 0'},
      ),
      css('.share-link-fallback__store', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          justifyContent: .center,
          width: 100.percent,
          padding: .symmetric(horizontal: 20.px, vertical: 12.px),
          backgroundColor: deepPurple,
          color: onBrand,
          fontFamily: uiFontFamily,
          fontWeight: .w600,
          radius: .circular(999.px),
          textDecoration: const TextDecoration(line: TextDecorationLine.none),
          raw: const {'margin-top': '8px', 'transition': 'background-color 150ms ease'},
        ),
        css('&:hover').styles(backgroundColor: const Color('#5000C8')),
      ]),
      css('.share-link-fallback__back').styles(
        color: deepPurple,
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        raw: const {'margin-top': '8px'},
      ),
    ]),
  ];
}
