import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/app_network_image.dart';
import 'package:flutter/material.dart';

/// Circular profile picture with a person icon fallback.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({required this.imageUrl, this.radius = 40, super.key});

  /// Picture URL; `null` or empty shows the fallback icon.
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final url = imageUrl;
    final fallback = Icon(
      Icons.person,
      size: radius,
      color: colorScheme.onPrimaryContainer,
      semanticLabel: t.profile.avatarSemanticLabel,
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      child: url == null || url.isEmpty
          ? fallback
          : ClipOval(
              child: AppNetworkImage(
                imageUrl: url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
            ),
    );
  }
}
