import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/generated_tokens.dart';
import '../constants/theme.dart';
import '../l10n/strings.dart';

class Header extends StatelessComponent {
  const Header({this.altLocaleHref, super.key});

  /// Navigation target for the language switch — the equivalent page in the
  /// *other* locale. When null, falls back to the other locale's home (used on
  /// pages where there's no per-locale counterpart).
  final String? altLocaleHref;

  // 有効化済み nav アイテム。locale が必要なものは build() 内で組み立てる。
  // TODO: Uncomment when each section is ready:
  // (label: 'Event Info', href: '#event-info')
  // (label: 'Timeline', href: '#timeline')
  // (label: 'Sponsors', href: '#sponsors')

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    // locale 対応のアンカー href: ホーム外ページからでも正しくトップへ飛べる
    final navItems = <({String label, String href})>[
      (label: 'Job Boards', href: strings.locale.jobBoardsAnchorHref),
    ];
    return header([
      a(href: strings.locale.linkHref, classes: 'brand', [.text('FlutterKaigi 2026')]),
      if (navItems.isNotEmpty)
        nav(
          classes: 'nav',
          attributes: const {'aria-label': 'Primary'},
          [
            for (final item in navItems)
              a(href: item.href, classes: 'nav__link', [
                .text(item.label),
                span(
                  classes: 'nav__dot',
                  attributes: const {'aria-hidden': 'true'},
                  [],
                ),
              ]),
          ],
        ),
      div(classes: 'actions', [
        // a(href: '#tickets', classes: 'btn btn--primary', [.text('Get Tickets')]),
        a(
          href: altLocaleHref ?? strings.other.linkHref,
          classes: 'lang lang--${strings.locale.code}',
          attributes: {
            'aria-label': 'Switch to ${strings.languageToggleLabel}',
            'hreflang': strings.other.code,
          },
          [
            img(
              classes: 'lang__icon',
              src: 'images/icons/icon.svg',
              alt: '',
              attributes: const {'aria-hidden': 'true'},
            ),
            span(classes: 'lang__label', [
              span(classes: 'lang__option lang__option--en', [.text('EN')]),
              span(classes: 'lang__separator', [.text(' / ')]),
              span(classes: 'lang__option lang__option--ja', [.text('JA')]),
            ]),
          ],
        ),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('header', [
      css('&').styles(
        position: .sticky(top: 0.px),
        display: .flex,
        width: 100.percent,
        padding: .symmetric(horizontal: 2.em, vertical: 1.em),
        alignItems: .center,
        backgroundColor: onBrand,
        color: onSurface,
        zIndex: const ZIndex(10),
        gap: Gap.column(1.5.em),
        raw: const {
          'box-shadow': '0 1px 0 rgba(29, 27, 32, 0.08)',
        },
      ),
      css('a').styles(
        textDecoration: const TextDecoration(line: TextDecorationLine.none),
      ),
      css('.brand').styles(
        color: onSurface,
        fontFamily: displayFontFamily,
        fontWeight: .w700,
        raw: {
          // Title-large M3 token but bumped to bold for brand identity.
          ...tokenFontCss(fontM3TitleLarge),
          'font-size': '1.125rem',
          'min-width': '0',
          'flex-shrink': '1',
          'overflow': 'hidden',
          'text-overflow': 'ellipsis',
          'white-space': 'nowrap',
        },
      ),
      css('.actions').styles(
        display: .flex,
        alignItems: .center,
        gap: Gap.column(0.75.em),
        raw: const {'margin-left': 'auto'},
      ),
      css('.nav', [
        css('&').styles(
          display: .flex,
          flex: const Flex(grow: 1),
          justifyContent: .center,
          gap: Gap.column(2.5.em),
        ),
        css('.nav__link', [
          css('&').styles(
            position: .relative(),
            color: onSurface,
            fontFamily: uiFontFamily,
            fontWeight: tokenWeight(fontM3LabelLarge.fontWeight),
            raw: {
              ...tokenFontCss(fontM3LabelLarge),
              'transition': 'color 150ms ease',
            },
          ),
          css('&:hover').styles(color: deepPurple),
          // 注目ドット: リンクの右肩に小さな Magenta Red の円を表示。
          // class 名は "nav__dot"（広告ブロッカー対象の命名を避ける）。
          css('.nav__dot').styles(
            position: .absolute(top: (-3).px, right: (-7).px),
            width: 6.px,
            height: 6.px,
            backgroundColor: magentaRed,
            radius: .circular(999.px),
            raw: const {'display': 'block', 'pointer-events': 'none'},
          ),
        ]),
      ]),
      css('.btn', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          padding: .symmetric(horizontal: 1.25.em, vertical: 0.6.em),
          fontFamily: uiFontFamily,
          fontWeight: .w600,
          radius: .circular(999.px),
          raw: {
            ...tokenFontCss(fontM3LabelLarge),
            'transition': 'background-color 150ms ease',
          },
        ),
        css('&.btn--primary', [
          css('&').styles(
            backgroundColor: deepPurple,
            color: onBrand,
          ),
          css('&:hover').styles(
            backgroundColor: const Color('#5000C8'),
          ),
        ]),
      ]),
      css('.lang', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          gap: Gap.column(0.4.em),
          padding: .symmetric(horizontal: 1.em, vertical: 0.5.em),
          color: onSurface,
          fontFamily: uiFontFamily,
          fontWeight: tokenWeight(fontM3LabelLarge.fontWeight),
          radius: .circular(999.px),
          border: Border.all(style: BorderStyle.solid, color: outlineColor, width: 1.px),
          raw: {
            ...tokenFontCss(fontM3LabelMedium),
            'transition': 'background-color 150ms ease',
          },
        ),
        css('&:hover').styles(
          backgroundColor: const Color('#1D1B2010'),
        ),
        css('.lang__icon').styles(
          width: 1.1.em,
          height: 1.1.em,
        ),
        css('&.lang--ja .lang__option--ja').styles(
          raw: const {
            'text-decoration': 'underline',
            'text-underline-offset': '0.2em',
          },
        ),
        css('&.lang--en .lang__option--en').styles(
          raw: const {
            'text-decoration': 'underline',
            'text-underline-offset': '0.2em',
          },
        ),
      ]),
    ]),

    css.media(MediaQuery.all(maxWidth: 960.px), [
      css('header .nav').styles(raw: const {'display': 'none'}),
    ]),
    css.media(MediaQuery.all(maxWidth: 720.px), [
      css('header', [
        css('&').styles(
          padding: .symmetric(horizontal: 0.75.em, vertical: 0.6.em),
          gap: Gap.column(0.5.em),
        ),
        css('.brand').styles(raw: const {'font-size': '0.95rem'}),
        // Drop the Get Tickets CTA on mobile so brand + language switch fit comfortably.
        css('.btn.btn--primary').styles(raw: const {'display': 'none'}),
        css('.lang', [
          css('&').styles(
            border: Border.none,
            padding: .all(0.45.em),
          ),
          css('.lang__label').styles(raw: const {'display': 'none'}),
        ]),
      ]),
    ]),
  ];
}
