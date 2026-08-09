import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/core/ui/widget/app_network_image.dart';
import 'package:app/core/ui/widget/press_scale_effect_widget.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_detail_provider.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';

/// Square sponsor logo tile.
class SponsorLogoCardWidget extends StatelessWidget {
  const SponsorLogoCardWidget({
    required this.sponsor,
    required this.side,
    this.externalUrlLauncher,
    super.key,
  });

  final Sponsor sponsor;
  final double side;
  final ExternalUrlLauncher? externalUrlLauncher;

  @override
  Widget build(BuildContext context) {
    if (sponsor.tier == SponsorTier.individual) {
      return _IndividualSponsorCard(
        sponsor: sponsor,
        side: side,
        externalUrlLauncher: externalUrlLauncher,
      );
    }

    final locale = Localizations.localeOf(context);
    final name = sponsor.name.resolve(locale).trim();
    final effectiveName = name.isEmpty ? sponsor.id : name;
    final sponsorKey = sponsorRouteKey(sponsor);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveSide = constraints.maxWidth.isFinite ? math.min(side, constraints.maxWidth) : side;
        return Semantics(
          label: Translations.of(
            context,
          ).sponsors.logoSemanticLabel(name: effectiveName),
          button: true,
          child: PressScaleEffectWidget(
            onTap: () => SponsorDetailsRoute(sponsorKey: sponsorKey).go(context),
            child: Material(
              color: Colors.white,
              elevation: 3,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              shape: shape.copyWith(
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox.square(
                dimension: effectiveSide,
                child: Center(
                  child: _SponsorLogoImage(
                    sponsor: sponsor,
                    name: effectiveName,
                    side: effectiveSide,
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

/// Individual sponsors use their `websiteUrl` first and fall back to `xUrl`
/// for an external profile or website URL, matching the website's card
/// behavior. The URL host determines the marker shown below the avatar
/// (GitHub, X, or a generic link). Missing or invalid URLs leave the card inert
/// instead of navigating to the sponsor details page.
class _IndividualSponsorCard extends StatelessWidget {
  const _IndividualSponsorCard({
    required this.sponsor,
    required this.side,
    this.externalUrlLauncher,
  });

  final Sponsor sponsor;
  final double side;
  final ExternalUrlLauncher? externalUrlLauncher;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final name = sponsor.name.resolve(locale).trim();
    final effectiveName = name.isEmpty ? sponsor.id : name;
    final individualLink = _individualLink(sponsor);
    final t = Translations.of(context);

    void openExternalLink() {
      if (individualLink == null) {
        return;
      }
      unawaited(
        launchExternalUrl(
          context,
          uri: individualLink.uri,
          failureMessage: t.links.openError,
          launcher: externalUrlLauncher,
        ),
      );
    }

    return Semantics(
      label: switch (individualLink?.type) {
        null => t.sponsors.logoSemanticLabel(name: effectiveName),
        _IndividualLinkType.github => t.sponsors.githubCardSemanticLabel(name: effectiveName),
        _IndividualLinkType.x => t.sponsors.xCardSemanticLabel(name: effectiveName),
        _IndividualLinkType.other => t.sponsors.externalCardSemanticLabel(name: effectiveName),
      },
      button: individualLink != null,
      child: PressScaleEffectWidget(
        onTap: individualLink == null ? null : openExternalLink,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 140.0;
            final avatarSide = math.min(side, width);
            return SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IndividualAvatar(
                    sponsor: sponsor,
                    name: effectiveName,
                    side: avatarSide,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (individualLink != null) ...[
                        ExcludeSemantics(
                          child: _IndividualLinkIcon(type: individualLink.type),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            text: effectiveName,
                            children: [
                              if (individualLink != null) const TextSpan(text: ' ↗'),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _IndividualAvatar extends StatelessWidget {
  const _IndividualAvatar({
    required this.sponsor,
    required this.name,
    required this.side,
  });

  final Sponsor sponsor;
  final String name;
  final double side;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = sponsor.primaryLogoUrl?.trim();

    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: CircleBorder(
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.square(
        dimension: side,
        child: url == null || url.isEmpty
            ? _SponsorLogoFallback(name: name, size: side)
            : AppNetworkImage(
                imageUrl: url,
                width: side,
                height: side,
                fit: BoxFit.cover,
                placeholderBuilder: (context) => _SponsorLogoShimmer(
                  size: side,
                  isCircle: true,
                ),
                errorBuilder: (context, error, stackTrace) => _SponsorLogoFallback(
                  name: name,
                  size: side,
                ),
              ),
      ),
    );
  }
}

enum _IndividualLinkType { github, x, other }

class _IndividualLink {
  const _IndividualLink({required this.uri, required this.type});

  final Uri uri;
  final _IndividualLinkType type;
}

class _IndividualLinkIcon extends StatelessWidget {
  const _IndividualLinkIcon({required this.type});

  final _IndividualLinkType type;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      _IndividualLinkType.github => const Icon(Icons.code, size: 14),
      _IndividualLinkType.x => const Text(
        'X',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      _IndividualLinkType.other => const Icon(Icons.public, size: 14),
    };
  }
}

_IndividualLink? _individualLink(Sponsor sponsor) {
  for (final rawUrl in [sponsor.websiteUrl, sponsor.xUrl]) {
    final link = _parseIndividualLink(rawUrl);
    if (link != null) {
      return link;
    }
  }
  return null;
}

_IndividualLink? _parseIndividualLink(String? rawUrl) {
  final trimmedUrl = rawUrl?.trim();
  if (trimmedUrl == null || trimmedUrl.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmedUrl);
  if (uri == null || uri.host.isEmpty) {
    return null;
  }
  if (uri.scheme != 'https' && uri.scheme != 'http') {
    return null;
  }
  final host = uri.host.toLowerCase();
  final type = switch (host) {
    'github.com' || 'www.github.com' => _IndividualLinkType.github,
    'x.com' || 'www.x.com' || 'twitter.com' || 'www.twitter.com' => _IndividualLinkType.x,
    _ => _IndividualLinkType.other,
  };
  return _IndividualLink(uri: uri, type: type);
}

class _SponsorLogoImage extends StatelessWidget {
  const _SponsorLogoImage({
    required this.sponsor,
    required this.name,
    required this.side,
  });

  final Sponsor sponsor;
  final String name;
  final double side;

  @override
  Widget build(BuildContext context) {
    final url = sponsor.primaryLogoUrl?.trim();
    final isIndividual = sponsor.tier == SponsorTier.individual;
    final logoSide = side * (isIndividual ? 1 : 0.7);

    if (url == null || url.isEmpty) {
      return _SponsorLogoFallback(name: name, size: side);
    }
    return Semantics(
      label: name,
      image: true,
      child: SizedBox.square(
        dimension: side,
        child: Center(
          child: AppNetworkImage(
            imageUrl: url,
            width: logoSide,
            height: logoSide,
            fit: BoxFit.contain,
            placeholderBuilder: (context) => _SponsorLogoShimmer(size: side, isCircle: isIndividual),
            errorBuilder: (context, error, stackTrace) => _SponsorLogoFallback(name: name, size: side),
          ),
        ),
      ),
    );
  }
}

class _SponsorLogoShimmer extends StatefulWidget {
  const _SponsorLogoShimmer({required this.size, required this.isCircle});

  final double size;
  final bool isCircle;

  @override
  State<_SponsorLogoShimmer> createState() => _SponsorLogoShimmerState();
}

class _SponsorLogoShimmerState extends State<_SponsorLogoShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;
    final shape = widget.isCircle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, -0.7),
              end: Alignment(_controller.value * 2, 0.7),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: SizedBox.square(
        dimension: widget.size,
        child: DecoratedBox(
          decoration: ShapeDecoration(color: baseColor, shape: shape),
        ),
      ),
    );
  }
}

class _SponsorLogoFallback extends StatelessWidget {
  const _SponsorLogoFallback({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize = (size * 0.13).clamp(13.0, 24.0);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: Text(
          name,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
