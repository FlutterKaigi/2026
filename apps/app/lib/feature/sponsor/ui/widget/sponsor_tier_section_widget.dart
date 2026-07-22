import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:app/feature/sponsor/ui/widget/sponsor_logo_card_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';

/// Sponsor logos for one sponsorship tier.
class SponsorTierSectionWidget extends StatelessWidget {
  const SponsorTierSectionWidget({
    required this.group,
    super.key,
  });

  final SponsorTierGroup group;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          group.tier.label,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 24,
          children: [
            for (final sponsor in group.sponsors)
              SponsorLogoCardWidget(
                sponsor: sponsor,
                side: group.tier.logoSide,
              ),
          ],
        ),
      ],
    );
  }
}

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
}
