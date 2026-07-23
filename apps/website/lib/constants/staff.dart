/// Staff domain model + SNS-link metadata.
///
/// This file is hand-written and checked into git. The *data* itself lives in
/// `generated_staff.dart`, which is generated at build time from the
/// `staffMembers` Firestore collection (packages/data) — or a sample fixture —
/// by `tool/generate_staff.dart` and is **never** committed (see
/// `.gitignore`). Keep this file free of any real staff data.
library;

/// A single SNS / external link on a staff card.
///
/// [type] is the platform key entered in the admin dashboard (`x`, `github`,
/// `note`, `medium`, `qiita`, `zenn`, `bluesky`, `mixi2`, …); unknown types
/// still render with the generic link icon.
class StaffSnsLink {
  const StaffSnsLink({required this.type, required this.value});

  final String type;

  /// Link target URL.
  final String value;

  /// Human-readable platform name, used in accessible labels.
  String get label => switch (type.toLowerCase()) {
    'x' || 'twitter' => 'X',
    'github' => 'GitHub',
    'note' => 'note',
    'medium' => 'Medium',
    'qiita' => 'Qiita',
    'zenn' => 'Zenn',
    'bluesky' => 'Bluesky',
    'mixi2' => 'mixi2',
    _ => 'Web',
  };

  /// Icon asset (relative to the site base href) for this link's platform.
  /// Platforms without a dedicated icon fall back to the generic globe.
  // Filenames follow the sponsor link icons (`link_*`): neutral names that ad
  // blockers don't network-block.
  String get iconAsset => switch (type.toLowerCase()) {
    'x' || 'twitter' => 'images/icons/link_x.svg',
    'github' => 'images/icons/link_github.svg',
    'note' => 'images/icons/link_note.svg',
    'medium' => 'images/icons/medium.svg',
    _ => 'images/icons/link_globe.svg',
  };
}

/// A staff member as rendered on the site, already in display order.
///
/// [iconUrl] is passed through from the data source as-is; when empty the
/// card renders the person-icon placeholder instead.
class StaffEntry {
  const StaffEntry({
    required this.name,
    this.iconUrl = '',
    this.greeting = '',
    this.snsLinks = const [],
  });

  final String name;
  final String iconUrl;

  /// One-line message shown under the SNS links. Empty when not provided.
  final String greeting;
  final List<StaffSnsLink> snsLinks;
}
