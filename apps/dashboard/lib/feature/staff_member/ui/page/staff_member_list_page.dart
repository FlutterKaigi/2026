import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/core/ui/confirm_delete_dialog.dart' show ConfirmDeleteDialog;
import 'package:dashboard/feature/staff_member/data/provider/staff_member_list_state.dart';
import 'package:dashboard/feature/staff_member/data/provider/staff_member_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StaffMemberListPage extends ConsumerWidget {
  const StaffMemberListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffMembers = ref.watch(staffMemberListProvider);

    Future<void> deleteStaffMember(StaffMember staffMember) async {
      await ConfirmDeleteDialog.show(
        context: context,
        name: staffMember.name,
        onConfirm: () async {
          try {
            await ref.read(staffMemberRepositoryProvider).delete(staffMember.id);
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
        staffMembers.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (staffMembers) => staffMembers.isEmpty
              ? const Center(child: Text('スタッフがいません'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: staffMembers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _StaffMemberListItem(
                    staffMember: staffMembers[index],
                    onEdit: () => StaffMemberEditRoute($extra: staffMembers[index]).push(context),
                    onDelete: () => deleteStaffMember(staffMembers[index]),
                  ),
                ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => const StaffMemberEditRoute().push(context),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _StaffMemberListItem extends StatelessWidget {
  const _StaffMemberListItem({required this.staffMember, required this.onEdit, required this.onDelete});

  final StaffMember staffMember;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(staffMember.iconUrl)),
      title: Text(staffMember.name),
      subtitle: Text(
        '順序: ${staffMember.order}${staffMember.snsLinks.isNotEmpty ? '  SNS: ${staffMember.snsLinks.length}件' : ''}',
      ),
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
