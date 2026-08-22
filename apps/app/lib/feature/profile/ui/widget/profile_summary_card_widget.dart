import 'dart:async';

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/feature/profile/data/sns_platform.dart';
import 'package:app/feature/profile/ui/widget/country_flag_widget.dart';
import 'package:app/feature/profile/ui/widget/profile_avatar_widget.dart';
import 'package:app/feature/profile/ui/widget/sns_link_icon_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';

/// Compact account card at the top of the signed-in account tab.
///
/// Shows the avatar with the display name and email, then either the saved
/// profile details (country, SNS links, bio) with an edit action, or an
/// invitation to create a profile when none is saved yet.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.title,
    required this.subtitle,
    required this.avatarUrl,
    required this.profile,
    required this.onEdit,
    required this.onCreate,
    super.key,
  });

  /// Primary line: the profile display name, or the email as a fallback.
  final String title;

  /// Secondary line; `null` hides it.
  final String? subtitle;
  final String? avatarUrl;

  /// Saved profile, or `null` to show the create prompt.
  final UserProfile? profile;
  final VoidCallback onEdit;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final savedProfile = profile;

    return Card.outlined(
      margin: EdgeInsets.zero,
      // チップや編集ボタンを個別のセマンティクスノードとして残す。
      semanticContainer: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ProfileAvatar(imageUrl: avatarUrl, radius: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle case final subtitle?)
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (savedProfile == null)
                        Text(
                          t.auth.account.signedIn,
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (savedProfile == null)
              _CreatePrompt(onCreate: onCreate)
            else
              _ProfileDetails(profile: savedProfile, onEdit: onEdit),
          ],
        ),
      ),
    );
  }
}

/// Invites a signed-in user without a profile to create one.
class _CreatePrompt extends StatelessWidget {
  const _CreatePrompt({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.profile.promptTitle,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  t.profile.promptBody,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onCreate,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(40)),
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
          label: Text(t.profile.create),
        ),
      ],
    );
  }
}

/// Country and SNS chips, a two-line bio and the edit action.
class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile, required this.onEdit});

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = Localizations.localeOf(context);
    final country = findCountry(profile.countryOrRegion);
    final bio = profile.bio?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CompactChip(
              avatar: country == null ? null : CountryFlagIcon(country: country, height: 14),
              label: country?.name.resolve(locale) ?? profile.countryOrRegion,
            ),
            for (final link in profile.snsLinks) _SnsLinkChip(link: link),
          ],
        ),
        if (bio != null && bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            bio,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: onEdit,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            // Material 3 のトーナルは secondaryContainer(赤系)になるため、
            // アカウントタブの操作はすべて primary 系で揃える。
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
          ),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(t.profile.edit),
        ),
      ],
    );
  }
}

/// Non-interactive 28px outlined chip (country).
class _CompactChip extends StatelessWidget {
  const _CompactChip({required this.label, this.avatar});

  final Widget? avatar;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: avatar,
    label: Text(label),
    labelStyle: Theme.of(context).textTheme.labelMedium,
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: const EdgeInsets.symmetric(horizontal: 4),
  );
}

class _SnsLinkChip extends StatelessWidget {
  const _SnsLinkChip({required this.link});

  final SnsLink link;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final platform = SnsPlatform.fromKey(link.type);
    final uri = Uri.tryParse(link.value);

    return ActionChip(
      avatar: SnsLinkIcon(platform: platform, size: 14),
      label: Text(platform.label ?? t.profile.snsPlatformOther),
      labelStyle: Theme.of(context).textTheme.labelMedium,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      tooltip: link.value,
      onPressed: uri == null
          ? null
          : () => unawaited(
              launchExternalUrl(context, uri: uri, failureMessage: t.links.openError),
            ),
    );
  }
}
