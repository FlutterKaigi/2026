import 'package:app/feature/profile/data/sns_platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Monochrome icon for an SNS platform, tinted to the surrounding text color.
class SnsLinkIcon extends StatelessWidget {
  const SnsLinkIcon({required this.platform, this.size = 20, this.color, super.key});

  final SnsPlatform platform;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return SvgPicture.asset(
      platform.iconAsset ?? 'res/assets/icons/link_globe.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}
