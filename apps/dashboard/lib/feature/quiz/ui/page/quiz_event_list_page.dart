import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_event_create_dialog.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_status_label.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class QuizEventListPage extends ConsumerWidget {
  const QuizEventListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(quizEventListProvider);

    Future<void> createEvent() async {
      await QuizEventCreateDialog.show(context: context, ref: ref);
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
                    return ListTile(
                      title: Text(event.title.ja.isEmpty ? '(タイトル未設定)' : event.title.ja),
                      subtitle: Text('スポンサー ${event.sponsorIds.length} 社 ・ EN: ${event.title.en}'),
                      leading: const Icon(Icons.quiz_outlined),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QuizEventStatusChip(status: event.status),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => QuizConsoleRoute(event.id).push(context),
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
