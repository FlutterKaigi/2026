import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/core/event_environment/event_admin_client.dart';
import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/core/event_environment/event_environment.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_event_create_dialog.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_status_label.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class QuizEventListPage extends HookConsumerWidget {
  const QuizEventListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(quizEventListProvider);
    final client = ref.watch(eventAdminClientProvider);
    final deleting = useState(false);
    final snapshot = ref.watch(eventAdminSnapshotProvider).asData?.value;
    final pendingDeletionIds = {
      for (final event in snapshot?['events'] as List? ?? [])
        if (event['deletionPending'] == true) event['id'] as String,
    };
    final registrationStartedIds = {
      for (final event in snapshot?['events'] as List? ?? [])
        if (event['admissionSlotsReady'] == true) event['id'] as String,
    };

    Future<void> createEvent() async {
      await QuizEventCreateDialog.show(context: context, ref: ref);
    }

    Future<void> deleteEvent(QuizEvent event) async {
      if (client == null || deleting.value) return;
      deleting.value = true;
      try {
        final deleted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _DeleteQuizEventDialog(client: client, event: event),
        );
        if (deleted == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('下書きイベントを削除しました')));
        }
      } finally {
        if (context.mounted) deleting.value = false;
      }
    }

    return Stack(
      children: [
        events.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (events) => events.isEmpty
              ? const Center(child: Text('クイズイベントがありません'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final deletionPending = pendingDeletionIds.contains(event.id);
                    return ListTile(
                      title: Text(event.title.ja.isEmpty ? '(タイトル未設定)' : event.title.ja),
                      subtitle: Text(
                        deletionPending
                            ? '削除が完了していません。削除を再試行してください。'
                            : 'スポンサー ${event.sponsorIds.length} 社 ・ EN: ${event.title.en}',
                      ),
                      leading: const Icon(Icons.quiz_outlined),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QuizEventStatusChip(status: event.status),
                          const SizedBox(width: 8),
                          if (client != null &&
                              event.status == QuizEventStatus.draft &&
                              !event.isPublic &&
                              !registrationStartedIds.contains(event.id))
                            IconButton(
                              key: ValueKey('delete-quiz-event-${event.id}'),
                              tooltip: '下書きを削除',
                              onPressed: deleting.value ? null : () => deleteEvent(event),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          if (!deletionPending) const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: deletionPending
                          ? null
                          : () => pushEventRoute(context, QuizConsoleRoute(event.id).location),
                    );
                  },
                ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: createEvent,
            tooltip: 'クイズイベントを新規作成',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _DeleteQuizEventDialog extends StatefulWidget {
  const _DeleteQuizEventDialog({required this.client, required this.event});

  final EventAdminClient client;
  final QuizEvent event;

  @override
  State<_DeleteQuizEventDialog> createState() => _DeleteQuizEventDialogState();
}

class _DeleteQuizEventDialogState extends State<_DeleteQuizEventDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _delete() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.client.mutate('deleteEvent', {'eventId': widget.event.id});
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        final message = error is FirebaseFunctionsException ? error.message ?? error.code : error.toString();
        setState(() => _error = '削除できませんでした: $message\n状態を確認し、この画面から再試行できます。');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.event.title.ja.isEmpty ? '(タイトル未設定)' : widget.event.title.ja;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('下書きイベントを削除'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.client.environment.label}の「$title」を削除します。\n登録済みの問題・正解も削除され、元に戻せません。'),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('キャンセル')),
          FilledButton(
            onPressed: _busy ? null : _delete,
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(_busy ? '削除中…' : '削除する'),
          ),
        ],
      ),
    );
  }
}
