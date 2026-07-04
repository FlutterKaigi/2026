import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/generated_sponsors.dart';
import '../constants/sponsors.dart';
import '../constants/theme.dart';
import '../l10n/strings.dart';

/// Home-page Job Boards section.
///
/// Displays a card grid of sponsors that have a [Sponsor.jobBoardUrl].
/// When there are no such sponsors the section renders nothing (empty fragment).
///
/// CSS class names deliberately avoid "sponsor", "job", "recruit", and "ad" to
/// prevent cosmetic ad-blocker filters from hiding the section. Use "hiring-*"
/// instead (see sponsor_detail.dart comment near connect-link for background).
class HiringSection extends StatelessComponent {
  const HiringSection({super.key});

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    final hiringSponsors = sponsorsWithJobBoard(generatedSponsors);

    // 0件なら何も描画しない
    if (hiringSponsors.isEmpty) return Component.fragment([]);

    return section(id: 'job-boards', classes: 'hiring-section', [
      div(classes: 'hiring-section__inner', [
        div(classes: 'hiring-section__header', [
          div(classes: 'hiring-section__eyecatch', [
            img(
              src: 'images/icons/link_briefcase.svg',
              alt: '',
              attributes: const {'aria-hidden': 'true'},
            ),
          ]),
          h2(classes: 'hiring-section__title', [.text('Job Boards')]),
          p(classes: 'hiring-section__subtitle', [.text(strings.jobBoardsSubtitle)]),
        ]),
        div(
          classes: 'hiring-grid',
          [
            for (final sponsor in hiringSponsors) _HiringCard(sponsor: sponsor, strings: strings),
          ],
        ),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.hiring-section', [
      css('&').styles(
        display: .flex,
        justifyContent: .center,
        width: 100.percent,
        padding: .symmetric(horizontal: 24.px, vertical: 128.px),
        // sponsors-section と同一の tinted background
        raw: const {'background-color': '#FDF7FF'},
      ),
      css('.hiring-section__inner').styles(
        display: .flex,
        flexDirection: .column,
        alignItems: .center,
        width: 100.percent,
        gap: Gap.row(48.px),
        raw: const {'max-width': '1232px'},
      ),
      css('.hiring-section__header', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          alignItems: .center,
          gap: Gap.row(16.px),
          textAlign: .center,
        ),
        css('.hiring-section__eyecatch', [
          css('&').styles(
            display: .flex,
            alignItems: .center,
            justifyContent: .center,
            width: 44.px,
            height: 44.px,
            radius: .circular(16.px),
            backgroundColor: primaryContainer,
            raw: const {'flex-shrink': '0'},
          ),
          css('img').styles(width: 22.px, height: 22.px),
        ]),
        css('.hiring-section__title').styles(
          color: const Color('#1D1A25'),
          fontFamily: displayFontFamily,
          fontWeight: .w700,
          raw: const {
            'font-size': 'clamp(1.75rem, 4vw, 2.5rem)',
            'line-height': '1.2',
          },
        ),
        css('.hiring-section__subtitle').styles(
          color: const Color('#494456'),
          fontFamily: uiFontFamily,
          fontWeight: .w400,
          raw: const {
            'font-size': 'clamp(0.95rem, 2vw, 1.125rem)',
            'line-height': '1.5',
          },
        ),
      ]),

      // Grid: flex-wrap で自然に中央寄せ（sponsors-section と同じアプローチ）。
      // 件数が少ないときも justify-content: center で自動的にセンタリングされる。
      css('.hiring-grid').styles(
        display: .flex,
        justifyContent: .center,
        width: 100.percent,
        raw: const {'flex-wrap': 'wrap', 'gap': '24px'},
      ),

      // Card: 固定幅 240px — flex-wrap の中央寄せと組み合わせて
      // sponsors-section と同じく件数が少なくても自然にセンタリングされる。
      css('.hiring-card', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          alignItems: .center,
          gap: Gap.row(16.px),
          padding: .all(24.px),
          backgroundColor: onBrand,
          radius: .circular(16.px),
          border: Border.all(
            style: BorderStyle.solid,
            color: const Color('#CBC3D933'),
            width: 1.px,
          ),
          raw: const {
            'width': '240px',
            'flex-shrink': '0',
            'box-shadow': '4px 4px 2px rgba(0, 0, 0, 0.25)',
            'transition': 'transform 150ms ease, box-shadow 150ms ease',
          },
        ),
        css('&:hover').styles(
          raw: const {
            'transform': 'translateY(-3px)',
            'box-shadow': '6px 8px 8px rgba(0, 0, 0, 0.22)',
          },
        ),
        css('.hiring-card__logo', [
          css('&').styles(
            display: .flex,
            alignItems: .center,
            justifyContent: .center,
            width: 100.percent,
            height: 88.px,
            backgroundColor: onBrand,
          ),
          css('img').styles(
            backgroundColor: onBrand,
            raw: const {
              'max-width': '100%',
              'max-height': '100%',
              'object-fit': 'contain',
            },
          ),
        ]),
        css('.hiring-card__cta', [
          css('&').styles(
            display: .flex,
            alignItems: .center,
            justifyContent: .center,
            gap: Gap.column(8.px),
            width: 100.percent,
            padding: .symmetric(horizontal: 20.px, vertical: 12.px),
            backgroundColor: primaryContainer,
            color: onPrimaryContainer,
            fontFamily: uiFontFamily,
            fontWeight: .w500,
            radius: .circular(8.px),
            textDecoration: const TextDecoration(line: TextDecorationLine.none),
            raw: const {
              'box-sizing': 'border-box',
              'margin-top': 'auto',
              'font-size': '14px',
              'line-height': '20px',
              'letter-spacing': '0.1px',
              'transition': 'background-image 150ms ease',
            },
          ),
          css('&:hover').styles(
            // M3 State Layer (Hover 8%) — onPrimaryContainer の 8% オーバーレイ。
            // background-color の単純上書きだと半透明色が透けるため gradient で重ねる。
            raw: const {
              'background-image':
                  'linear-gradient('
                  '$onPrimaryContainerHoverHex, $onPrimaryContainerHoverHex)',
            },
          ),
          css('&:focus-visible').styles(
            raw: const {'outline': '3px solid #65558F', 'outline-offset': '2px'},
          ),
          css('.hiring-card__cta-icon').styles(
            width: 16.px,
            height: 16.px,
            raw: const {'flex-shrink': '0', 'opacity': '0.9'},
          ),
          css('.hiring-card__cta-ext').styles(
            raw: const {'font-size': '13px', 'opacity': '0.75', 'flex-shrink': '0'},
          ),
        ]),
      ]),
    ]),

    css.media(MediaQuery.all(maxWidth: 960.px), [
      css('.hiring-section').styles(
        padding: .symmetric(horizontal: 24.px, vertical: 80.px),
      ),
      css('.hiring-section__inner').styles(gap: Gap.row(40.px)),
    ]),
    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.hiring-section').styles(
        padding: .symmetric(horizontal: 16.px, vertical: 56.px),
      ),
      css('.hiring-section__inner').styles(gap: Gap.row(32.px)),
    ]),
  ];
}

class _HiringCard extends StatelessComponent {
  const _HiringCard({required this.sponsor, required this.strings});

  final Sponsor sponsor;
  final Strings strings;

  @override
  Component build(BuildContext context) {
    final name = sponsor.name.resolve(strings.locale);
    return div(classes: 'hiring-card', [
      div(classes: 'hiring-card__logo', [
        img(
          src: sponsor.wideLogo,
          alt: name,
          attributes: const {'loading': 'lazy'},
        ),
      ]),
      a(
        href: sponsor.jobBoardUrl!,
        target: Target.blank,
        classes: 'hiring-card__cta',
        attributes: {
          'rel': 'noopener noreferrer',
          'aria-label': strings.jobBoardsCardAriaLabel(name),
        },
        [
          img(
            classes: 'hiring-card__cta-icon',
            src: 'images/icons/link_briefcase.svg',
            alt: '',
            attributes: const {'aria-hidden': 'true'},
          ),
          span([.text(strings.jobBoardsCta)]),
          span(
            classes: 'hiring-card__cta-ext',
            attributes: const {'aria-hidden': 'true'},
            [.text('↗')],
          ),
        ],
      ),
    ]);
  }
}
