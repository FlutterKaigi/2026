import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/extension/date_time_extension.dart';
import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/core/ui/confirm_delete_dialog.dart' show ConfirmDeleteDialog;
import 'package:dashboard/feature/timeline_event/data/provider/timeline_event_list_state.dart';
import 'package:dashboard/feature/timeline_event/data/provider/timeline_event_repository.dart';
import 'package:dashboard/feature/venue/data/provider/venue_list_state.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TimelineEventListPage extends ConsumerWidget {
  const TimelineEventListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(timelineEventListProvider);
    final venues = ref.watch(venueListProvider);

    final venueNameById = venues.whenData(
      (list) => {for (final v in list) v.id: v.name.ja},
    );

    Future<void> deleteEvent(TimelineEvent event) async {
      await ConfirmDeleteDialog.show(
        context: context,
        name: event.title.ja,
        onConfirm: () async {
          try {
            await ref.read(timelineEventRepositoryProvider).delete(event.id);
            if (context.mounted) context.showSnackBar('削除しました');
          } catch (e) {
            if (context.mounted) context.showSnackBar('削除に失敗しました: $e');
          }
        },
      );
    }

    return Stack(
      children: [
        events.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (events) => events.isEmpty
              ? const Center(child: Text('タイムラインイベントがありません'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final venueName = event.venueId != null
                        ? (venueNameById.value?[event.venueId] ?? event.venueId!)
                        : null;
                    return _TimelineEventListItem(
                      event: event,
                      venueName: venueName,
                      onEdit: () => TimelineEventEditRoute($extra: event).push(context),
                      onDelete: () => deleteEvent(event),
                    );
                  },
                ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => const TimelineEventEditRoute().push(context),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _TimelineEventListItem extends StatelessWidget {
  const _TimelineEventListItem({
    required this.event,
    required this.venueName,
    required this.onEdit,
    required this.onDelete,
  });

  final TimelineEvent event;
  final String? venueName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final timeRange = event.endsAt != null
        ? '${event.startsAt.formatDateTime()} 〜 ${event.endsAt!.formatDateTime()}'
        : event.startsAt.formatDateTime();

    return ListTile(
      title: Text(event.title.ja),
      subtitle: Text('$timeRange${venueName != null ? '  $venueName' : ''}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: '編集', onPressed: onEdit),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '削除',
            color: Colors.red,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
