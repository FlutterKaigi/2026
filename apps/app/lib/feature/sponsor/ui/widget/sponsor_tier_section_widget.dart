import 'dart:math' as math;

import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:app/feature/sponsor/ui/sponsor_tier_presentation.dart';
import 'package:app/feature/sponsor/ui/widget/sponsor_logo_card_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';

/// Heading for one sponsorship tier.
class SponsorTierHeaderWidget extends StatelessWidget {
  const SponsorTierHeaderWidget({
    required this.tier,
    super.key,
  });

  final SponsorTier tier;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Text(
        tier.label,
        textAlign: TextAlign.center,
        style: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

/// Lazily built, centered sponsor logo rows for one sponsorship tier.
class SponsorTierRowsSliverWidget extends StatelessWidget {
  const SponsorTierRowsSliverWidget({
    required this.availableWidth,
    required this.group,
    required this.semanticIndexOffset,
    super.key,
  });

  final double availableWidth;
  final SponsorTierGroup group;
  final int semanticIndexOffset;

  @override
  Widget build(BuildContext context) {
    const spacing = 24.0;
    final contentWidth = math.min<double>(1232, availableWidth);
    final logoSide = math.min(group.tier.logoSide, contentWidth);
    final columnCount = math.max(
      1,
      ((contentWidth + spacing) / (logoSide + spacing)).floor(),
    );
    final rowCount = (group.sponsors.length / columnCount).ceil();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, rowIndex) {
          final firstSponsorIndex = rowIndex * columnCount;
          final lastSponsorIndex = math.min(
            firstSponsorIndex + columnCount,
            group.sponsors.length,
          );
          return Padding(
            padding: EdgeInsets.only(
              bottom: rowIndex == rowCount - 1 ? 0 : spacing,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var sponsorIndex = firstSponsorIndex; sponsorIndex < lastSponsorIndex; sponsorIndex++) ...[
                  IndexedSemantics(
                    index: semanticIndexOffset + sponsorIndex,
                    child: SizedBox.square(
                      dimension: logoSide,
                      child: SponsorLogoCardWidget(
                        sponsor: group.sponsors[sponsorIndex],
                        side: group.tier.logoSide,
                      ),
                    ),
                  ),
                  if (sponsorIndex != lastSponsorIndex - 1)
                    const SizedBox(
                      width: spacing,
                    ),
                ],
              ],
            ),
          );
        },
        addAutomaticKeepAlives: false,
        addSemanticIndexes: false,
        childCount: rowCount,
      ),
    );
  }
}
