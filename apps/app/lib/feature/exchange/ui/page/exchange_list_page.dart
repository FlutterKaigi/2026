import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/provider/exchanged_profile_list_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_list_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository_provider.dart';
import 'package:app/feature/exchange/ui/widget/exchanged_profile_card_widget.dart';
import 'package:app/feature/exchange/ui/widget/exchanged_profile_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// `/account/exchange/list` — attendees the signed-in user has exchanged
/// profiles with.
class ExchangeListPage extends ConsumerWidget {
  const ExchangeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final listState = ref.watch(exchangedProfileListProvider);
    final countState = ref.watch(profileExchangeCountProvider);

    Future<void> delete(String otherUid) async {
      if (uid == null) {
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.exchange.list.deleteConfirmTitle),
          content: Text(t.exchange.list.deleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.exchange.list.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.exchange.list.deleteConfirmAction),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await ref.read(profileExchangeRepositoryProvider).delete(uid: uid, otherUid: otherUid);
      }
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.exchange.list.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: switch (listState) {
        AsyncData(:final value) when value.isEmpty => const _EmptyView(),
        AsyncData(:final value) => AppScrollbar(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: value.length + 1,
            separatorBuilder: (context, index) => index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return switch (countState) {
                  AsyncData(:final value) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      t.exchange.list.countLabel(n: value),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _ => const SizedBox.shrink(),
                };
              }
              final entry = value[index - 1];
              return ExchangedProfileCardWidget(
                entry: entry,
                onTap: () =>
                    uid == null ? null : showExchangedProfileDetailSheet(context, currentUid: uid, entry: entry),
                onDelete: () => delete(entry.otherUid),
              );
            },
          ),
        ),
        AsyncError(:final error) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(exchangedProfileListProvider),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(t.exchange.list.empty, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              t.exchange.list.emptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
