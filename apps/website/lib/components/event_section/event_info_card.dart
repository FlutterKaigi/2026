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
        div(classes: 'event-info-card__cta-row', [
          button(
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
                  .text(
                    strings.eventInfoTicketsOpensAt(
                      ticketsOpen.dateFor(locale),
                    ),
                  ),
                ]),
            ],
            classes: 'event-info-card__cta',
            type: ButtonType.button,
            disabled: true,
            attributes: {'aria-label': strings.eventInfoTicketsAriaLabel},
          ),
          button(
            [
              span(classes: 'event-info-card__cta-label', [
                .text(strings.eventInfoSessionClosed),
              ]),
            ],
            classes: 'event-info-card__cta',
            type: ButtonType.button,
            disabled: true,
          ),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.event-info-card', [
      css('&').styles(
        display: .flex,
        flexDirection: .column,
        // 隣の Roadmap が背高（マイルストーン件数で伸縮）でも、stretch で
        // 引き伸ばされた余白を各ブロック間に均等配分して間延びを防ぐ。
        // gap は最小間隔として残るので、伸ばされない時のレイアウトは不変。
        justifyContent: .spaceBetween,
        padding: .all(49.px),
        backgroundColor: eventCardSurfaceInfo,
        radius: .circular(24.px),
        border: Border.all(
          style: BorderStyle.solid,
          color: eventCardBorder,
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
          backgroundColor: primaryContainer,
          alignItems: .center,
          justifyContent: .center,
          raw: const {'flex-shrink': '0'},
        ),
        css('img').styles(width: 20.px, height: 20.px),
      ]),
      css('.event-info-card__title').styles(
        color: onSurface,
        fontFamily: uiFontFamily,
        fontWeight: .w500,
        raw: const {'font-size': '22px', 'line-height': '28px'},
      ),
      // DATE/VENUE 行：auto-fit + minmax で「収まれば2列、狭ければ1列」を自動切替。
      css('.event-info-card__rows').styles(
        display: .grid,
        raw: const {
          'grid-template-columns': 'repeat(auto-fit, minmax(min(100%, 320px), 1fr))',
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
        color: onSurfaceVariant,
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
        color: onSurface,
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
        color: onSurface,
        fontFamily: uiFontFamily,
        fontWeight: .w400,
        raw: const {'font-size': '22px', 'line-height': '28px'},
      ),
      css('.event-info-card__tickets').styles(
        display: .flex,
        flexDirection: .column,
        gap: Gap.row(8.px),
      ),
      // CTA 群：横並び。幅が足りなければ自動で折り返す。
      // row-gap も持たせ、縦積み（レスポンシブ時）でもボタン間に間隔を確保する。
      css('.event-info-card__cta-row').styles(
        display: .flex,
        flexWrap: .wrap,
        alignItems: .center,
        raw: const {'margin-top': '4px', 'gap': '16px 24px'},
      ),
      // Disabled CTA：時計アイコン+ラベル+販売開始日のmeta行。
      // `<button disabled>` 標準 disabled でブラウザのキーボード操作・aria 伝達を任せる。
      // デスクトップは inline-flex で内容幅、タブレット以下はカード幅いっぱい。
      css('.event-info-card__cta', [
        css('&').styles(
          display: .inlineFlex,
          padding: .symmetric(horizontal: 20.px, vertical: 12.px),
          alignItems: .center,
          gap: Gap.column(10.px),
          backgroundColor: eventCtaDisabledBg,
          color: eventCtaDisabledFg,
          fontFamily: uiFontFamily,
          fontWeight: .w500,
          radius: .circular(8.px),
          border: Border.all(style: BorderStyle.none),
          raw: const {
            'font-size': '14px',
            'line-height': '20px',
            'letter-spacing': '0.1px',
            'align-self': 'flex-start',
            'cursor': 'not-allowed',
            'user-select': 'none',
            'flex-wrap': 'wrap',
            // `<button disabled>` のブラウザ既定（不透明度低下・色変化）を打ち消す。
            'opacity': '1',
            '-webkit-appearance': 'none',
            'appearance': 'none',
            'text-align': 'left',
            'text-decoration': 'none',
          },
        ),
        // セッション応募 CTA：活性リンク。クリック可能であることを示す。
        css('&.event-info-card__cta--active').styles(
          backgroundColor: primaryContainer,
          color: onPrimaryContainer,
          raw: const {
            'cursor': 'pointer',
            'transition': 'background-color 150ms ease',
          },
        ),
        // M3 State Layer (Hover 8%) — onPrimaryContainer 由来のオーバーレイを
        // 単色の primaryContainer 上に重ねる。background-color の差し替えだと
        // 半透明色の背後にカード面が透けるため、linear-gradient で塗り重ねる。
        css('&.event-info-card__cta--active:hover').styles(
          raw: const {
            'background-image':
                'linear-gradient('
                '$onPrimaryContainerHoverHex, $onPrimaryContainerHoverHex)',
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
