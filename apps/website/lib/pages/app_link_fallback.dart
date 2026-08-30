import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/generated_tokens.dart';
import '../constants/theme.dart';

/// Static fallback for `/x/*` — the profile-exchange share link
/// (`https://2026.flutterkaigi.jp/x/<token>`, see the Flutter app's
/// `apps/app/lib/feature/exchange/data/exchange_link.dart`) opened in a
/// browser that doesn't have (or can't open into) the app.
///
/// This single static page (`build/jaspr/x/index.html`, from the `/x` route
/// below) is served for every `/x/<token>` request via `web/_redirects`
/// (`/x/* /x/index.html 200`, a same-URL rewrite handled entirely at the
/// Cloudflare edge from the static asset store) — the token in the path is
/// never sent to, or read by, any server. On a device with the app
/// installed and Universal Links / App Links verified (see
/// `web/.well-known/README.md`), the OS hands the link to the app before it
/// ever reaches this page.
///
/// Locale-agnostic by necessity: unlike the rest of the site (one generated
/// page per [AppLocale]), this single static file is what every `/x/*`
/// request resolves to regardless of the visitor's language, so both
/// languages are shown together rather than picking one at build time.
class AppLinkFallbackPage extends StatelessComponent {
  const AppLinkFallbackPage({super.key});

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      Document.head(
        meta: const {
          'description': 'Open this link in the FlutterKaigi 2026 app to exchange profiles.',
          // Not a content page — keep it out of search results.
          'robots': 'noindex,nofollow',
        },
      ),
      section(classes: 'app-link-fallback', [
        div(classes: 'app-link-fallback__card', [
          img(
            classes: 'app-link-fallback__logo',
            src: 'images/logo.svg',
            alt: 'FlutterKaigi 2026',
          ),
          h1(classes: 'app-link-fallback__title', [
            .text('プロフィール交換'),
            br(),
            .text('Profile Exchange'),
          ]),
          p(classes: 'app-link-fallback__body', [
            .text(
              'FlutterKaigi 2026 アプリでこのリンクを開くと、プロフィールを交換できます。'
              'アプリをお持ちでない場合は、入手方法についてイベント情報をご確認ください。',
            ),
          ]),
          p(classes: 'app-link-fallback__body app-link-fallback__body--en', [
            .text(
              'Open this link in the FlutterKaigi 2026 app to exchange profiles. '
              "If it didn't open automatically and you don't have the app yet, "
              'check the event page for how to get it.',
            ),
          ]),
          a(href: '/', classes: 'app-link-fallback__cta', [
            .text('FlutterKaigi 2026 トップページへ / Back to FlutterKaigi 2026'),
          ]),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.app-link-fallback', [
      css('&').styles(
        display: .flex,
        alignItems: .center,
        justifyContent: .center,
        width: 100.percent,
        minHeight: 100.vh,
        padding: .all(24.px),
        raw: const {
          'background':
              'linear-gradient(160deg, $colorKeycolorsDeepnavyHex 0%, '
              '$colorKeycolorsPrimaryHex 55%, $colorKeycolorsMagentaredHex 100%)',
        },
      ),
      css('.app-link-fallback__card').styles(
        display: .flex,
        flexDirection: .column,
        alignItems: .center,
        width: 100.percent,
        gap: Gap.row(16.px),
        padding: .all(40.px),
        backgroundColor: onBrand,
        radius: .circular(20.px),
        raw: const {
          'max-width': '480px',
          'text-align': 'center',
          'box-shadow': '0 24px 48px rgba(29, 26, 32, 0.24)',
        },
      ),
      css('.app-link-fallback__logo').styles(height: 40.px, raw: const {'width': 'auto'}),
      css('.app-link-fallback__title').styles(
        color: const Color('#1D1A25'),
        fontFamily: displayFontFamily,
        fontWeight: .w700,
        raw: const {'font-size': 'clamp(1.25rem, 4vw, 1.5rem)', 'line-height': '1.4', 'margin': '0'},
      ),
      css('.app-link-fallback__body').styles(
        color: const Color('#494456'),
        fontFamily: uiFontFamily,
        raw: const {'font-size': '15px', 'line-height': '1.7', 'margin': '0'},
      ),
      css('.app-link-fallback__body--en').styles(
        color: onSurfaceVariant,
        raw: const {'font-size': '14px'},
      ),
      css('.app-link-fallback__cta', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          justifyContent: .center,
          width: 100.percent,
          padding: .symmetric(horizontal: 20.px, vertical: 12.px),
          color: onBrand,
          fontFamily: uiFontFamily,
          fontWeight: .w500,
          radius: .circular(999.px),
          textDecoration: const TextDecoration(line: TextDecorationLine.none),
          raw: const {'background': '#65558F', 'font-size': '15px', 'margin-top': '8px'},
        ),
        css('&:hover').styles(raw: const {'background': '#4700AF'}),
      ]),
    ]),
  ];
}
