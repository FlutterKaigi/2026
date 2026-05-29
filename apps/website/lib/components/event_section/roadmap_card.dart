import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../constants/roadmap_milestones.dart';
import '../../constants/theme.dart';
import '../../l10n/strings.dart';

class RoadmapCard extends StatelessComponent {
  const RoadmapCard({super.key});

  @override
  Component build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final strings = Strings(locale);
    final now = DateTime.now();

    return article(classes: 'roadmap-card', [
      div(classes: 'roadmap-card__head', [
        div(classes: 'roadmap-card__icon', [
          img(
            src: 'images/icons/roadmap.svg',
            alt: '',
            attributes: const {'aria-hidden': 'true'},
          ),
        ]),
        h2(classes: 'roadmap-card__title', [.text(strings.roadmapCardTitle)]),
      ]),
      div(classes: 'roadmap-card__timeline', [
        ol(classes: 'roadmap-card__list', [
          for (final m in eventRoadmap)
            _milestoneItem(
              m: m,
              status: milestoneStatus(m, now, all: eventRoadmap),
              locale: locale,
            ),
        ]),
      ]),
    ]);
  }

  Component _milestoneItem({
    required RoadmapMilestone m,
    required MilestoneStatus status,
    required AppLocale locale,
  }) {
    final cls = switch (status) {
      MilestoneStatus.past => 'roadmap-card__item roadmap-card__item--past',
      MilestoneStatus.upNext => 'roadmap-card__item roadmap-card__item--upnext',
      MilestoneStatus.future => 'roadmap-card__item',
    };
    return li(classes: cls, [
      span(
        classes: 'roadmap-card__dot',
        attributes: const {'aria-hidden': 'true'},
        [],
      ),
      p(classes: 'roadmap-card__date', [.text(m.dateFor(locale))]),
      p(classes: 'roadmap-card__name', [.text(m.titleFor(locale))]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.roadmap-card', [
      css('&').styles(
        display: .flex,
        flexDirection: .column,
        padding: .all(33.px),
        backgroundColor: const Color('#F3EBFB'),
        radius: .circular(24.px),
        border: Border.all(
          style: BorderStyle.solid,
          color: const Color('#CBC3D94D'),
          width: 1.px,
        ),
        raw: const {'min-height': '330px', 'height': '100%'},
      ),
      css('.roadmap-card__head').styles(
        display: .flex,
        alignItems: .center,
        gap: Gap.column(12.px),
        raw: const {'padding-bottom': '32px'},
      ),
      css('.roadmap-card__icon', [
        css('&').styles(
          display: .flex,
          width: 44.px,
          height: 44.px,
          radius: .circular(16.px),
          backgroundColor: const Color('#D4E3FF'),
          alignItems: .center,
          justifyContent: .center,
          raw: const {'flex-shrink': '0'},
        ),
        css('img').styles(width: 20.px, height: 20.px),
      ]),
      css('.roadmap-card__title').styles(
        color: const Color('#1D1A25'),
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        raw: const {'font-size': '22px', 'line-height': '28px'},
      ),
      css('.roadmap-card__timeline').styles(
        position: .relative(),
        raw: const {'padding-left': '8px'},
      ),
      css('.roadmap-card__list', [
        css('&').styles(
          position: .relative(),
          display: .flex,
          flexDirection: .column,
          padding: .zero,
          raw: const {
            'list-style': 'none',
            'margin': '0',
            'gap': '24px',
          },
        ),
        css('&::before').styles(
          position: .absolute(top: 6.px, bottom: 6.px, left: 5.px),
          width: 2.px,
          backgroundColor: const Color('#CBC3D980'),
          raw: const {'content': '""'},
        ),
      ]),
      css('.roadmap-card__item', [
        css('&').styles(
          position: .relative(),
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(4.px),
          raw: const {'padding-left': '32px'},
        ),
        // 既定（future）状態の dot は赤茶系。
        css('.roadmap-card__dot').styles(
          position: .absolute(top: 6.px, left: 0.px),
          width: 12.px,
          height: 12.px,
          radius: .circular(999.px),
          backgroundColor: const Color('#904A45'),
          border: Border.all(
            style: BorderStyle.solid,
            color: const Color('#F3EBFB'),
            width: 4.px,
          ),
          raw: const {
            'box-sizing': 'content-box',
            'margin-left': '-4px',
            'transition': 'transform 200ms ease',
          },
        ),
        // 過去：dot を彩度の低いグレーに、テキストも muted に。
        css('&--past', [
          css('.roadmap-card__dot').styles(
            backgroundColor: const Color('#CBC3D9'),
            border: Border.all(
              style: BorderStyle.solid,
              color: const Color('#F3EBFB'),
              width: 4.px,
            ),
          ),
          css('.roadmap-card__date').styles(
            raw: const {'opacity': '0.55'},
          ),
          css('.roadmap-card__name').styles(
            raw: const {'opacity': '0.55'},
          ),
        ]),
        // 次に到来：紫の強アクセント＋外周のリング演出。
        css('&--upnext', [
          css('.roadmap-card__dot').styles(
            backgroundColor: const Color('#65558F'),
            raw: const {
              'box-shadow': '0 0 0 4px rgba(101, 85, 143, 0.18)',
            },
          ),
          css('.roadmap-card__name').styles(
            color: const Color('#21005D'),
            fontWeight: .w500,
          ),
        ]),
        css('.roadmap-card__date').styles(
          color: const Color('#494456'),
          fontFamily: uiFontFamily,
          fontWeight: .w400,
          raw: const {
            'font-size': '11px',
            'line-height': '16px',
            'letter-spacing': '0.5px',
          },
        ),
        css('.roadmap-card__name').styles(
          color: const Color('#1D1A25'),
          fontFamily: uiFontFamily,
          fontWeight: .w400,
          raw: const {
            'font-size': '16px',
            'line-height': '24px',
            'letter-spacing': '0.15px',
          },
        ),
      ]),
    ]),

    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.roadmap-card').styles(padding: .all(24.px)),
    ]),
  ];
}
