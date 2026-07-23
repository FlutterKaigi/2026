import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
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
    super.key,
  });

  final Sponsor sponsor;
  final double side;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final name = sponsor.name.resolve(locale).trim();
    final effectiveName = name.isEmpty ? sponsor.id : name;
    final sponsorKey = sponsorRouteKey(sponsor);
    final shape = sponsor.tier == SponsorTier.individual
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveSide = constraints.maxWidth.isFinite ? math.min(side, constraints.maxWidth) : side;
        return Tooltip(
          message: effectiveName,
          child: Semantics(
            label: Translations.of(
              context,
            ).sponsors.logoSemanticLabel(name: effectiveName),
            button: true,
            child: PressScaleEffectWidget(
              onTap: () => SponsorDetailsRoute(
                sponsorKey: sponsorKey,
                $extra: sponsor,
              ).push<void>(context),
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
          ),
        );
      },
    );
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
