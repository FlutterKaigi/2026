import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/generated_tokens.dart';
import '../constants/theme.dart';
import '../l10n/strings.dart';

class Home extends StatelessComponent {
  const Home({super.key});

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    return section(classes: 'hero', [
      div(classes: 'hero__title', [
        h1(classes: 'hero__headline', [
          span(classes: 'hero__headline-line hero__headline-line--brand', [
            .text('FlutterKaigi'),
          ]),
          span(classes: 'hero__headline-line hero__headline-line--year', [
            .text('2026'),
          ]),
        ]),
        div(classes: 'hero__meta', [
          div(classes: 'hero__meta-row', [
            img(
              classes: 'hero__meta-icon',
              src: 'images/icons/calendar_paper.svg',
              alt: '',
              attributes: const {'aria-hidden': 'true'},
            ),
            p(classes: 'hero__meta-text', [
              .text('10.29'),
              _Sup('THU'),
              .text(' – 30'),
              _Sup('FRI'),
            ]),
          ]),
          div(classes: 'hero__meta-row', [
            img(
              classes: 'hero__meta-icon',
              src: 'images/icons/map_pin.svg',
              alt: '',
              attributes: const {'aria-hidden': 'true'},
            ),
            p(classes: 'hero__meta-text', [.text(strings.venue)]),
          ]),
        ]),
      ]),
      div(classes: 'hero__brand', [
        div(classes: 'hero__logo', [
          img(
            src: 'images/logo.svg',
            alt: 'FlutterKaigi 2026',
            attributes: const {'aria-hidden': 'true'},
          ),
        ]),
        a(
          href: strings.latestUpdatesCtaUrl,
          target: Target.blank,
          classes: 'hero__cta',
          [
            span([.text(strings.latestUpdatesCta)]),
            span(
              classes: 'hero__cta-arrow',
              attributes: const {'aria-hidden': 'true'},
              [.text('→')],
            ),
          ],
        ),
      ]),
      div(classes: 'hero__slogan', [
        p(classes: 'hero__slogan-headline', [.text('Assemble')]),
        p(classes: 'hero__slogan-tagline', [.text(strings.heroTagline)]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.hero', [
      css('&').styles(
        position: .relative(),
        display: .flex,
        flex: const Flex(grow: 1),
        width: 100.percent,
        minHeight: 720.px,
        overflow: .hidden,
        padding: .symmetric(horizontal: 4.em, vertical: 4.em),
        color: onBrand,
        raw: const {'background': heroGradient},
      ),
      css('.hero__title', [
        css('&').styles(
          position: .absolute(top: 3.em, left: 3.em),
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(1.5.em),
          maxWidth: 50.percent,
          zIndex: const ZIndex(2),
        ),
        css('.hero__headline', [
          css('&').styles(
            display: .flex,
            flexDirection: .column,
            fontFamily: displayFontFamily,
            fontWeight: tokenWeight(fontMainvisualEnglish2026.fontWeight),
          ),
          css('.hero__headline-line').styles(display: .block),
          // Per-line sizing anchored to mainvisual tokens (60/72px max).
          css('.hero__headline-line--brand').styles(
            raw: tokenFontCss(
              fontMainvisualEnglishFlutterkaigi,
              fluidMin: '2rem',
              fluidVw: '7vw',
            ),
          ),
          css('.hero__headline-line--year').styles(
            raw: tokenFontCss(
              fontMainvisualEnglish2026,
              fluidMin: '2.25rem',
              fluidVw: '8vw',
            ),
          ),
        ]),
        css('.hero__meta', [
          css('&').styles(
            display: .flex,
            flexDirection: .column,
            gap: Gap.row(0.5.em),
            fontFamily: displayFontFamily,
            raw: tokenFontCss(fontM3TitleMedium),
          ),
          css('.hero__meta-row').styles(
            display: .flex,
            alignItems: .center,
            gap: Gap.column(0.5.em),
          ),
          css('.hero__meta-text').styles(color: onBrand),
          css('.hero__meta-text sup').styles(
            fontWeight: tokenWeight(fontM3LabelSmall.fontWeight),
            raw: const {
              'font-size': '0.55em',
              'letter-spacing': '0.05em',
              'vertical-align': 'super',
            },
          ),
          css('.hero__meta-icon').styles(
            width: 1.4.em,
            height: 1.4.em,
            raw: const {'flex-shrink': '0'},
          ),
        ]),
      ]),
      css('.hero__brand').styles(
        position: .absolute(top: 50.percent, left: 50.percent),
        display: .flex,
        flexDirection: .column,
        alignItems: .center,
        gap: Gap.row(1.5.em),
        raw: const {'transform': 'translate(-50%, -50%)'},
      ),
      css('.hero__logo', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          justifyContent: .center,
        ),
        css('img').styles(
          width: 28.vw,
          maxWidth: 460.px,
          minWidth: 280.px,
          height: .auto,
          // The shuriken / windmill motif drop-shadow from the design system.
          raw: {'filter': effectShuriken.cssDropShadow},
        ),
      ]),
      css('.hero__cta', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          gap: Gap.column(0.5.em),
          padding: .symmetric(horizontal: 1.5.em, vertical: 0.85.em),
          backgroundColor: onBrand,
          color: deepPurple,
          fontFamily: uiFontFamily,
          fontWeight: tokenWeight(fontM3LabelLarge.fontWeight),
          radius: .circular(999.px),
          textDecoration: TextDecoration(line: .none),
          raw: {
            ...tokenFontCss(fontM3LabelLarge),
            'box-shadow': '0 8px 24px rgba(0, 0, 0, 0.18)',
            'transition': 'transform 150ms ease, box-shadow 150ms ease',
          },
        ),
        css('&:hover').styles(
          raw: const {
            'transform': 'translateY(-2px)',
            'box-shadow': '0 12px 28px rgba(0, 0, 0, 0.22)',
          },
        ),
        css('.hero__cta-arrow').styles(
          fontFamily: displayFontFamily,
          fontWeight: .w500,
          raw: const {'font-size': '1.1em'},
        ),
      ]),
      css('.hero__slogan', [
        css('&').styles(
          position: .absolute(bottom: 2.5.em, right: 3.em),
          display: .flex,
          flexDirection: .column,
          alignItems: .center,
          gap: Gap.row(0.25.em),
          textAlign: .end,
          zIndex: const ZIndex(2),
          fontFamily: displayFontFamily,
        ),
        css('.hero__slogan-headline').styles(
          raw: tokenFontCss(
            fontMainvisualEnglishConcept,
          ),
        ),
        css('.hero__slogan-tagline').styles(
          raw: tokenFontCss(
            fontMainvisualJapanese,
          ),
        ),
      ]),
    ]),

    // Tablet: tighten padding and shift logo so it doesn't crowd the title.
    css.media(MediaQuery.all(maxWidth: 960.px), [
      css('.hero', [
        css('&').styles(
          padding: .symmetric(horizontal: 2.em, vertical: 3.em),
        ),
        css('.hero__title', [
          css('&').styles(
            raw: const {'top': '2em', 'left': '2em'},
            maxWidth: 60.percent,
          ),
        ]),
        css('.hero__logo img').styles(width: 38.vw, minWidth: 220.px),
        css('.hero__slogan').styles(
          raw: const {'bottom': '2em', 'right': '2em'},
        ),
      ]),
    ]),

    // Mobile: stack everything in normal flow.
    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.hero', [
        css('&').styles(
          flexDirection: .column,
          alignItems: .center,
          justifyContent: .start,
          padding: .symmetric(horizontal: 1.em, vertical: 2.em),
          gap: Gap.row(2.em),
        ),
        css('.hero__title', [
          css('&').styles(
            alignItems: .center,
            textAlign: .center,
            maxWidth: 100.percent,
            raw: const {
              'position': 'static',
              'top': 'auto',
              'left': 'auto',
            },
          ),
          css('.hero__headline').styles(alignItems: .center),
          css('.hero__meta').styles(alignItems: .center),
        ]),
        css('.hero__brand').styles(
          raw: const {
            'position': 'static',
            'top': 'auto',
            'left': 'auto',
            'transform': 'none',
          },
        ),
        css('.hero__logo img').styles(width: 70.percent, maxWidth: 280.px),
        css('.hero__slogan').styles(
          alignItems: .center,
          textAlign: .center,
          raw: const {
            'position': 'static',
            'bottom': 'auto',
            'right': 'auto',
          },
        ),
      ]),
    ]),
  ];
}

class _Sup extends StatelessComponent {
  const _Sup(this.text);
  final String text;

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: 'sup',
      children: [Component.text(text)],
    );
  }
}
