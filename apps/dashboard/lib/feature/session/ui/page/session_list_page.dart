import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/extension/date_time_extension.dart';
import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/core/ui/confirm_delete_dialog.dart' show ConfirmDeleteDialog;
import 'package:dashboard/feature/session/data/provider/session_list_state.dart';
import 'package:dashboard/feature/session/data/provider/session_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SessionListPage extends ConsumerWidget {
  const SessionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionListProvider);

    Future<void> deleteSession(Session session) async {
      await ConfirmDeleteDialog.show(
        context: context,
        name: session.title.ja,
        onConfirm: () async {
          try {
            await ref.read(sessionRepositoryProvider).delete(session.id);
            if (context.mounted) context.showSnackBar('削除しました');
          } catch (e) {
            if (context.mounted) context.showSnackBar('削除に失敗しました: $e');
          }
        },
      );
    }

    return Stack(
      children: [
        sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (sessions) => sessions.isEmpty
              ? const Center(child: Text('セッションがありません'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return ListTile(
                      title: Text(session.title.ja),
                      subtitle: Text(
                        '${session.startsAt.formatDateTime()} 〜 ${session.endsAt.formatDateTime()}'
                        '  スピーカー ${session.speakerIds.length} 名',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: '編集',
                            onPressed: () => SessionEditRoute($extra: session).push(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: '削除',
                            color: Colors.red,
                            onPressed: () => deleteSession(session),
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
            onPressed: () => const SessionEditRoute().push(context),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
