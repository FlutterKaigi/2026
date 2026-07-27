import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../constants/theme.dart';
import '../../constants/ticket_sales.dart';
import '../../l10n/strings.dart';

/// Exploratory preview of Luma's embedded checkout (`<iframe>`), placed
/// alongside the checkout-button CTAs (Hero / EventInfoCard) so the two
/// approaches can be compared in a live preview before picking one. Full
/// width and in its own row — deliberately not squeezed into the tuned
/// EventInfoCard/RoadmapCard bento layout.
class TicketEmbedCard extends StatelessComponent {
  const TicketEmbedCard({super.key});

  @override
  Component build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final strings = Strings(locale);

    return article(classes: 'ticket-embed-card', [
      h2(classes: 'ticket-embed-card__title', [
        .text(strings.ticketEmbedTitle),
      ]),
      p(classes: 'ticket-embed-card__note', [
        .text(strings.ticketEmbedNote),
      ]),
      iframe(
        const [],
        src: lumaEmbedUrl,
        width: 600,
        height: 450,
        // `payment` is required for Luma's embedded checkout to complete a
        // purchase inside the frame; `fullscreen` matches Luma's own sample.
        allow: 'fullscreen; payment',
        styles: Styles(
          border: Border.all(
            style: BorderStyle.solid,
            color: const Color('#bfcbda88'),
            width: 1.px,
          ),
          radius: .circular(4.px),
        ),
        attributes: const {'aria-hidden': 'false', 'tabindex': '0'},
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.ticket-embed-card', [
      css('&').styles(
        display: .flex,
        flexDirection: .column,
        padding: .all(32.px),
        backgroundColor: eventCardSurfaceInfo,
        radius: .circular(24.px),
        border: Border.all(
          style: BorderStyle.solid,
          color: eventCardBorder,
          width: 1.px,
        ),
        raw: const {'gap': '16px'},
      ),
      css('.ticket-embed-card__title').styles(
        color: onSurface,
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        raw: const {'font-size': '22px', 'line-height': '28px'},
      ),
      css('.ticket-embed-card__note').styles(
        color: onSurfaceVariant,
        fontFamily: uiFontFamily,
        fontWeight: .w400,
        raw: const {'font-size': '14px', 'line-height': '20px'},
      ),
      // Luma's iframe is a fixed 600x450; cap the width so narrow viewports
      // don't overflow horizontally (height stays fixed — acceptable for
      // this exploratory preview, not a final responsive treatment).
      css('.ticket-embed-card iframe').styles(
        raw: const {'max-width': '100%'},
      ),
    ]),
  ];
}
