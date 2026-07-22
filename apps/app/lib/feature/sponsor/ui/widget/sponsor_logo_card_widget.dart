import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Square sponsor logo tile.
class SponsorLogoCardWidget extends StatelessWidget {
  const SponsorLogoCardWidget({
    required this.sponsor,
    required this.side,
    super.key,
  });

  final Sponsor sponsor;
  final double side;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final name = sponsor.name.resolve(locale).trim();
    final effectiveName = name.isEmpty ? sponsor.id : name;
    final url = _primaryUrl(sponsor);
    final shape = sponsor.tier == SponsorTier.individual
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveSide = constraints.maxWidth.isFinite ? math.min(side, constraints.maxWidth) : side;
        return Tooltip(
          message: effectiveName,
          child: Semantics(
            label: Translations.of(context).sponsors.logoSemanticLabel(name: effectiveName),
            button: url != null,
            child: Material(
              color: Colors.white,
              elevation: 3,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              shape: shape.copyWith(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: shape,
                onTap: url == null
                    ? null
                    : () => unawaited(
                        launchUrl(url, mode: LaunchMode.externalApplication),
                      ),
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
          ),
        );
      },
    );
  }

  Uri? _primaryUrl(Sponsor sponsor) {
    return _parseUri(sponsor.websiteUrl) ??
        _parseUri(sponsor.recruitUrl) ??
        _parseUri(sponsor.jobBoardUrl) ??
        _parseUri(sponsor.xUrl);
  }

  Uri? _parseUri(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return null;
    }
    return uri;
  }
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
      return _SponsorLogoFallback(size: side);
    }

    return Semantics(
      label: name,
      image: true,
      child: CachedNetworkImage(
        imageUrl: url,
        width: logoSide,
        height: logoSide,
        fit: BoxFit.contain,
        placeholder: (context, url) => SizedBox.square(
          dimension: math.min(32, side * 0.22),
          child: const CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => _SponsorLogoFallback(size: side),
      ),
    );
  }
}

class _SponsorLogoFallback extends StatelessWidget {
  const _SponsorLogoFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.business_center_outlined,
      size: size * 0.28,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}
