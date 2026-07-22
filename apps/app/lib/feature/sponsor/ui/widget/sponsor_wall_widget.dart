import 'package:app/core/i18n/strings.g.dart';
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
    final sectionGap = width < 640 ? 40.0 : (width < 960 ? 48.0 : 64.0);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: pagePadding,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1232),
            child: Column(
              children: [
                _SponsorHeader(
                  title: t.sponsors.title,
                  subtitle: t.sponsors.subtitle,
                ),
                SizedBox(height: sectionGap),
                for (final group in data.groups) ...[
                  SponsorTierSectionWidget(group: group),
                  if (group != data.groups.last) SizedBox(height: sectionGap),
                ],
              ],
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
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
