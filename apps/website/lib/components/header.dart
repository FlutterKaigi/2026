import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/generated_tokens.dart';
import '../constants/theme.dart';

class Header extends StatelessComponent {
  const Header({super.key});

  static const _navItems = <({String label, String href})>[
    // TODO: Create link
    // (label: 'Event Info', href: '#event-info'),
    // (label: 'Timeline', href: '#timeline'),
    // (label: 'Sponsors', href: '#sponsors'),
    // (label: 'Job Board', href: '#job-board'),
  ];

  @override
  Component build(BuildContext context) {
    return header([
      a(href: '/', classes: 'brand', [.text('FlutterKaigi 2026')]),
      nav(
        classes: 'nav',
        attributes: const {'aria-label': 'Primary'},
        [
          for (final item in _navItems)
            a(href: item.href, classes: 'nav__link', [.text(item.label)]),
        ],
      ),
      // TODO: Create Action
      // div(classes: 'actions', [
      //   a(href: '#tickets', classes: 'btn btn--primary', [.text('Get Tickets')]),
      //   a(
      //     href: '#lang',
      //     classes: 'lang',
      //     attributes: const {'aria-label': 'Language'},
      //     [
      //       _GlobeIcon(),
      //       span(classes: 'lang__label', [.text('EN / JA')]),
      //     ],
      //   ),
      // ]),
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
        backgroundColor: surface,
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
            ...tokenFontCss(fontM3LabelLarge),
            'transition': 'background-color 150ms ease',
          },
        ),
        css('&:hover').styles(
          backgroundColor: const Color('#1D1B2010'),
        ),
        css('svg').styles(
          width: 1.1.em,
          height: 1.1.em,
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
          css('&').styles(padding: .all(0.45.em)),
          css('.lang__label').styles(raw: const {'display': 'none'}),
        ]),
      ]),
    ]),
  ];
}

class _GlobeIcon extends StatelessComponent {
  const _GlobeIcon();

  @override
  Component build(BuildContext context) {
    return svg(
      viewBox: '0 0 24 24',
      width: 24.px,
      height: 24.px,
      attributes: const {
        'fill': 'none',
        'stroke': 'currentColor',
        'stroke-width': '1.6',
        'stroke-linecap': 'round',
        'stroke-linejoin': 'round',
        'aria-hidden': 'true',
      },
      [
        circle([], cx: '12', cy: '12', r: '9'),
        Component.element(
          tag: 'ellipse',
          attributes: const {'cx': '12', 'cy': '12', 'rx': '4', 'ry': '9'},
          children: const [],
        ),
        line([], x1: '3', y1: '12', x2: '21', y2: '12'),
      ],
    );
  }
}
