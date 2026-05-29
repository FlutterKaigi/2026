import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../constants/event_info.dart';
import '../../constants/roadmap_milestones.dart';
import '../../constants/theme.dart';
import '../../l10n/strings.dart';

class EventInfoCard extends StatelessComponent {
  const EventInfoCard({super.key});

  @override
  Component build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final strings = Strings(locale);
    final ticketsOpen = milestoneByGate(MilestoneGate.tickets);

    return article(classes: 'event-info-card', [
      div(classes: 'event-info-card__head', [
        div(classes: 'event-info-card__icon', [
          img(
            src: 'images/icons/event_info.svg',
            alt: '',
            attributes: const {'aria-hidden': 'true'},
          ),
        ]),
        h2(classes: 'event-info-card__title', [
          .text(strings.eventInfoCardTitle),
        ]),
      ]),
      // DATE / VENUE。横幅が十分なら2カラム、狭ければ自動で1カラムに。
      div(classes: 'event-info-card__rows', [
        div(classes: 'event-info-card__field event-info-card__field--date', [
          p(classes: 'event-info-card__label', [
            .text(strings.eventInfoDateLabel),
          ]),
          p(classes: 'event-info-card__date-value', [
            .text(eventDate.forLocale(locale)),
          ]),
        ]),
        div(classes: 'event-info-card__field', [
          p(classes: 'event-info-card__label', [
            .text(strings.eventInfoVenueLabel),
          ]),
          p(classes: 'event-info-card__value', [
            .text(eventVenue.forLocale(locale)),
          ]),
        ]),
      ]),
      div(classes: 'event-info-card__tickets', [
        p(classes: 'event-info-card__label', [
          .text(strings.eventInfoTicketsLabel),
        ]),
        span(
          classes: 'event-info-card__cta',
          attributes: {
            'role': 'button',
            'aria-disabled': 'true',
            'aria-label': strings.eventInfoTicketsAriaLabel,
            'tabindex': '-1',
          },
          [
            img(
              classes: 'event-info-card__cta-icon',
              src: 'images/icons/hourglass.svg',
              alt: '',
              attributes: const {'aria-hidden': 'true'},
            ),
            span(classes: 'event-info-card__cta-label', [
              .text(strings.eventInfoComingSoon),
            ]),
            if (ticketsOpen != null)
              span(classes: 'event-info-card__cta-meta', [
                .text(strings.eventInfoTicketsOpensAt(
                  ticketsOpen.dateFor(locale),
                )),
              ]),
          ],
        ),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.event-info-card', [
      css('&').styles(
        display: .flex,
        flexDirection: .column,
        padding: .all(49.px),
        backgroundColor: const Color('#EDE5F5'),
        radius: .circular(24.px),
        border: Border.all(
          style: BorderStyle.solid,
          color: const Color('#CBC3D94D'),
          width: 1.px,
        ),
        raw: const {'gap': '32px', 'min-height': '330px'},
      ),
      css('.event-info-card__head').styles(
        display: .flex,
        alignItems: .center,
        gap: Gap.column(12.px),
      ),
      css('.event-info-card__icon', [
        css('&').styles(
          display: .flex,
          width: 44.px,
          height: 44.px,
          radius: .circular(16.px),
          backgroundColor: const Color('#E9DDFF'),
          alignItems: .center,
          justifyContent: .center,
          raw: const {'flex-shrink': '0'},
        ),
        css('img').styles(width: 20.px, height: 20.px),
      ]),
      css('.event-info-card__title').styles(
        color: const Color('#1D1A25'),
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        raw: const {'font-size': '22px', 'line-height': '28px'},
      ),
      // DATE/VENUE 行：auto-fit + minmax で「収まれば2列、狭ければ1列」を自動切替。
      css('.event-info-card__rows').styles(
        display: .grid,
        raw: const {
          'grid-template-columns':
              'repeat(auto-fit, minmax(min(100%, 320px), 1fr))',
          'gap': '24px 32px',
        },
      ),
      css('.event-info-card__field').styles(
        display: .flex,
        flexDirection: .column,
        gap: Gap.row(4.px),
        raw: const {'min-width': '0'},
      ),
      css('.event-info-card__label').styles(
        color: const Color('#494456'),
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        raw: const {
          'font-size': '11px',
          'line-height': '16px',
          'letter-spacing': '0.55px',
          'text-transform': 'uppercase',
        },
      ),
      // DATE: 主役級サイズ。日本語が長い場合に備えて clamp と word-break で安全側。
      css('.event-info-card__date-value').styles(
        color: const Color('#1D1A25'),
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        raw: const {
          'font-size': 'clamp(22px, 2.2vw, 28px)',
          'line-height': '1.2',
          'letter-spacing': '0.1px',
          'word-break': 'keep-all',
          'overflow-wrap': 'anywhere',
        },
      ),
      css('.event-info-card__value').styles(
        color: const Color('#1D1A25'),
        fontFamily: uiFontFamily,
        fontWeight: .w400,
        raw: const {'font-size': '22px', 'line-height': '28px'},
      ),
      css('.event-info-card__tickets').styles(
        display: .flex,
        flexDirection: .column,
        gap: Gap.row(8.px),
      ),
      // Disabled CTA：時計アイコン+ラベル+販売開始日のmeta行。
      // デスクトップは inline-flex で内容幅、タブレット以下はカード幅いっぱい。
      css('.event-info-card__cta', [
        css('&').styles(
          display: .inlineFlex,
          padding: .symmetric(horizontal: 20.px, vertical: 12.px),
          alignItems: .center,
          gap: Gap.column(10.px),
          backgroundColor: const Color('#65558F66'),
          color: const Color('#FFFFFFE6'),
          fontFamily: uiFontFamily,
          fontWeight: .w500,
          radius: .circular(8.px),
          raw: const {
            'font-size': '14px',
            'line-height': '20px',
            'letter-spacing': '0.1px',
            'align-self': 'flex-start',
            'cursor': 'not-allowed',
            'user-select': 'none',
            'margin-top': '4px',
            'flex-wrap': 'wrap',
          },
        ),
        css('.event-info-card__cta-icon').styles(
          width: 16.px,
          height: 16.px,
          raw: const {'flex-shrink': '0', 'opacity': '0.9'},
        ),
        css('.event-info-card__cta-label').styles(
          raw: const {'white-space': 'nowrap'},
        ),
        css('.event-info-card__cta-meta').styles(
          fontWeight: .w400,
          raw: const {
            'font-size': '12px',
            'line-height': '16px',
            'opacity': '0.85',
            'padding-left': '6px',
            'border-left': '1px solid rgba(255, 255, 255, 0.4)',
            'margin-left': '2px',
          },
        ),
      ]),
    ]),

    css.media(MediaQuery.all(maxWidth: 960.px), [
      css('.event-info-card', [
        css('&').styles(padding: .all(32.px)),
        // タブレット以下：CTAをカード幅いっぱいに、中央寄せ。
        css('.event-info-card__cta').styles(
          display: .flex,
          width: 100.percent,
          justifyContent: .center,
          raw: const {'align-self': 'stretch'},
        ),
      ]),
    ]),

    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.event-info-card', [
        css('&').styles(padding: .all(24.px)),
        css('.event-info-card__rows').styles(
          raw: const {
            'grid-template-columns': 'minmax(0, 1fr)',
            'gap': '20px',
          },
        ),
        // 狭い画面では meta の縦区切り線をやめて自然に折り返す。
        css('.event-info-card__cta .event-info-card__cta-meta').styles(
          raw: const {
            'border-left': 'none',
            'padding-left': '0',
            'margin-left': '0',
            'flex-basis': '100%',
            'text-align': 'center',
          },
        ),
      ]),
    ]),
  ];
}
