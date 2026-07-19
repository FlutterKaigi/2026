import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../constants/roadmap_milestones.dart';
import '../../constants/theme.dart';
import '../../l10n/strings.dart';

/// Roadmap タイムライン。Figma 準拠で「Conference Day だけプライマリーで強調」
/// する静的表示。動的な「現在地」判定は持たないため SSG 完結。
class RoadmapCard extends StatelessComponent {
  const RoadmapCard({super.key});

  @override
  Component build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final strings = Strings(locale);

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
          for (final m in eventRoadmap) _milestoneItem(m: m, locale: locale),
        ]),
      ]),
    ]);
  }

  Component _milestoneItem({
    required RoadmapMilestone m,
    required AppLocale locale,
  }) {
    final isPrimary = m.gate == MilestoneGate.conference;
    final cls = isPrimary ? 'roadmap-card__item roadmap-card__item--primary' : 'roadmap-card__item';
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
        backgroundColor: eventCardSurfaceRoadmap,
        radius: .circular(24.px),
        border: Border.all(
          style: BorderStyle.solid,
          color: eventCardBorder,
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
          backgroundColor: tertiaryContainer,
          alignItems: .center,
          justifyContent: .center,
          raw: const {'flex-shrink': '0'},
        ),
        css('img').styles(width: 20.px, height: 20.px),
      ]),
      css('.roadmap-card__title').styles(
        color: onSurface,
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
          backgroundColor: eventRoadmapTimeline,
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
        // 既定の dot：secondary（赤茶系）の単色。
        css('.roadmap-card__dot').styles(
          position: .absolute(top: 6.px, left: 0.px),
          width: 12.px,
          height: 12.px,
          radius: .circular(999.px),
          backgroundColor: secondary,
          border: Border.all(
            style: BorderStyle.solid,
            color: eventCardSurfaceRoadmap,
            width: 4.px,
          ),
          raw: const {
            'box-sizing': 'content-box',
            'margin-left': '-4px',
          },
        ),
        // Conference Day だけ primary 強調＋外周のリング、名前も濃紫で w500。
        css('&--primary', [
          css('.roadmap-card__dot').styles(
            backgroundColor: primary,
            raw: const {
              'box-shadow': '0 0 0 4px rgba(101, 85, 143, 0.18)',
            },
          ),
          css('.roadmap-card__name').styles(
            color: eventRoadmapEmphasis,
            fontWeight: .w500,
          ),
        ]),
        css('.roadmap-card__date').styles(
          color: onSurfaceVariant,
          fontFamily: uiFontFamily,
          fontWeight: .w400,
          raw: const {
            'font-size': '11px',
            'line-height': '16px',
            'letter-spacing': '0.5px',
          },
        ),
        css('.roadmap-card__name').styles(
          color: onSurface,
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
