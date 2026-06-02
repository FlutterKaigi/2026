import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/event_info.dart';
import 'event_section/event_info_card.dart';
import 'event_section/news_card.dart';
import 'event_section/roadmap_card.dart';
import 'event_section/social_link_card.dart';

/// トップページ Hero 直下に置くイベント情報セクション。Bento Grid (12 cols)。
///
/// - Row 1: News (12 cols)
/// - Row 2: Event Information (8 cols) + Roadmap (4 cols)
/// - Row 3: Medium (6 cols) + X (6 cols)
///
/// タブレット以下 (≤960px) では全カード横幅いっぱい縦並びに崩れる。
class EventSection extends StatelessComponent {
  const EventSection({super.key});

  @override
  Component build(BuildContext context) {
    return section(
      id: 'event-info',
      classes: 'event-section',
      [
        div(classes: 'event-section__grid', [
          div(classes: 'event-section__news', [const NewsCard()]),
          div(classes: 'event-section__info', [const EventInfoCard()]),
          div(classes: 'event-section__roadmap', [const RoadmapCard()]),
          for (var i = 0; i < eventSocialCards.length; i++)
            div(
              classes: i == 0
                  ? 'event-section__social event-section__social--first'
                  : 'event-section__social',
              [SocialLinkCard(card: eventSocialCards[i])],
            ),
        ]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    css('.event-section', [
      css('&').styles(
        display: .flex,
        justifyContent: .center,
        width: 100.percent,
        padding: .symmetric(horizontal: 24.px, vertical: 128.px),
        raw: const {'background-color': '#FDF7FF'},
      ),
      css('.event-section__grid').styles(
        display: .grid,
        width: 100.percent,
        raw: const {
          'grid-template-columns': 'repeat(12, minmax(0, 1fr))',
          'column-gap': '24px',
          'row-gap': '24px',
          'max-width': '1232px',
        },
      ),
      css('.event-section__news').styles(
        raw: const {'grid-column': '1 / span 12'},
      ),
      css('.event-section__info').styles(
        display: .flex,
        raw: const {'grid-column': '1 / span 8', 'min-width': '0'},
      ),
      css('.event-section__roadmap').styles(
        display: .flex,
        raw: const {'grid-column': '9 / span 4', 'min-width': '0'},
      ),
      css('.event-section__social').styles(
        display: .flex,
        raw: const {'grid-column': 'span 6', 'min-width': '0'},
      ),
      css('.event-section__social--first').styles(
        raw: const {'grid-column': '1 / span 6'},
      ),
      // 子カードをセル全体に伸ばす。
      css('.event-section__news > *').styles(width: 100.percent),
      css('.event-section__info > *').styles(width: 100.percent),
      css('.event-section__roadmap > *').styles(width: 100.percent),
      css('.event-section__social > *').styles(width: 100.percent),
    ]),

    // タブレット以下：1カラム縦並び。
    css.media(MediaQuery.all(maxWidth: 960.px), [
      css('.event-section', [
        css('&').styles(
          padding: .symmetric(horizontal: 24.px, vertical: 64.px),
        ),
        css('.event-section__grid').styles(
          raw: const {
            'grid-template-columns': 'minmax(0, 1fr)',
            'row-gap': '16px',
          },
        ),
        css('.event-section__news').styles(
          raw: const {'grid-column': '1'},
        ),
        css('.event-section__info').styles(
          raw: const {'grid-column': '1'},
        ),
        css('.event-section__roadmap').styles(
          raw: const {'grid-column': '1'},
        ),
        css('.event-section__social').styles(
          raw: const {'grid-column': '1'},
        ),
        css('.event-section__social--first').styles(
          raw: const {'grid-column': '1'},
        ),
      ]),
    ]),

    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.event-section').styles(
        padding: .symmetric(horizontal: 16.px, vertical: 48.px),
      ),
    ]),
  ];
}
