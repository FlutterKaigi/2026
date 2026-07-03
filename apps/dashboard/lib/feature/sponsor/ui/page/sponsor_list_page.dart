import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/core/ui/confirm_delete_dialog.dart' show ConfirmDeleteDialog;
import 'package:dashboard/feature/sponsor/data/provider/sponsor_list_state.dart';
import 'package:dashboard/feature/sponsor/data/provider/sponsor_repository.dart';
import 'package:dashboard/feature/sponsor/model/sponsor_column.dart';
import 'package:dashboard/feature/sponsor/model/sponsor_issue_filter.dart';
import 'package:dashboard/feature/sponsor/ui/widget/sponsor_sync_button.dart';
import 'package:dashboard/feature/sponsor/ui/widget/sponsor_table.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SponsorListPage extends HookConsumerWidget {
  const SponsorListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sponsorsAsync = ref.watch(sponsorListProvider);
    final issueFilters = useState(const <SponsorIssueFilter>{});
    final tierFilter = useState<SponsorTier?>(null);
    final sort = useState<SponsorSort?>(null);
    final editingCell = useState<SponsorCellRef?>(null);

    Future<void> saveSponsor(Sponsor updated) async {
      try {
        await ref.read(sponsorRepositoryProvider).save(updated);
        if (context.mounted) context.showSnackBar('保存しました');
      } catch (e) {
        if (context.mounted) context.showSnackBar('保存に失敗しました: $e');
      }
    }

    Future<void> submitText(Sponsor sponsor, SponsorColumn column, String text) async {
      editingCell.value = null;
      final updated = column.applyText(sponsor, text);
      if (updated == sponsor) return;
      await saveSponsor(updated);
    }

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

    void toggleSort(SponsorColumn column) {
      final current = sort.value;
      if (current?.column != column) {
        sort.value = (column: column, ascending: true);
      } else if (current!.ascending) {
        sort.value = (column: column, ascending: false);
      } else {
        sort.value = null; // 3 回目のクリックでデフォルト（作成日時の降順）に戻す
      }
    }

    List<Sponsor> applyViewOptions(List<Sponsor> sponsors) {
      final filtered = sponsors.where((sponsor) {
        if (tierFilter.value != null && sponsor.tier != tierFilter.value) return false;
        return issueFilters.value.every((filter) => filter.matches(sponsor));
      }).toList();
      final currentSort = sort.value;
      if (currentSort != null) {
        filtered.sort(
          (a, b) => currentSort.ascending ? currentSort.column.compare(a, b) : currentSort.column.compare(b, a),
        );
      }
      return filtered;
    }

    // 新規作成はスプレッドシート（GAS 連携）側で行うため、作成ボタンは置かない。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TierFilterDropdown(
                      value: tierFilter.value,
                      onChanged: (tier) => tierFilter.value = tier,
                    ),
                    for (final filter in SponsorIssueFilter.values)
                      FilterChip(
                        label: Text(filter.label),
                        selected: issueFilters.value.contains(filter),
                        onSelected: (selected) {
                          final next = {...issueFilters.value};
                          selected ? next.add(filter) : next.remove(filter);
                          issueFilters.value = next;
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const SponsorSyncButton(),
            ],
          ),
        ),
        sponsorsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (sponsors) {
            final visibleCount = applyViewOptions(sponsors).length;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text('$visibleCount / ${sponsors.length} 件', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '編集できるのはロゴ・slug のみ（セルをダブルクリック）。その他の項目の原本はスプレッドシートで、GAS 連携で反映されます',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: sponsorsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('エラー: $e')),
            data: (sponsors) {
              if (sponsors.isEmpty) {
                return const Center(child: Text('スポンサーがありません'));
              }
              final visibleSponsors = applyViewOptions(sponsors);
              if (visibleSponsors.isEmpty) {
                return const Center(child: Text('条件に一致するスポンサーがありません'));
              }
              // SelectionArea で閲覧時のテキスト選択（コピー）を可能にする。
              return SelectionArea(
                child: SponsorTable(
                  sponsors: visibleSponsors,
                  editingCell: editingCell.value,
                  sort: sort.value,
                  onSortRequested: toggleSort,
                  onEditStarted: (sponsor, column) => editingCell.value = (sponsorId: sponsor.id, column: column),
                  onEditCancelled: () => editingCell.value = null,
                  onTextSubmitted: submitText,
                  onEditPagePressed: (sponsor) => SponsorEditRoute($extra: sponsor).push(context),
                  onDeletePressed: deleteSponsor,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TierFilterDropdown extends StatelessWidget {
  const _TierFilterDropdown({required this.value, required this.onChanged});

  final SponsorTier? value;
  final ValueChanged<SponsorTier?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<SponsorTier?>(
          value: value,
          hint: const Text('ティア: すべて'),
          isDense: true,
          items: [
            const DropdownMenuItem<SponsorTier?>(value: null, child: Text('ティア: すべて')),
            for (final tier in SponsorTier.values) DropdownMenuItem<SponsorTier?>(value: tier, child: Text(tier.name)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
