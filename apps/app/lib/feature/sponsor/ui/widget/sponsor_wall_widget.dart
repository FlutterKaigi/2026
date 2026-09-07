import 'dart:math' as math;

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/trademark_footer_widget.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:app/feature/sponsor/ui/widget/sponsor_tier_section_widget.dart';
import 'package:flutter/material.dart';

/// Responsive sponsor logo wall inspired by the web sponsor section.
class SponsorWallWidget extends StatelessWidget {
  const SponsorWallWidget({required this.data, super.key});

  final SponsorWallData data;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final pagePadding = _pagePadding(width);
    final availableWidth = math.max<double>(0, width - pagePadding.horizontal);
    final sectionGap = width < 640 ? 40.0 : (width < 960 ? 48.0 : 64.0);
    var semanticIndexOffset = 0;
    final tierSlivers = <Widget>[];
    final horizontalPadding = EdgeInsets.symmetric(
      horizontal: pagePadding.left,
    );
    for (final group in data.groups) {
      tierSlivers.addAll([
        SliverPadding(
          padding: horizontalPadding,
          sliver: SliverToBoxAdapter(
            child: SponsorTierHeaderWidget(tier: group.tier),
          ),
        ),
        SliverPadding(
          padding: horizontalPadding,
          sliver: SponsorTierRowsSliverWidget(
            availableWidth: availableWidth,
            group: group,
            semanticIndexOffset: semanticIndexOffset,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: sectionGap)),
      ]);
      semanticIndexOffset += group.sponsors.length;
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      semanticChildCount: semanticIndexOffset,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            pagePadding.left,
            pagePadding.top,
            pagePadding.right,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1232),
                child: Padding(
                  padding: EdgeInsets.only(bottom: sectionGap),
                  child: _SponsorHeader(label: t.sponsors.subtitle),
                ),
              ),
            ),
          ),
        ),
        ...tierSlivers,
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            pagePadding.left,
            0,
            pagePadding.right,
            pagePadding.bottom,
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1232),
                child: const TrademarkFooterWidget(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  EdgeInsets _pagePadding(double width) {
    if (width < 640) {
      return const EdgeInsets.fromLTRB(16, 32, 16, 48);
    }
    if (width < 960) {
      return const EdgeInsets.fromLTRB(24, 48, 24, 64);
    }
    return const EdgeInsets.fromLTRB(24, 64, 24, 96);
  }
}

class _SponsorHeader extends StatelessWidget {
  const _SponsorHeader({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      label,
      textAlign: TextAlign.center,
      style: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
    );
  }
}
