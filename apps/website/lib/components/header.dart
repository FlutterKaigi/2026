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

  // TODO: Timeline を追加する場合はここに追記する。

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    final locale = strings.locale;
    // ナビリンク定義（desktop nav と mobile panel で共用）。
    final navLinks = [
      (label: 'Event Info', href: locale.eventInfoAnchorHref),
      (label: 'Sponsors', href: locale.sponsorsAnchorHref),
      (label: 'Staff', href: locale.staffAnchorHref),
      (label: 'Job Boards', href: locale.jobBoardsAnchorHref),
    ];
    return header([
      a(href: locale.linkHref, classes: 'brand', [.text('FlutterKaigi 2026')]),
      // Desktop nav（≤960px で非表示）。
      nav(
        classes: 'nav',
        attributes: const {'aria-label': 'Primary'},
        [
          for (final item in navLinks) a(href: item.href, classes: 'nav__link', [.text(item.label)]),
        ],
      ),
      div(classes: 'actions', [
        // a(href: '#tickets', classes: 'btn btn--primary', [.text('Get Tickets')]),
        a(
          href: altLocaleHref ?? strings.other.linkHref,
          classes: 'lang lang--${locale.code}',
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
      // Mobile hamburger（>960px で非表示）。
      // <details> を利用して JS なしで開閉を実現。アクセシビリティ上の補足:
      // summary に aria-label を付与してスクリーンリーダーに用途を伝える。
      // role="navigation" は panel 内の <nav> が担うため details 自体には不要。
      details(classes: 'mob-nav', [
        summary(
          classes: 'mob-nav__btn',
          attributes: {'aria-label': strings.navMenuAriaLabel},
          [
            span(classes: 'mob-nav__icon', attributes: const {'aria-hidden': 'true'}, []),
          ],
        ),
        nav(
          classes: 'mob-nav__panel',
          attributes: const {'aria-label': 'Primary'},
          [
            for (final item in navLinks) a(href: item.href, classes: 'mob-nav__link', [.text(item.label)]),
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
            color: onSurface,
            fontFamily: uiFontFamily,
            fontWeight: tokenWeight(fontM3LabelLarge.fontWeight),
            raw: {
              ...tokenFontCss(fontM3LabelLarge),
              'transition': 'color 150ms ease',
            },
          ),
          css('&:hover').styles(color: deepPurple),
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

    // ── Mobile hamburger ─────────────────────────────────────────────────
    css('.mob-nav', [
      // モバイル専用: desktop では非表示。
      css('&').styles(raw: const {'display': 'none'}),

      // <summary> のデフォルトマーカー（▶）を消してボタン化。
      css('.mob-nav__btn', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          justifyContent: .center,
          width: 40.px,
          height: 40.px,
          color: onSurface,
          radius: .circular(8.px),
          raw: const {
            'cursor': 'pointer',
            'list-style': 'none',
            'user-select': 'none',
            '-webkit-appearance': 'none',
          },
        ),
        css('&::-webkit-details-marker').styles(raw: const {'display': 'none'}),
        css('&::marker').styles(raw: const {'display': 'none'}),
        css('&:hover').styles(backgroundColor: const Color('#1D1B2010')),
        css('&:focus-visible').styles(
          raw: const {'outline': '2px solid #65558F', 'outline-offset': '2px'},
        ),
      ]),

      // CSS だけで描くハンバーガーアイコン（3本線 → ✕ アニメーション）。
      // ::before / ::after で上下の線を作り、中央線は要素本体。
      css('.mob-nav__icon', [
        css('&').styles(
          display: .block,
          position: .relative(),
          width: 20.px,
          height: 2.px,
          backgroundColor: onSurface,
          raw: const {'transition': 'background-color 200ms ease, transform 200ms ease'},
        ),
        css('&::before').styles(
          position: .absolute(top: (-6).px, left: 0.px),
          width: 100.percent,
          height: 100.percent,
          backgroundColor: onSurface,
          raw: const {'content': '""', 'transition': 'top 200ms ease, transform 200ms ease'},
        ),
        css('&::after').styles(
          position: .absolute(top: 6.px, left: 0.px),
          width: 100.percent,
          height: 100.percent,
          backgroundColor: onSurface,
          raw: const {'content': '""', 'transition': 'top 200ms ease, transform 200ms ease'},
        ),
      ]),

      // open 時: 中央線を消して上下線をクロスさせて ✕ に。
      css('&[open] .mob-nav__icon').styles(
        raw: const {'background-color': 'transparent'},
      ),
      css('&[open] .mob-nav__icon::before').styles(
        raw: const {'top': '0', 'transform': 'rotate(45deg)'},
      ),
      css('&[open] .mob-nav__icon::after').styles(
        raw: const {'top': '0', 'transform': 'rotate(-45deg)'},
      ),

      // パネル: sticky header の直下に absolute で展開。
      // header は position: sticky なので containing block になる。
      css('.mob-nav__panel', [
        css('&').styles(
          position: .absolute(top: 100.percent, left: 0.px, right: 0.px),
          display: .flex,
          flexDirection: .column,
          backgroundColor: onBrand,
          raw: const {
            'box-shadow': '0 4px 16px rgba(29, 26, 32, 0.12)',
            'padding': '8px 16px 16px',
            'gap': '2px',
          },
        ),
        css('.mob-nav__link', [
          css('&').styles(
            display: .block,
            padding: .symmetric(horizontal: 12.px, vertical: 14.px),
            color: onSurface,
            fontFamily: uiFontFamily,
            fontWeight: tokenWeight(fontM3LabelLarge.fontWeight),
            radius: .circular(8.px),
            raw: {
              ...tokenFontCss(fontM3LabelLarge),
              'transition': 'background-color 150ms ease',
            },
          ),
          css('&:hover').styles(backgroundColor: const Color('#1D1B2010')),
        ]),
      ]),
    ]),

    css.media(MediaQuery.all(maxWidth: 960.px), [
      css('header .nav').styles(raw: const {'display': 'none'}),
      css('header .mob-nav').styles(raw: const {'display': 'block'}),
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
