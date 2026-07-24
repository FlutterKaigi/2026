import 'package:data/data.dart';
import 'package:flutter/material.dart';

extension SponsorTierPresentation on SponsorTier {
  /// Brand-facing tier label kept in English, matching the website design.
  String get label => switch (this) {
    SponsorTier.platinum => 'Platinum',
    SponsorTier.gold => 'Gold',
    SponsorTier.silver => 'Silver',
    SponsorTier.bronze => 'Bronze',
    SponsorTier.tool => 'Tool',
    SponsorTier.community => 'Community',
    SponsorTier.individual => 'Individual',
  };

  /// Logo tile side length from the website sponsor wall.
  double get logoSide => switch (this) {
    SponsorTier.platinum => 256,
    SponsorTier.gold => 192,
    SponsorTier.individual => 96,
    _ => 144,
  };

  List<Color> get badgeGradientColors => switch (this) {
    SponsorTier.platinum => const [
      Color(0xFFD6DBE0),
      Color(0xFFF2F4F6),
      Color(0xFFB8BFC8),
    ],
    SponsorTier.gold => const [Color(0xFFF4B400), Color(0xFFE59400)],
    SponsorTier.silver => const [Color(0xFF9AA0A6), Color(0xFF7C8388)],
    SponsorTier.bronze => const [Color(0xFFC7864F), Color(0xFFA86B3C)],
    SponsorTier.tool => const [Color(0xFF7E57C2), Color(0xFF65558F)],
    SponsorTier.community => const [Color(0xFF1E88E5), Color(0xFF1565C0)],
    SponsorTier.individual => const [Color(0xFF7E57C2), Color(0xFF65558F)],
  };

  Color get badgeForegroundColor => switch (this) {
    SponsorTier.platinum => const Color(0xFF2B2F36),
    _ => Colors.white,
  };
}
