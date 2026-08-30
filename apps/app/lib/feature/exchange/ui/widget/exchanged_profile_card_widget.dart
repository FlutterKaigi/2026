import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/exchange/data/exchanged_profile.dart';
import 'package:app/feature/profile/ui/widget/country_flag_widget.dart';
import 'package:app/feature/profile/ui/widget/profile_avatar_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One row in the exchanged-profile list: avatar, name, country and the
/// exchange date, with a delete action.
class ExchangedProfileCardWidget extends StatelessWidget {
  const ExchangedProfileCardWidget({required this.entry, required this.onTap, required this.onDelete, super.key});

  final ExchangedProfile entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final profile = entry.profile;
    final country = profile == null ? null : findCountry(profile.countryOrRegion);
    final exchangedAt = t.exchange.list.exchangedAt(
      date: DateFormat.yMMMd(locale.toLanguageTag()).format(entry.exchange.createdAt),
    );

    return ListTile(
      leading: ProfileAvatar(imageUrl: profile?.avatarUrl, radius: 22),
      title: Text(
        profile?.displayName ?? t.exchange.list.deletedProfile,
        style: profile == null ? theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant) : null,
      ),
      subtitle: Row(
        children: [
          if (country != null) ...[
            CountryFlagIcon(country: country),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              exchangedAt,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      trailing: IconButton(
        tooltip: t.exchange.list.deleteAction,
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}
