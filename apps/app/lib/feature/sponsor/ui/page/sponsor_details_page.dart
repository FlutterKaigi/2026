import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/app_network_image.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_detail_provider.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:app/feature/sponsor/ui/sponsor_tier_presentation.dart';
import 'package:app/feature/sponsor/ui/widget/sponsor_message_state_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows details for one sponsor from the sponsor wall data.
class SponsorDetailsPage extends ConsumerWidget {
  const SponsorDetailsPage({
    required this.sponsorKey,
    this.initialSponsor,
    super.key,
  });

  final String sponsorKey;
  final Sponsor? initialSponsor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);

    if (initialSponsor != null) {
      return _SponsorDetailsContent(sponsor: initialSponsor!);
    }

    final detail = ref.watch(sponsorDetailProvider(sponsorKey));

    return switch (detail) {
      AsyncData(:final value) =>
        value == null
            ? Scaffold(
                appBar: AppBar(title: Text(t.sponsors.detailTitle)),
                body: SponsorMessageStateWidget(
                  icon: Icons.search_off_outlined,
                  title: t.sponsors.notFound,
                ),
              )
            : _SponsorDetailsContent(sponsor: value),
      AsyncError() => Scaffold(
        appBar: AppBar(title: Text(t.sponsors.detailTitle)),
        body: SponsorMessageStateWidget(
          icon: Icons.error_outline,
          title: t.sponsors.error,
          actionLabel: t.common.retry,
          onActionPressed: () => ref.invalidate(sponsorListProvider),
        ),
      ),
      AsyncLoading() => Scaffold(
        appBar: AppBar(title: Text(t.sponsors.detailTitle)),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
    };
  }
}

class _SponsorDetailsContent extends StatelessWidget {
  const _SponsorDetailsContent({required this.sponsor});

  final Sponsor sponsor;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final name = sponsor.name.resolve(locale).trim();
    final effectiveName = name.isEmpty ? sponsor.id : name;
    final description = sponsor.description.resolve(locale).trim();
    final jobBoardLinks = _jobBoardLinks(t, sponsor);
    final connectLinks = _connectLinks(sponsor);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(title: Text(effectiveName)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SponsorLogoBanner(sponsor: sponsor, name: effectiveName),
                      const SizedBox(height: 32),
                      _TierBadge(tier: sponsor.tier),

                      if (jobBoardLinks.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _LinkSection(
                          title: t.sponsors.jobBoards,
                          links: jobBoardLinks,
                        ),
                      ],
                      if (connectLinks.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _LinkSection(
                          title: t.sponsors.connect,
                          links: connectLinks,
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Text(
                          description,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.65),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SponsorLogoBanner extends StatelessWidget {
  const _SponsorLogoBanner({required this.sponsor, required this.name});

  final Sponsor sponsor;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final logoUrl = sponsor.primaryLogoUrl?.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width - 32;
        final height = (width / 2.1).clamp(180.0, 320.0);
        return Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Center(
              child: logoUrl == null || logoUrl.isEmpty
                  ? _SponsorLogoNameFallback(
                      name: name,
                      width: width,
                      height: height,
                    )
                  : Semantics(
                      label: name,
                      image: true,
                      child: AppNetworkImage(
                        imageUrl: logoUrl,
                        width: width * 0.7,
                        height: height * 0.62,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => const SizedBox.square(
                          dimension: 32,
                          child: CircularProgressIndicator.adaptive(),
                        ),
                        errorBuilder: (context, error, stackTrace) => _SponsorLogoNameFallback(
                          name: name,
                          width: width,
                          height: height,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _SponsorLogoNameFallback extends StatelessWidget {
  const _SponsorLogoNameFallback({
    required this.name,
    required this.width,
    required this.height,
  });

  final String name;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final shorterSide = math.min(width, height);
    final fontSize = (shorterSide * 0.16).clamp(22.0, 40.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.12,
        vertical: height * 0.16,
      ),
      child: Text(
        name,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.18,
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final SponsorTier tier;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: tier.badgeGradientColors),
        borderRadius: BorderRadius.circular(999),
        border: tier == SponsorTier.platinum ? Border.all(color: Colors.white70) : null,
        boxShadow: tier == SponsorTier.platinum
            ? const [
                BoxShadow(
                  color: Color(0x332D2F38),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(
          t.sponsors.tierBadge(tier: tier.label),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: tier.badgeForegroundColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _LinkSection extends StatelessWidget {
  const _LinkSection({required this.title, required this.links});

  final String title;
  final List<_SponsorLinkData> links;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.34),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final link in links) _SponsorLinkTile(link: link),
          ],
        ),
      ),
    );
  }
}

class _SponsorLinkTile extends StatelessWidget {
  const _SponsorLinkTile({required this.link});

  final _SponsorLinkData link;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => unawaited(launchUrl(link.uri, mode: LaunchMode.externalApplication)),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox.square(dimension: 24, child: Center(child: link.icon)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                link.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.open_in_new,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsorLinkData {
  const _SponsorLinkData({
    required this.title,
    required this.uri,
    required this.icon,
  });

  final String title;
  final Uri uri;
  final Widget icon;
}

List<_SponsorLinkData> _jobBoardLinks(Translations t, Sponsor sponsor) {
  final links = <_SponsorLinkData>[];
  final seen = <String>{};

  void add(String? rawUrl, String title) {
    final uri = _externalUri(rawUrl);
    if (uri == null || !seen.add(uri.toString())) {
      return;
    }
    links.add(
      _SponsorLinkData(
        title: title,
        uri: uri,
        icon: const Icon(Icons.work_outline, size: 22),
      ),
    );
  }

  add(sponsor.jobBoardUrl, t.sponsors.jobBoardCta);
  add(sponsor.recruitUrl, t.sponsors.recruitCta);
  return links;
}

List<_SponsorLinkData> _connectLinks(Sponsor sponsor) {
  final links = <_SponsorLinkData>[];
  final seen = <String>{};

  void add(String? rawUrl, Widget icon) {
    final uri = _externalUri(rawUrl);
    if (uri == null || !seen.add(uri.toString())) {
      return;
    }
    links.add(_SponsorLinkData(title: uri.toString(), uri: uri, icon: icon));
  }

  add(sponsor.websiteUrl, const Icon(Icons.public, size: 22));
  add(
    sponsor.xUrl,
    const Text(
      'X',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    ),
  );
  return links;
}

Uri? _externalUri(String? rawUrl) {
  final trimmed = rawUrl?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.isEmpty) {
    return null;
  }
  if (uri.scheme != 'https' && uri.scheme != 'http') {
    return null;
  }
  return uri;
}
