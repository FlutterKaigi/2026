import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../constants/staff.dart';
import '../../constants/theme.dart';
import '../../l10n/strings.dart';

/// A single staff card: circular avatar, name, SNS icon links and an optional
/// one-line greeting, per the Figma design (node 656:2774).
class StaffCard extends StatelessComponent {
  const StaffCard({super.key, required this.entry});

  final StaffEntry entry;

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    return div(classes: 'staff-card', [
      if (entry.iconUrl.isNotEmpty)
        img(
          classes: 'staff-card__avatar',
          src: entry.iconUrl,
          alt: '',
          attributes: const {'loading': 'lazy'},
        )
      else
        div(
          classes: 'staff-card__avatar staff-card__avatar--placeholder',
          attributes: const {'aria-hidden': 'true'},
          [
            img(src: 'images/icons/person.svg', alt: ''),
          ],
        ),
      p(classes: 'staff-card__name', [.text(entry.name)]),
      if (entry.snsLinks.isNotEmpty)
        div(classes: 'staff-card__links', [
          for (final link in entry.snsLinks)
            a(
              href: link.value,
              target: Target.blank,
              classes: 'staff-card__link',
              attributes: {
                'aria-label': strings.staffSnsAriaLabel(entry.name, link.label),
              },
              [
                img(src: link.iconAsset, alt: ''),
              ],
            ),
        ]),
      if (entry.greeting.isNotEmpty) p(classes: 'staff-card__greeting', [.text(entry.greeting)]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.staff-card', [
      css('&').styles(
        display: .flex,
        flexDirection: .column,
        alignItems: .center,
        width: 200.px,
        gap: Gap.row(12.px),
        textAlign: .center,
      ),
      css('.staff-card__avatar', [
        css('&').styles(
          width: 150.px,
          height: 150.px,
          radius: .circular(999.px),
          raw: const {'object-fit': 'cover', 'flex-shrink': '0'},
        ),
        // Placeholder when no icon URL is set: person glyph on a light
        // lavender disc (same tint family as the event-section cards).
        css('&.staff-card__avatar--placeholder', [
          css('&').styles(
            display: .flex,
            alignItems: .center,
            justifyContent: .center,
            backgroundColor: const Color('#F3EBFB'),
          ),
          css('img').styles(width: 48.px, height: 48.px),
        ]),
      ]),
      css('.staff-card__name').styles(
        color: const Color('#1D1A25'),
        fontFamily: uiFontFamily,
        fontWeight: .w700,
        raw: const {
          'font-size': '18px',
          'line-height': '1.4',
          'overflow-wrap': 'anywhere',
        },
      ),
      css('.staff-card__links', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          justifyContent: .center,
          gap: Gap.column(20.px),
          raw: const {'flex-wrap': 'wrap'},
        ),
        css('.staff-card__link', [
          css('&').styles(
            display: .flex,
            alignItems: .center,
            justifyContent: .center,
            raw: const {'transition': 'transform 150ms ease, opacity 150ms ease'},
          ),
          css('&:hover').styles(
            raw: const {'transform': 'translateY(-2px)', 'opacity': '0.7'},
          ),
          css('&:focus-visible').styles(
            raw: const {'outline': '2px solid #65558F', 'outline-offset': '2px'},
          ),
          css('img').styles(width: 22.px, height: 22.px),
        ]),
      ]),
      css('.staff-card__greeting').styles(
        color: onSurfaceVariant,
        fontFamily: uiFontFamily,
        fontWeight: .w400,
        raw: const {
          'font-size': '14px',
          'line-height': '1.5',
          'overflow-wrap': 'anywhere',
        },
      ),
    ]),

    // Mobile: two cards per row.
    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.staff-card', [
        css('&').styles(width: 150.px),
        css('.staff-card__avatar').styles(width: 120.px, height: 120.px),
      ]),
    ]),
  ];
}
