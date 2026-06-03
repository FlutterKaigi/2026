/// Sponsor domain model + tier metadata.
///
/// This file is hand-written and checked into git. The *data* itself lives in
/// `generated_sponsors.dart`, which is generated at build time from the tracc
/// API (or a sample fixture) by `tool/generate_sponsors.dart` and is **never**
/// committed — see `.gitignore`. Keep this file free of any real sponsor data.
library;

/// Sponsorship tiers, in the order they are displayed on the site.
///
/// [logoBox] is the px size of the square logo cell in the home-page grid,
/// derived from the Figma layout (node 656:2718).
enum SponsorTier {
  platinum(label: 'Platinum', logoBox: 256),
  gold(label: 'Gold', logoBox: 192),
  silver(label: 'Silver', logoBox: 144),
  bronze(label: 'Bronze', logoBox: 144),
  tool(label: 'Tool', logoBox: 144),
  student(label: 'Student', logoBox: 144),
  community(label: 'Community', logoBox: 144),
  individual(label: 'Individual', logoBox: 96);

  const SponsorTier({required this.label, required this.logoBox});

  /// Brand-facing tier name (kept in English in both locales, as in the design).
  final String label;

  /// Side length (px) of the logo cell for this tier in the home grid.
  final int logoBox;
}

/// The kind of a sponsor link, used to pick an icon on the detail page.
enum SponsorLinkType {
  x,
  recruit,
  other;

  static SponsorLinkType parse(String? raw) => switch (raw?.toLowerCase().trim()) {
    'x' || 'twitter' => SponsorLinkType.x,
    'recruit' || 'careers' || 'jobs' => SponsorLinkType.recruit,
    _ => SponsorLinkType.other,
  };
}

/// A single outbound link shown on the sponsor detail page.
class SponsorLink {
  const SponsorLink({required this.url, required this.title, required this.type});

  final String url;
  final String title;
  final SponsorLinkType type;
}

/// A sponsor as rendered on the site.
///
/// Logo/OGP fields are *asset paths* relative to the site base href (e.g.
/// `images/sponsors/acme-square.png`). When logo processing fails (e.g. the
/// source was an SVG), they may fall back to the remote URL / default OGP.
class Sponsor {
  const Sponsor({
    required this.id,
    required this.slug,
    required this.tier,
    required this.name,
    required this.prText,
    required this.links,
    required this.squareLogo,
    required this.wideLogo,
    required this.ogpImage,
    this.benefits = const [],
    this.year = 2026,
  });

  final String id;

  /// URL-safe identifier; the detail page lives at `sponsors/{slug}`.
  final String slug;
  final SponsorTier tier;
  final String name;
  final String prText;
  final List<SponsorLink> links;

  /// Square logo asset (home grid). Path relative to base href, or a remote URL.
  final String squareLogo;

  /// Landscape logo asset (detail banner). Path relative to base href, or a remote URL.
  final String wideLogo;

  /// OGP image asset for this sponsor's detail page. Path relative to base href.
  final String ogpImage;

  /// Internal package perks. Held for completeness; not rendered publicly.
  final List<String> benefits;
  final int year;
}

/// Groups [sponsors] by tier, preserving [SponsorTier] declaration order and
/// dropping tiers that have no sponsors.
Map<SponsorTier, List<Sponsor>> groupSponsorsByTier(List<Sponsor> sponsors) {
  final byTier = <SponsorTier, List<Sponsor>>{};
  for (final tier in SponsorTier.values) {
    final inTier = sponsors.where((s) => s.tier == tier).toList();
    if (inTier.isNotEmpty) byTier[tier] = inTier;
  }
  return byTier;
}
