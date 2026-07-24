import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:app/feature/sponsor/ui/sponsor_tier_presentation.dart';
import 'package:app/feature/sponsor/ui/widget/sponsor_logo_card_widget.dart';
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
