import 'dart:async';

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/profile/ui/widget/country_flag_widget.dart';
import 'package:app/feature/profile/ui/widget/profile_avatar_widget.dart';
import 'package:app/feature/profile/ui/widget/sns_link_chip_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// One entry in the exchange list: the other attendee's profile, joined from
/// `users/{otherUid}` by [ProfileExchange.id].
class ExchangedProfileCard extends HookConsumerWidget {
  const ExchangedProfileCard({required this.exchange, super.key});

  final ProfileExchange exchange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final profileState = ref.watch(exchangedUserProfileProvider(exchange.id));
    final myUid = ref.watch(authStateChangesProvider).value?.uid;
    final isDeleting = useState(false);
    final isSavingNote = useState(false);

    void showMessage(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> handleDelete() async {
      final uid = myUid;
      if (uid == null || isDeleting.value) {
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.exchange.deleteConfirmTitle),
          content: Text(t.exchange.deleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.exchange.deleteCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.exchange.deleteConfirmAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) {
        return;
      }
      isDeleting.value = true;
      try {
        await ref.read(profileExchangeRepositoryProvider).delete(uid: uid, otherUid: exchange.id);
      } on Exception catch (error, stackTrace) {
        ref.read(talkerProvider).handle(error, stackTrace);
        if (context.mounted) {
          showMessage(t.exchange.deleteFailed);
        }
      } finally {
        if (context.mounted) {
          isDeleting.value = false;
        }
      }
    }

    Future<void> handleEditNote() async {
      final uid = myUid;
      if (uid == null || isSavingNote.value) {
        return;
      }
      final result = await showDialog<_NoteEditSaved>(
        context: context,
        builder: (_) => _NoteEditDialog(initialNote: exchange.note),
      );
      if (result == null || !context.mounted) {
        return;
      }
      isSavingNote.value = true;
      try {
        await ref
            .read(profileExchangeRepositoryProvider)
            .updateNote(uid: uid, otherUid: exchange.id, note: result.note);
      } on Exception catch (error, stackTrace) {
        ref.read(talkerProvider).handle(error, stackTrace);
        if (context.mounted) {
          showMessage(t.exchange.noteSaveFailed);
        }
      } finally {
        if (context.mounted) {
          isSavingNote.value = false;
        }
      }
    }

    return Card.outlined(
      margin: EdgeInsets.zero,
      semanticContainer: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (profileState) {
          AsyncData(value: final profile?) => _ProfileContent(
            profile: profile,
            exchange: exchange,
            isDeleting: isDeleting.value,
            isSavingNote: isSavingNote.value,
            onDelete: () => unawaited(handleDelete()),
            onEditNote: () => unawaited(handleEditNote()),
          ),
          AsyncData() => _UnavailableContent(
            message: t.exchange.profileUnavailable,
            isDeleting: isDeleting.value,
            onDelete: () => unawaited(handleDelete()),
          ),
          AsyncError() => _UnavailableContent(
            message: t.exchange.profileUnavailable,
            isDeleting: isDeleting.value,
            onDelete: () => unawaited(handleDelete()),
          ),
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
  const _ProfileContent({
    required this.profile,
    required this.exchange,
    required this.isDeleting,
    required this.isSavingNote,
    required this.onDelete,
    required this.onEditNote,
  });

  final UserProfile profile;
  final ProfileExchange exchange;
  final bool isDeleting;
  final bool isSavingNote;
  final VoidCallback onDelete;
  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final country = findCountry(profile.countryOrRegion);
    final bio = profile.bio?.trim();
    final note = exchange.note?.trim();

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
            _CardActions(
              hasNote: note != null && note.isNotEmpty,
              isDeleting: isDeleting,
              isSavingNote: isSavingNote,
              onDelete: onDelete,
              onEditNote: onEditNote,
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
              for (final link in profile.snsLinks) SnsLinkChip(link: link),
            ],
          ),
        ],
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.sticky_note_2_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Trailing delete / note-edit icon buttons, shown for both a resolvable
/// profile and [_UnavailableContent] (deleting must stay possible even once
/// the other attendee's profile can no longer be read).
///
/// Each button is disabled and swapped for a spinner while its own operation
/// is in flight, and the other button is disabled alongside it so the two
/// awaited repository calls can't race each other on the same document.
class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.hasNote,
    required this.isDeleting,
    required this.onDelete,
    this.isSavingNote = false,
    this.onEditNote,
  });

  final bool hasNote;
  final bool isDeleting;
  final bool isSavingNote;
  final VoidCallback onDelete;
  final VoidCallback? onEditNote;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isBusy = isDeleting || isSavingNote;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEditNote != null)
          if (isSavingNote)
            const _CardActionSpinner()
          else
            IconButton(
              icon: Icon(hasNote ? Icons.edit_note : Icons.note_add_outlined),
              tooltip: hasNote ? t.exchange.noteEditTooltip : t.exchange.noteAddTooltip,
              onPressed: isBusy ? null : onEditNote,
            ),
        if (isDeleting)
          const _CardActionSpinner()
        else
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: t.exchange.deleteTooltip,
            onPressed: isBusy ? null : onDelete,
          ),
      ],
    );
  }
}

/// Matches an [IconButton]'s default tap target size, so the spinner doesn't
/// shift surrounding layout when it swaps in for one.
class _CardActionSpinner extends StatelessWidget {
  const _CardActionSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 48,
    child: Center(
      child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
    ),
  );
}

/// Shown when the other attendee's profile can no longer be read (deleted
/// account, or a transient load error). Deleting must stay reachable even
/// then, so [onDelete] is still wired up; editing a note about someone whose
/// profile is gone isn't useful, so no note button is shown.
class _UnavailableContent extends StatelessWidget {
  const _UnavailableContent({required this.message, required this.isDeleting, required this.onDelete});

  final String message;
  final bool isDeleting;
  final VoidCallback onDelete;

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
      _CardActions(hasNote: false, isDeleting: isDeleting, onDelete: onDelete),
    ],
  );
}

/// Result of [_NoteEditDialog] once the user taps save; distinct from `null`
/// (dialog dismissed) so an explicit save-with-empty-text can still clear the
/// note.
class _NoteEditSaved {
  const _NoteEditSaved(this.note);

  final String? note;
}

class _NoteEditDialog extends StatefulWidget {
  const _NoteEditDialog({required this.initialNote});

  final String? initialNote;

  @override
  State<_NoteEditDialog> createState() => _NoteEditDialogState();
}

class _NoteEditDialogState extends State<_NoteEditDialog> {
  late final _controller = TextEditingController(text: widget.initialNote ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final trimmed = _controller.text.trim();
    Navigator.of(context).pop(_NoteEditSaved(trimmed.isEmpty ? null : trimmed));
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return AlertDialog(
      title: Text(t.exchange.noteEditTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: ProfileExchange.noteMaxLength,
        maxLines: 4,
        minLines: 2,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: t.exchange.noteLabel,
          hintText: t.exchange.noteEditHint,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.exchange.noteCancel),
        ),
        FilledButton(onPressed: _save, child: Text(t.exchange.noteSave)),
      ],
    );
  }
}
