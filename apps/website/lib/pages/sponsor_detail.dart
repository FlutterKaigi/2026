import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/meta.dart';
import '../constants/build_config.dart';
import '../constants/site.dart';
import '../constants/sponsors.dart';
import '../constants/theme.dart';
import '../l10n/strings.dart';

/// Sponsor detail page at `sponsors/{slug}` (Figma node 668:3547).
///
/// Layout: back link → full-width logo banner → two columns (tier badge +
/// name + Connect links on the left, PR text on the right). Per-page OGP is
/// injected via `Document.head()`.
class SponsorDetailPage extends StatelessComponent {
  const SponsorDetailPage({super.key, required this.sponsor});

  final Sponsor sponsor;

  static String _linkIcon(SponsorLinkType type) => switch (type) {
    SponsorLinkType.x => 'images/icons/sponsor_x.svg',
    SponsorLinkType.recruit => 'images/icons/sponsor_briefcase.svg',
    SponsorLinkType.other => 'images/icons/sponsor_globe.svg',
  };

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    final locale = strings.locale;

    return Component.fragment([
      Document.head(
        meta: {'description': _clip(sponsor.prText, 160)},
        children: [
          ogMeta('og:title', '${sponsor.name} | FlutterKaigi 2026'),
          ogMeta('og:description', _clip(sponsor.prText, 200)),
          ogMeta('og:image', _absUrl(sponsor.ogpImage)),
          ogMeta('og:type', 'article'),
          ogMeta('og:url', '$siteOrigin${locale.sponsorHref(sponsor.slug)}/'),
        ],
      ),
      section(classes: 'sponsor-detail', [
        div(classes: 'sponsor-detail__inner', [
          a(
            href: locale.sponsorsAnchorHref,
            classes: 'sponsor-detail__back',
            [
              span(
                classes: 'sponsor-detail__back-arrow',
                attributes: const {'aria-hidden': 'true'},
                [.text('←')],
              ),
              span([.text(strings.sponsorBackToList)]),
            ],
          ),
          div(classes: 'sponsor-detail__banner', [
            img(
              classes: 'sponsor-detail__logo',
              src: sponsor.wideLogo,
              alt: sponsor.name,
            ),
          ]),
          div(classes: 'sponsor-detail__body', [
            div(classes: 'sponsor-detail__meta', [
              span(
                classes: 'sponsor-detail__badge badge--${sponsor.tier.name}',
                [.text(strings.sponsorTierBadge(sponsor.tier.label))],
              ),
              h1(classes: 'sponsor-detail__name', [.text(sponsor.name)]),
              if (sponsor.links.isNotEmpty)
                div(classes: 'sponsor-detail__links', [
                  h2(classes: 'sponsor-detail__links-title', [
                    .text(strings.sponsorConnectHeading),
                  ]),
                  div(classes: 'sponsor-detail__links-list', [
                    for (final link in sponsor.links)
                      a(
                        href: link.url,
                        target: Target.blank,
                        classes: 'sponsor-link',
                        attributes: const {'rel': 'noopener noreferrer'},
                        [
                          span(classes: 'sponsor-link__icon', [
                            img(
                              src: _linkIcon(link.type),
                              alt: '',
                              attributes: const {'aria-hidden': 'true'},
                            ),
                          ]),
                          span(classes: 'sponsor-link__title', [.text(link.title)]),
                          span(
                            classes: 'sponsor-link__ext',
                            attributes: const {'aria-hidden': 'true'},
                            [.text('↗')],
                          ),
                        ],
                      ),
                  ]),
                ]),
            ]),
            div(classes: 'sponsor-detail__desc', [
              div(classes: 'sponsor-detail__pr', [.text(sponsor.prText)]),
            ]),
          ]),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.sponsor-detail', [
      css('&').styles(
        display: .flex,
        justifyContent: .center,
        width: 100.percent,
        padding: .symmetric(horizontal: 24.px, vertical: 48.px),
        raw: const {'background-color': '#FDF7FF'},
      ),
      css('.sponsor-detail__inner').styles(
        display: .flex,
        flexDirection: .column,
        width: 100.percent,
        gap: Gap.row(24.px),
        raw: const {'max-width': '1232px'},
      ),

      // Back link.
      css('.sponsor-detail__back', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          gap: Gap.column(8.px),
          color: const Color('#4700AF'),
          fontFamily: uiFontFamily,
          textDecoration: const TextDecoration(line: TextDecorationLine.none),
          raw: const {'font-size': '16px', 'width': 'fit-content'},
        ),
        css('&:hover').styles(
          raw: const {'text-decoration': 'underline', 'text-underline-offset': '0.2em'},
        ),
        css('.sponsor-detail__back-arrow').styles(raw: const {'font-size': '18px'}),
      ]),

      // Logo banner.
      css('.sponsor-detail__banner', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          justifyContent: .center,
          width: 100.percent,
          backgroundColor: onBrand,
          radius: .circular(16.px),
          border: Border.all(
            style: BorderStyle.solid,
            color: const Color('#CBC3D933'),
            width: 1.px,
          ),
          raw: const {
            'min-height': 'clamp(220px, 30vw, 360px)',
            'padding': 'clamp(24px, 4vw, 48px)',
          },
        ),
        css('.sponsor-detail__logo').styles(
          raw: const {
            'max-width': '86%',
            'max-height': 'clamp(150px, 22vw, 280px)',
            'object-fit': 'contain',
          },
        ),
      ]),

      // Two-column body.
      css('.sponsor-detail__body').styles(
        display: .flex,
        alignItems: .start,
        width: 100.percent,
        gap: Gap.column(48.px),
        padding: .symmetric(vertical: 24.px),
      ),
      css('.sponsor-detail__meta').styles(
        display: .flex,
        flexDirection: .column,
        gap: Gap.row(24.px),
        width: 100.percent,
        raw: const {'max-width': '460px', 'flex-shrink': '0'},
      ),

      // Tier badge.
      css('.sponsor-detail__badge', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          alignSelf: .start,
          padding: .symmetric(horizontal: 16.px, vertical: 6.px),
          color: onBrand,
          fontFamily: uiFontFamily,
          fontWeight: .w700,
          radius: .circular(999.px),
          raw: const {
            'font-size': '14px',
            'letter-spacing': '0.8px',
            'text-transform': 'uppercase',
            'background': '#65558F',
          },
        ),
        css('&.badge--platinum').styles(
          raw: const {'background': 'linear-gradient(90deg, #FF9100 0%, #FB8700 100%)'},
        ),
        css('&.badge--gold').styles(
          raw: const {'background': 'linear-gradient(90deg, #F4B400 0%, #E59400 100%)'},
        ),
        css('&.badge--silver').styles(
          raw: const {'background': 'linear-gradient(90deg, #9AA0A6 0%, #7C8388 100%)'},
        ),
        css('&.badge--bronze').styles(
          raw: const {'background': 'linear-gradient(90deg, #C7864F 0%, #A86B3C 100%)'},
        ),
        // Tool shares Individual's purple (per design feedback).
        css('&.badge--tool').styles(
          raw: const {'background': 'linear-gradient(90deg, #7E57C2 0%, #65558F 100%)'},
        ),
        css('&.badge--student').styles(
          raw: const {'background': 'linear-gradient(90deg, #2E9E5B 0%, #228A4C 100%)'},
        ),
        css('&.badge--community').styles(
          raw: const {'background': 'linear-gradient(90deg, #1E88E5 0%, #1565C0 100%)'},
        ),
        css('&.badge--individual').styles(
          raw: const {'background': 'linear-gradient(90deg, #7E57C2 0%, #65558F 100%)'},
        ),
      ]),

      css('.sponsor-detail__name').styles(
        color: const Color('#1D1A25'),
        fontFamily: displayFontFamily,
        fontWeight: .w700,
        raw: const {'font-size': 'clamp(1.375rem, 3vw, 1.875rem)', 'line-height': '1.25'},
      ),

      // Connect links card.
      css('.sponsor-detail__links', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(16.px),
          width: 100.percent,
          padding: .all(25.px),
          radius: .circular(12.px),
          border: Border.all(
            style: BorderStyle.solid,
            color: const Color('#CBC3D9'),
            width: 1.px,
          ),
          raw: const {'background-color': '#F3EBFB'},
        ),
        css('.sponsor-detail__links-title').styles(
          color: const Color('#1D1A25'),
          fontFamily: uiFontFamily,
          fontWeight: .w500,
          raw: const {'font-size': '16px', 'line-height': '24px'},
        ),
        css('.sponsor-detail__links-list').styles(
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(8.px),
        ),
        css('.sponsor-link', [
          css('&').styles(
            display: .flex,
            alignItems: .center,
            gap: Gap.column(12.px),
            padding: .all(8.px),
            color: const Color('#494456'),
            fontFamily: uiFontFamily,
            radius: .circular(8.px),
            textDecoration: const TextDecoration(line: TextDecorationLine.none),
            raw: const {'font-size': '16px', 'transition': 'background-color 150ms ease'},
          ),
          css('&:hover').styles(raw: const {'background-color': '#FFFFFF99'}),
          css('.sponsor-link__icon', [
            css('&').styles(
              display: .flex,
              alignItems: .center,
              justifyContent: .center,
              raw: const {'flex-shrink': '0'},
            ),
            css('img').styles(width: 20.px, height: 20.px),
          ]),
          css('.sponsor-link__title').styles(
            raw: const {'flex': '1 1 auto', 'min-width': '0', 'overflow-wrap': 'anywhere'},
          ),
          css('.sponsor-link__ext').styles(
            color: onSurfaceVariant,
            raw: const {'font-size': '14px', 'flex-shrink': '0'},
          ),
        ]),
      ]),

      // Description / PR text.
      css('.sponsor-detail__desc', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          gap: Gap.row(16.px),
          raw: const {'flex': '1 1 0', 'min-width': '0'},
        ),
        css('.sponsor-detail__pr').styles(
          color: const Color('#494456'),
          fontFamily: uiFontFamily,
          raw: const {
            'font-size': '16px',
            'line-height': '1.7',
            'white-space': 'pre-wrap',
            'overflow-wrap': 'anywhere',
          },
        ),
      ]),
    ]),

    // Stack columns on narrower viewports.
    css.media(MediaQuery.all(maxWidth: 860.px), [
      css('.sponsor-detail__body').styles(flexDirection: .column, gap: Gap.row(32.px)),
      css('.sponsor-detail__meta').styles(raw: const {'max-width': '100%'}),
    ]),
    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.sponsor-detail').styles(
        padding: .symmetric(horizontal: 16.px, vertical: 32.px),
      ),
    ]),
  ];
}

/// Collapses whitespace and clips to [max] characters for meta descriptions.
String _clip(String s, int max) {
  final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.length <= max) return t;
  return '${t.substring(0, max - 1).trimRight()}…';
}

/// Absolute URL for an OGP asset path (or a passthrough remote URL).
String _absUrl(String asset) =>
    asset.startsWith('http') ? asset : '$siteOrigin$baseHref$asset';
