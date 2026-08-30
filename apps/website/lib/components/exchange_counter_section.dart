import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/generated_exchange_counter.dart';
import '../constants/theme.dart';
import '../l10n/strings.dart';

/// A single modest stat line — "N profiles exchanged so far" — for the
/// in-app profile-exchange feature (issue-594.md). Placed as its own thin
/// band between [StaffSection] and the footer: understated on purpose (a
/// single line of text, not a card competing with the Bento-grid sections
/// above it), and skipped visually in favor of a short teaser sentence while
/// the count is still 0 — mostly true before/early in the event, when a bare
/// "0" would read as broken rather than "not started yet".
///
/// [generatedProfileExchangeCount] is a build-time snapshot (see
/// `tool/generate_exchange_counter.dart`), not a live count.
class ExchangeCounterSection extends StatelessComponent {
  const ExchangeCounterSection({super.key});

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    const count = generatedProfileExchangeCount;
    return section(classes: 'exchange-counter', [
      p(classes: 'exchange-counter__text', [
        .text(count > 0 ? strings.exchangeCounterLabel(count) : strings.exchangeCounterEmpty),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.exchange-counter', [
      css('&').styles(
        display: .flex,
        justifyContent: .center,
        width: 100.percent,
        padding: .symmetric(horizontal: 24.px, vertical: 20.px),
        backgroundColor: eventCardSurfaceRoadmap,
      ),
      css('.exchange-counter__text').styles(
        color: const Color('#494456'),
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        raw: const {'font-size': '14px', 'text-align': 'center', 'margin': '0'},
      ),
    ]),
  ];
}
