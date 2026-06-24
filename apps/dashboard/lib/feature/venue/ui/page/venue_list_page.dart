import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/core/ui/confirm_delete_dialog.dart' show ConfirmDeleteDialog;
import 'package:dashboard/feature/venue/data/provider/venue_list_state.dart';
import 'package:dashboard/feature/venue/data/provider/venue_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class VenueListPage extends ConsumerWidget {
  const VenueListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(venueListProvider);

    Future<void> deleteVenue(Venue venue) async {
      await ConfirmDeleteDialog.show(
        context: context,
        name: venue.name.ja,
        onConfirm: () async {
          try {
            await ref.read(venueRepositoryProvider).delete(venue.id);
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
        venues.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (venues) => venues.isEmpty
              ? const Center(child: Text('会場がありません'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: venues.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _VenueListItem(
                    venue: venues[index],
                    onEdit: () => VenueEditRoute($extra: venues[index]).push(context),
                    onDelete: () => deleteVenue(venues[index]),
                  ),
                ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => const VenueEditRoute().push(context),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _VenueListItem extends StatelessWidget {
  const _VenueListItem({required this.venue, required this.onEdit, required this.onDelete});

  final Venue venue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(venue.name.ja),
      subtitle: Text('EN: ${venue.name.en}${venue.order != null ? '  順序: ${venue.order}' : ''}'),
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
