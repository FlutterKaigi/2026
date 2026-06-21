import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/core/ui/confirm_delete_dialog.dart' show ConfirmDeleteDialog;
import 'package:dashboard/feature/sponsor/data/provider/sponsor_list_state.dart';
import 'package:dashboard/feature/sponsor/data/provider/sponsor_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SponsorListPage extends ConsumerWidget {
  const SponsorListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sponsors = ref.watch(sponsorListProvider);

    Future<void> deleteSponsor(Sponsor sponsor) async {
      await ConfirmDeleteDialog.show(
        context: context,
        name: sponsor.name.ja,
        onConfirm: () async {
          try {
            await ref.read(sponsorRepositoryProvider).delete(sponsor.id);
            if (context.mounted) context.showSnackBar('削除しました');
          } catch (e) {
            if (context.mounted) context.showSnackBar('削除に失敗しました: $e');
          }
        },
      );
    }

    return Stack(
      children: [
        sponsors.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (sponsors) => sponsors.isEmpty
              ? const Center(child: Text('スポンサーがありません'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sponsors.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sponsor = sponsors[index];
                    return ListTile(
                      title: Text(sponsor.name.ja),
                      subtitle: sponsor.nameKana != null ? Text(sponsor.nameKana!) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: '編集',
                            onPressed: () => SponsorEditRoute($extra: sponsor).push(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: '削除',
                            color: Colors.red,
                            onPressed: () => deleteSponsor(sponsor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => const SponsorEditRoute().push(context),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
