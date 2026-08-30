import 'dart:async';

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/profile/data/sns_platform.dart';
import 'package:app/feature/profile/ui/widget/country_flag_widget.dart';
import 'package:app/feature/profile/ui/widget/profile_avatar_widget.dart';
import 'package:app/feature/profile/ui/widget/sns_link_icon_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// One entry in the exchange list: the other attendee's profile, joined from
/// `users/{otherUid}` by [ProfileExchange.id].
class ExchangedProfileCard extends ConsumerWidget {
  const ExchangedProfileCard({required this.exchange, super.key});

  final ProfileExchange exchange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final profileState = ref.watch(exchangedUserProfileProvider(exchange.id));

    return Card.outlined(
      margin: EdgeInsets.zero,
      semanticContainer: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (profileState) {
          AsyncData(value: final profile?) => _ProfileContent(profile: profile),
          AsyncData() => _UnavailableContent(message: t.exchange.profileUnavailable),
          AsyncError() => _UnavailableContent(message: t.exchange.profileUnavailable),
          AsyncLoading() => const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator.adaptive()),
          ),
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final country = findCountry(profile.countryOrRegion);
    final bio = profile.bio?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ProfileAvatar(imageUrl: profile.avatarUrl, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (country != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CountryFlagIcon(country: country, height: 14),
                        const SizedBox(width: 6),
                        Text(
                          country.name.resolve(locale),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        if (bio != null && bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(bio, style: theme.textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
        if (profile.snsLinks.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final link in profile.snsLinks) _SnsLinkChip(link: link),
            ],
          ),
        ],
      ],
    );
  }
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

/// Shown when the other attendee's profile can no longer be read (deleted
/// account, or a transient load error).
class _UnavailableContent extends StatelessWidget {
  const _UnavailableContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.person_off_outlined, size: 24),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    ],
  );
}
