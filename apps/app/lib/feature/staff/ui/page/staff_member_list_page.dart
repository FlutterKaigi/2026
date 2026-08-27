import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/settings_icon_button.dart';
import 'package:app/feature/staff/data/provider/staff_member_list_provider.dart';
import 'package:app/feature/staff/ui/widget/staff_member_grid_widget.dart';
import 'package:app/feature/staff/ui/widget/staff_message_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Displays staff profiles sourced from Firestore.
class StaffMemberListPage extends ConsumerWidget {
  const StaffMemberListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final staffMembers = ref.watch(staffMemberListProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.staffMembers.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [SettingsIconButton()],
      ),
      body: switch (staffMembers) {
        AsyncData(:final value) when value.isEmpty => StaffMessageStateWidget(
          icon: Icons.groups_outlined,
          title: t.staffMembers.empty,
        ),
        AsyncData(:final value) => StaffMemberGridWidget(staffMembers: value),
        AsyncError(:final error) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(staffMemberListProvider),
        ),
        AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
      },
    );
  }
}
