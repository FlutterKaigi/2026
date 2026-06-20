import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/core/ui/confirm_delete_dialog.dart' show ConfirmDeleteDialog;
import 'package:dashboard/feature/speaker/data/provider/speaker_list_state.dart';
import 'package:dashboard/feature/speaker/data/provider/speaker_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SpeakerListPage extends ConsumerWidget {
  const SpeakerListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speakers = ref.watch(speakerListProvider);

    Future<void> deleteSpeaker(Speaker speaker) async {
      await ConfirmDeleteDialog.show(
        context: context,
        name: speaker.name,
        onConfirm: () async {
          try {
            await ref.read(speakerRepositoryProvider).delete(speaker.id);
            if (context.mounted) {
              context.showSnackBar('削除しました');
            }
          } catch (e) {
            if (context.mounted) {
              context.showSnackBar('削除に失敗しました: $e');
            }
          }
        },
      );
    }

    return Stack(
      children: [
        speakers.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (speakers) => speakers.isEmpty
              ? const Center(child: Text('スピーカーがいません'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: speakers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _SpeakerListItem(
                    speaker: speakers[index],
                    onEdit: () => SpeakerEditRoute($extra: speakers[index]).push(context),
                    onDelete: () => deleteSpeaker(speakers[index]),
                  ),
                ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => const SpeakerEditRoute().push(context),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _SpeakerListItem extends StatelessWidget {
  const _SpeakerListItem({required this.speaker, required this.onEdit, required this.onDelete});

  final Speaker speaker;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: speaker.avatarUrl != null
          ? CircleAvatar(backgroundImage: NetworkImage(speaker.avatarUrl!))
          : const CircleAvatar(child: Icon(Icons.person)),
      title: Text(speaker.name),
      subtitle: speaker.xId != null ? Text('@${speaker.xId}') : null,
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
