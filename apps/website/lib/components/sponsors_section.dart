import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/generated_sponsors.dart';
import '../constants/sponsors.dart';
import '../constants/theme.dart';
import '../l10n/strings.dart';

/// Home-page Sponsors section: a centered "logo wall" grouped by tier.
///
/// Tiers and logo-cell sizes follow the Figma layout (node 656:2718):
/// Platinum 256 / Gold 192 / Silver·Bronze·Tool·Student·Community 144.
/// Each of those logos links to `sponsors/{slug}`. Individual sponsors (96px
/// avatar) are the exception — see [_IndividualSponsorCard] — and link out to
/// GitHub instead.
/// Firestore document id of Flutter (Google) — pinned to the front of the
/// sponsor wall regardless of the default id-ascending order.
const String _pinnedFirstId = 'D2026-015';

class SponsorsSection extends StatelessComponent {
  const SponsorsSection({super.key});

  @override
  Component build(BuildContext context) {
    final strings = LocaleScope.stringsOf(context);
    // Order sponsors by their (opaque) Firestore document id ascending, so the
    // wall has a stable, name-agnostic ordering within tiers. The slug now
    // carries the admin-entered detail-page path and is no longer id-derived,
    // so sort on the id explicitly rather than the slug.
    //
    // Exception: Flutter (Google) is pinned to the front of its tier
    // unconditionally — as the namesake sponsor it always leads the wall,
    // regardless of where its document id falls in the ascending order.
    final ordered = [...generatedSponsors]
      ..sort((s1, s2) {
        if (s1.id == _pinnedFirstId) return s2.id == _pinnedFirstId ? 0 : -1;
        if (s2.id == _pinnedFirstId) return 1;
        return s1.id.compareTo(s2.id);
      });
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
        // Match the Event Information section's tinted background.
        raw: const {'background-color': '#FDF7FF'},
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
          display: .flex,
          justifyContent: .center,
          alignItems: .start,
          width: 100.percent,
          raw: const {'flex-wrap': 'wrap', 'gap': '24px'},
        ),
      ]),

      // ── Logo card ───────────────────────────────────────────────────
      css('.sponsor-card', [
        css('&').styles(
          display: .flex,
          alignItems: .center,
          justifyContent: .center,
          backgroundColor: onBrand,
          radius: .circular(16.px),
          border: Border.all(
            style: BorderStyle.solid,
            color: const Color('#CBC3D933'), // rgba(203,195,217,0.2)
            width: 1.px,
          ),
          textDecoration: const TextDecoration(line: TextDecorationLine.none),
          // No padding here: CSS percentage padding resolves against the PARENT
          // width (same for every card) and would swamp the fixed tier widths
          // (collapsing the logo to nothing). Breathing room is set on the <img>
          // below, whose % sizing IS relative to this card — so it scales per tier.
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
        // Logo occupies 70% of the card (≈15% clear space each side — the
        // breathing room formerly baked into the generated asset). % is relative
        // to this card, so it scales correctly per tier. Centered via the card's
        // flex alignment. White plate hides the baked white glow some logos carry
        // (see sponsors.dart) regardless of surrounding colour.
        css('img').styles(
          width: 70.percent,
          height: 70.percent,
          backgroundColor: onBrand,
          raw: const {'object-fit': 'contain'},
        ),
        // Tier sizes: fixed widths (square via aspect-ratio). The logo size is
        // intentionally NOT responsive — the grid wraps (`flex-wrap: wrap`) so
        // narrower viewports show fewer cards per row rather than shrinking each
        // logo. Sizes follow the Figma layout (node 656:2718).
        css('&.sponsor-card--xl').styles(
          raw: const {'width': '256px'},
        ),
        css('&.sponsor-card--lg').styles(
          raw: const {'width': '192px'},
        ),
        css('&.sponsor-card--md').styles(
          raw: const {'width': '144px'},
        ),
      ]),

      // ── Individual sponsor card ────────────────────────────────────
      // Unlike other tiers, this isn't a `.sponsor-card`: the avatar is a
      // fixed 96px circular tile (same square-logo asset as other tiers,
      // but cropped to fill — a profile photo, unlike a company logo, isn't
      // guaranteed square and shouldn't be letterboxed), with the GitHub
      // icon + display name stacked below it. The whole card links out to
      // GitHub rather than the site's own detail page — but only when a
      // GitHub URL is on record; otherwise it renders as a plain, inert
      // `<div>` with no `--linked` modifier (see `_IndividualSponsorCard`),
      // so it never picks up the hover/focus affordance below.
      css('.individual-card', [
        css('&').styles(
          display: .flex,
          flexDirection: .column,
          alignItems: .center,
          gap: Gap.row(8.px),
          width: 140.px,
          textDecoration: const TextDecoration(line: TextDecorationLine.none),
          raw: const {'flex-shrink': '0'},
        ),
        css('&.individual-card--linked:hover .individual-card__avatar').styles(
          raw: const {
            'transform': 'translateY(-3px)',
            'box-shadow': '6px 8px 8px rgba(0, 0, 0, 0.22)',
          },
        ),
        css('&.individual-card--linked:focus-visible').styles(
          raw: const {'outline': '3px solid #65558F', 'outline-offset': '2px'},
        ),
        css('.individual-card__avatar', [
          css('&').styles(
            width: 96.px,
            height: 96.px,
            backgroundColor: onBrand,
            radius: .circular(999.px),
            border: Border.all(
              style: BorderStyle.solid,
              color: eventCardBorderSocial,
              width: 1.px,
            ),
            raw: const {
              'flex-shrink': '0',
              'overflow': 'hidden',
              'box-shadow': '4px 4px 2px rgba(0, 0, 0, 0.25)',
              'transition': 'transform 150ms ease, box-shadow 150ms ease',
            },
          ),
          css('img').styles(
            width: 100.percent,
            height: 100.percent,
            raw: const {'object-fit': 'cover'},
          ),
        ]),
        css('.individual-card__meta').styles(
          display: .flex,
          alignItems: .start,
          justifyContent: .center,
          gap: Gap.column(4.px),
          width: 100.percent,
        ),
        css('.individual-card__github-icon').styles(
          width: 14.px,
          height: 14.px,
          raw: const {'flex-shrink': '0'},
        ),
        css('.individual-card__name').styles(
          color: const Color('#1D1A25'),
          fontFamily: uiFontFamily,
          fontWeight: .w500,
          textAlign: .center,
          raw: const {
            'font-size': '14px',
            'line-height': '20px',
            'word-break': 'auto-phrase',
            'overflow-wrap': 'anywhere',
          },
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
    SponsorTier.platinum => 'sponsor-card--xl',
    SponsorTier.gold => 'sponsor-card--lg',
    _ => 'sponsor-card--md',
  };

  @override
  Component build(BuildContext context) {
    final name = sponsor.name.resolve(strings.locale);
    if (sponsor.tier == SponsorTier.individual) {
      return _IndividualSponsorCard(sponsor: sponsor, strings: strings, name: name);
    }
    return a(
      href: strings.locale.sponsorHref(sponsor.slug),
      classes: 'sponsor-card ${_sizeClass(sponsor.tier)}',
      attributes: {'aria-label': strings.sponsorCardAriaLabel(name)},
      [
        img(src: sponsor.squareLogo, alt: name, attributes: const {'loading': 'lazy'}),
      ],
    );
  }
}

/// Individual sponsors don't have a company site, so the generic "Web" link
/// (from Firestore's `websiteUrl`) is repurposed to carry their GitHub
/// profile URL instead.
String? _individualGithubUrl(Sponsor sponsor) {
  for (final link in sponsor.links) {
    if (link.type == SponsorLinkType.other) return link.url;
  }
  return null;
}

/// Individual-sponsor card: a circular avatar (same square logo asset as
/// other tiers, cropped to fill) with the GitHub icon + display name below
/// it. The whole card links out to the sponsor's GitHub profile rather than
/// the site's own detail page — unlike every other tier.
class _IndividualSponsorCard extends StatelessComponent {
  const _IndividualSponsorCard({
    required this.sponsor,
    required this.strings,
    required this.name,
  });

  final Sponsor sponsor;
  final Strings strings;
  final String name;

  @override
  Component build(BuildContext context) {
    final githubUrl = _individualGithubUrl(sponsor);
    final avatar = div(classes: 'individual-card__avatar', [
      img(src: sponsor.squareLogo, alt: '', attributes: const {'loading': 'lazy', 'aria-hidden': 'true'}),
    ]);
    final meta = div(classes: 'individual-card__meta', [
      if (githubUrl != null)
        img(
          classes: 'individual-card__github-icon',
          src: 'images/icons/link_github.svg',
          alt: '',
          attributes: const {'aria-hidden': 'true'},
        ),
      span(classes: 'individual-card__name', [.text(name)]),
    ]);

    // No GitHub URL on record (e.g. only an X/Twitter link was provided):
    // show the avatar and name without a click target rather than guessing
    // a fallback destination. No `--linked` modifier, so it doesn't pick up
    // the hover/focus affordance either.
    if (githubUrl == null) {
      return div(classes: 'individual-card', [avatar, meta]);
    }
    return a(
      href: githubUrl,
      target: Target.blank,
      classes: 'individual-card individual-card--linked',
      attributes: {
        'aria-label': strings.sponsorGithubCardAriaLabel(name),
        'rel': 'noopener noreferrer',
      },
      [avatar, meta],
    );
  }
}
