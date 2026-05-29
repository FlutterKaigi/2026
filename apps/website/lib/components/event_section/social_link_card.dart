import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../constants/event_info.dart';
import '../../constants/theme.dart';
import '../../l10n/strings.dart';

class SocialLinkCard extends StatelessComponent {
  const SocialLinkCard({super.key, required this.card});

  final SocialCard card;

  @override
  Component build(BuildContext context) {
    final locale = LocaleScope.of(context);
    return a(
      href: card.url,
      target: Target.blank,
      classes: 'social-link-card',
      [
        div(classes: 'social-link-card__lead', [
          div(classes: 'social-link-card__icon', [
            img(
              src: card.iconAsset,
              alt: '',
              attributes: const {'aria-hidden': 'true'},
            ),
          ]),
          div(classes: 'social-link-card__text', [
            p(classes: 'social-link-card__label', [
              .text(card.label.forLocale(locale)),
            ]),
            p(classes: 'social-link-card__handle', [.text(card.handle)]),
          ]),
        ]),
        span(
          classes: 'social-link-card__arrow',
          attributes: const {'aria-hidden': 'true'},
          [.text('↗')],
        ),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    css('.social-link-card', [
      css('&').styles(
        display: .flex,
        height: 98.px,
        padding: .symmetric(horizontal: 25.px, vertical: 25.px),
        alignItems: .center,
        justifyContent: .spaceBetween,
        backgroundColor: const Color('#F8F1FF'),
        radius: .circular(24.px),
        border: Border.all(
          style: BorderStyle.solid,
          color: const Color('#CBC3D933'),
          width: 1.px,
        ),
        textDecoration: const TextDecoration(line: TextDecorationLine.none),
        raw: const {
          'overflow': 'hidden',
          'transition': 'transform 150ms ease, box-shadow 150ms ease',
        },
      ),
      css('&:hover').styles(
        raw: const {
          'transform': 'translateY(-2px)',
          'box-shadow': '0 8px 20px rgba(101, 85, 143, 0.18)',
        },
      ),
      css('.social-link-card__lead').styles(
        display: .flex,
        alignItems: .center,
        gap: Gap.column(16.px),
      ),
      css('.social-link-card__icon', [
        css('&').styles(
          display: .flex,
          width: 48.px,
          height: 48.px,
          radius: .circular(999.px),
          backgroundColor: const Color('#E9DDFF'),
          alignItems: .center,
          justifyContent: .center,
          raw: const {'flex-shrink': '0'},
        ),
        css('img').styles(width: 24.px, height: 24.px),
      ]),
      css('.social-link-card__text').styles(
        display: .flex,
        flexDirection: .column,
        gap: Gap.row(0.px),
      ),
      css('.social-link-card__label').styles(
        color: const Color('#1D1A25'),
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        raw: const {
          'font-size': '16px',
          'line-height': '24px',
          'letter-spacing': '0.15px',
        },
      ),
      css('.social-link-card__handle').styles(
        color: const Color('#494456'),
        fontFamily: uiFontFamily,
        fontWeight: .w400,
        raw: const {
          'font-size': '12px',
          'line-height': '16px',
          'letter-spacing': '0.4px',
        },
      ),
      css('.social-link-card__arrow').styles(
        color: const Color('#494456'),
        raw: const {'font-size': '16px', 'line-height': '1'},
      ),
    ]),
  ];
}
