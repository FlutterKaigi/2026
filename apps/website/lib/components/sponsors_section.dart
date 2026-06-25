import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/generated_sponsors.dart';
import '../constants/sponsors.dart';
import '../constants/theme.dart';
import '../l10n/strings.dart';

/// Home-page Sponsors section: a centered "logo wall" grouped by tier.
///
/// Tiers and logo-cell sizes follow the Figma layout (node 656:2718):
/// Platinum 256 / Gold 192 / Silver·Bronze·Tool·Student·Community 144 /
/// Individual 96. Each logo links to `sponsors/{slug}`.
class SponsorsSection extends StatelessComponent {
  const SponsorsSection({super.key});

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    // Order sponsors by their (opaque) Firestore document id — i.e. slug —
    // ascending, so the wall has a stable, name-agnostic ordering within tiers.
    final ordered = [...generatedSponsors]..sort((s1, s2) => s1.slug.compareTo(s2.slug));
    final byTier = groupSponsorsByTier(ordered);

    return section(id: 'sponsors', classes: 'sponsors-section', [
      div(classes: 'sponsors-section__inner', [
        div(classes: 'sponsors-section__header', [
          h2(classes: 'sponsors-section__title', [.text(strings.sponsorsTitle)]),
          p(classes: 'sponsors-section__subtitle', [.text(strings.sponsorsSubtitle)]),
        ]),
        for (final entry in byTier.entries)
          div(classes: 'sponsors-tier', [
            h3(classes: 'sponsors-tier__heading', [.text(entry.key.label)]),
            div(classes: 'sponsors-tier__grid', [
              for (final sponsor in entry.value) _SponsorLogoCard(sponsor: sponsor, strings: strings),
            ]),
          ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.sponsors-section', [
      css('&').styles(
        display: .flex,
        justifyContent: .center,
        width: 100.percent,
        padding: .symmetric(horizontal: 24.px, vertical: 128.px),
        backgroundColor: onBrand, // white
      ),
      css('.sponsors-section__inner').styles(
        display: .flex,
        flexDirection: .column,
        alignItems: .center,
        width: 100.percent,
        gap: Gap.row(64.px),
        raw: const {'max-width': '1232px'},
      ),
      css('.sponsors-section__header', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          alignItems: .center,
          gap: Gap.row(16.px),
          textAlign: .center,
        ),
        css('.sponsors-section__title').styles(
          color: const Color('#1D1A25'),
          fontFamily: displayFontFamily,
          fontWeight: .w700,
          raw: const {
            'font-size': 'clamp(1.75rem, 4vw, 2.5rem)',
            'line-height': '1.2',
          },
        ),
        css('.sponsors-section__subtitle').styles(
          color: const Color('#494456'),
          fontFamily: uiFontFamily,
          fontWeight: .w400,
          raw: const {
            'font-size': 'clamp(0.95rem, 2vw, 1.125rem)',
            'line-height': '1.5',
          },
        ),
      ]),
      css('.sponsors-tier', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          alignItems: .center,
          width: 100.percent,
          gap: Gap.row(32.px),
        ),
        css('.sponsors-tier__heading').styles(
          color: const Color('#1D1A25'),
          fontFamily: uiFontFamily,
          fontWeight: .w400,
          textAlign: .center,
          raw: const {'font-size': '22px', 'line-height': '28px'},
        ),
        css('.sponsors-tier__grid').styles(
          alignItems: .start,
          display: .flex,
          justifyContent: .center,
          width: 100.percent,
          raw: const {'flex-wrap': 'wrap', 'gap': '24px'},
        ),
      ]),

      // ── Logo cell: square logo tile + optional social icon links ───────
      css('.sponsor-cell', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          alignItems: .center,
          gap: Gap.row(10.px),
          raw: const {'flex-shrink': '0'},
        ),
        // Tier sizes (fluid via clamp). The tile squares itself via aspect-ratio.
        css('&.sponsor-cell--xl').styles(raw: const {'width': 'clamp(180px, 38vw, 256px)'}),
        css('&.sponsor-cell--lg').styles(raw: const {'width': 'clamp(150px, 30vw, 192px)'}),
        css('&.sponsor-cell--md').styles(raw: const {'width': 'clamp(112px, 24vw, 144px)'}),
        css('&.sponsor-cell--sm').styles(raw: const {'width': 'clamp(84px, 18vw, 96px)'}),

        // Icon-only link row beneath the logo.
        css('.sponsor-cell__links').styles(
          display: .flex,
          alignItems: .center,
          justifyContent: .center,
          flexWrap: .wrap,
          width: 100.percent,
          gap: Gap.all(8.px),
        ),
        css('.sponsor-cell__link', [
          css('&').styles(
            display: .flex,
            alignItems: .center,
            justifyContent: .center,
            width: 32.px,
            height: 32.px,
            color: const Color('#494456'),
            radius: .circular(999.px),
            border: Border.all(
              style: BorderStyle.solid,
              color: const Color('#CBC3D9'),
              width: 1.px,
            ),
            textDecoration: const TextDecoration(line: TextDecorationLine.none),
            raw: const {
              'flex-shrink': '0',
              'background-color': '#F3EBFB',
              'transition': 'transform 150ms ease, background-color 150ms ease',
            },
          ),
          css('&:hover').styles(
            raw: const {'transform': 'translateY(-2px)', 'background-color': '#FFFFFF'},
          ),
          css('&:focus-visible').styles(
            raw: const {'outline': '3px solid #65558F', 'outline-offset': '2px'},
          ),
          css('img').styles(width: 16.px, height: 16.px),
        ]),
      ]),

      // ── Logo tile ──────────────────────────────────────────────────────
      css('.sponsor-card', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          justifyContent: .center,
          width: 100.percent,
          padding: .all(1.px),
          backgroundColor: onBrand,
          radius: .circular(16.px),
          border: Border.all(
            style: BorderStyle.solid,
            color: const Color('#CBC3D933'), // rgba(203,195,217,0.2)
            width: 1.px,
          ),
          textDecoration: const TextDecoration(line: TextDecorationLine.none),
          raw: const {
            'aspect-ratio': '1',
            'flex-shrink': '0',
            'overflow': 'hidden',
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
        css('&:focus-visible').styles(
          raw: const {'outline': '3px solid #65558F', 'outline-offset': '2px'},
        ),
        css('img').styles(
          width: 100.percent,
          height: 100.percent,
          raw: const {'object-fit': 'contain'},
        ),
        // Individual sponsors are shown as circular tiles. The card chrome is
        // circular via border-radius; the logo itself is masked to a circle at
        // generation time (baked transparency), avoiding a replaced-<img>
        // clipping quirk that otherwise rendered an octagon.
        css('&.sponsor-card--circle').styles(
          raw: const {'border-radius': '50%'},
        ),
      ]),
    ]),

    // Tighten vertical rhythm on smaller screens.
    css.media(MediaQuery.all(maxWidth: 960.px), [
      css('.sponsors-section').styles(
        padding: .symmetric(horizontal: 24.px, vertical: 80.px),
      ),
      css('.sponsors-section__inner').styles(gap: Gap.row(48.px)),
    ]),
    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.sponsors-section').styles(
        padding: .symmetric(horizontal: 16.px, vertical: 56.px),
      ),
      css('.sponsors-tier').styles(gap: Gap.row(24.px)),
    ]),
  ];
}

class _SponsorLogoCard extends StatelessComponent {
  const _SponsorLogoCard({required this.sponsor, required this.strings});

  final Sponsor sponsor;
  final Strings strings;

  static String _sizeClass(SponsorTier tier) => switch (tier) {
    SponsorTier.platinum => 'sponsor-cell--xl',
    SponsorTier.gold => 'sponsor-cell--lg',
    SponsorTier.individual => 'sponsor-cell--sm',
    _ => 'sponsor-cell--md',
  };

  @override
  Component build(BuildContext context) {
    final name = sponsor.name.resolve(strings.locale);
    final isCircle = sponsor.tier == SponsorTier.individual;
    return div(classes: 'sponsor-cell ${_sizeClass(sponsor.tier)}', [
      a(
        href: strings.locale.sponsorHref(sponsor.slug),
        classes: 'sponsor-card${isCircle ? ' sponsor-card--circle' : ''}',
        attributes: {'aria-label': strings.sponsorCardAriaLabel(name)},
        [
          img(src: sponsor.squareLogo, alt: name, attributes: const {'loading': 'lazy'}),
        ],
      ),
      // Below the logo: only the links this sponsor actually supplied, as
      // icon-only buttons, centered. Order follows the generator
      // (website → X → recruit → job board).
      if (sponsor.links.isNotEmpty)
        div(classes: 'sponsor-cell__links', [
          for (final link in sponsor.links)
            a(
              href: link.url,
              target: Target.blank,
              classes: 'sponsor-cell__link',
              attributes: {'rel': 'noopener noreferrer', 'aria-label': link.title},
              [
                img(
                  src: sponsorLinkIconAsset(link.type),
                  alt: '',
                  attributes: const {'aria-hidden': 'true'},
                ),
              ],
            ),
        ]),
    ]);
  }
}
