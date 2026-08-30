import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/exchange/data/exchanged_profile.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository_provider.dart';
import 'package:app/feature/profile/data/sns_platform.dart';
import 'package:app/feature/profile/ui/widget/country_flag_widget.dart';
import 'package:app/feature/profile/ui/widget/profile_avatar_widget.dart';
import 'package:app/feature/profile/ui/widget/sns_link_icon_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a bottom sheet with [entry]'s profile details, SNS links and the
/// signed-in user's private note.
Future<void> showExchangedProfileDetailSheet(
  BuildContext context, {
  required String currentUid,
  required ExchangedProfile entry,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _ExchangedProfileDetailSheet(currentUid: currentUid, entry: entry),
);

class _ExchangedProfileDetailSheet extends HookConsumerWidget {
  const _ExchangedProfileDetailSheet({required this.currentUid, required this.entry});

  final String currentUid;
  final ExchangedProfile entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final profile = entry.profile;
    final noteController = useTextEditingController(text: entry.exchange.note ?? '');
    final isSavingNote = useState(false);

    Future<void> saveNote() async {
      isSavingNote.value = true;
      try {
        final note = noteController.text.trim();
        await ref
            .read(profileExchangeRepositoryProvider)
            .updateNote(
              uid: currentUid,
              otherUid: entry.otherUid,
              note: note.isEmpty ? null : note,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(t.exchange.list.noteSaved)));
        }
      } on Object {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(t.exchange.list.noteSaveFailed)));
        }
      } finally {
        if (context.mounted) {
          isSavingNote.value = false;
        }
      }
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          Center(child: ProfileAvatar(imageUrl: profile?.avatarUrl)),
          const SizedBox(height: 12),
          Text(
            profile?.displayName ?? t.exchange.list.deletedProfile,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          if (profile != null) ...[
            const SizedBox(height: 4),
            Center(
              child: Builder(
                builder: (context) {
                  final country = findCountry(profile.countryOrRegion);
                  if (country == null) {
                    return const SizedBox.shrink();
                  }
                  return CountryFlagIcon(country: country);
                },
              ),
            ),
            if (profile.bio case final bio? when bio.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(bio, style: theme.textTheme.bodyMedium),
            ],
            if (profile.snsLinks.isNotEmpty) ...[
              const SizedBox(height: 20),
              for (final link in profile.snsLinks) _SnsLinkRow(link: link),
            ],
          ],
          const SizedBox(height: 24),
          Text(t.exchange.list.noteLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 4,
            minLines: 2,
            enabled: !isSavingNote.value,
            decoration: InputDecoration(
              hintText: t.exchange.list.noteHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: isSavingNote.value ? null : saveNote,
              child: isSavingNote.value
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t.exchange.list.noteSave),
            ),
          ),
        ],
      ),
    );
  }
}

class _SnsLinkRow extends StatelessWidget {
  const _SnsLinkRow({required this.link});

  final SnsLink link;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final platform = SnsPlatform.fromKey(link.type);
    final label = platform.label ?? t.profile.snsPlatformOther;

    Future<void> open() async {
      final uri = Uri.tryParse(link.value);
      var launched = false;
      if (uri != null && uri.hasScheme) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } on Object {
          launched = false;
        }
      }
      if (!launched && context.mounted) {
        await _copy(context, message: t.exchange.list.openLinkFailed);
      }
    }

    Future<void> copy() => _copy(context, message: t.exchange.list.linkCopied);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SnsLinkIcon(platform: platform),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    Text(
                      link.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: t.exchange.list.copyLink,
                icon: const Icon(Icons.copy_outlined, size: 20),
                onPressed: copy,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, {required String message}) async {
    await Clipboard.setData(ClipboardData(text: link.value));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
