import 'package:dashboard/core/env.dart';
import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/sync/collection_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// [target] のデータを本番環境へワンクリックで反映するボタン。
///
/// 実行前に dry run で反映内容（作成・更新・削除の件数）を取得して確認ダイアログを
/// 表示し、承認後に Cloud Functions (`syncCollectionsToProd`) を実行する。
/// 本番フレーバーでは反映元にならないため表示しない。
class CollectionSyncButton extends HookConsumerWidget {
  const CollectionSyncButton({required this.target, super.key});

  final SyncTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = useState(false);

    if (Flavor.current == Flavor.prod) return const SizedBox.shrink();

    Future<void> sync() async {
      final service = ref.read(collectionSyncServiceProvider);
      isSyncing.value = true;
      try {
        // まず dry run で反映内容を取得し、確認ダイアログを表示する。
        final plan = await service.syncToProd(collections: target.collections, dryRun: true);
        if (!context.mounted) return;
        final confirmed = await _CollectionSyncConfirmDialog.show(context, target: target, plan: plan);
        if (confirmed != true) return;

        final result = await service.syncToProd(collections: target.collections, dryRun: false);
        if (!context.mounted) return;
        context.showSnackBar(
          '本番環境へ反映しました（作成 ${result.created} 件・更新 ${result.updated} 件・削除 ${result.deleted} 件）',
        );
      } catch (e) {
        if (context.mounted) context.showSnackBar('本番環境への反映に失敗しました: $e');
      } finally {
        isSyncing.value = false;
      }
    }

    return FilledButton.tonalIcon(
      onPressed: isSyncing.value ? null : sync,
      icon: isSyncing.value
          ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.cloud_upload_outlined),
      label: const Text('本番環境へ反映'),
    );
  }
}

class _CollectionSyncConfirmDialog extends StatelessWidget {
  const _CollectionSyncConfirmDialog({required this.target, required this.plan});

  final SyncTarget target;
  final CollectionSyncResult plan;

  static Future<bool?> show(
    BuildContext context, {
    required SyncTarget target,
    required CollectionSyncResult plan,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _CollectionSyncConfirmDialog(target: target, plan: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorStyle = TextStyle(color: theme.colorScheme.error);
    return AlertDialog(
      title: const Text('本番環境への反映'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${target.label}の全データ（全 ${plan.total} 件）を本番環境へ反映します。'),
          const SizedBox(height: 12),
          Text('・作成: ${plan.created} 件'),
          Text('・更新: ${plan.updated} 件'),
          Text('・削除: ${plan.deleted} 件', style: plan.deleted > 0 ? errorStyle : null),
          // 複数コレクションをまとめて反映する場合は内訳も示す。
          if (plan.collections.length > 1) ...[
            const SizedBox(height: 12),
            Text('内訳', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            for (final count in plan.collections)
              Text(
                '${count.label}: 作成 ${count.created} 件・更新 ${count.updated} 件・削除 ${count.deleted} 件',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: count.deleted > 0 ? theme.colorScheme.error : null,
                ),
              ),
          ],
          const SizedBox(height: 12),
          Text(
            'STG 環境と完全に一致させるため、STG に存在しない本番のデータは削除されます。この操作は元に戻せません。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => context.pop(true),
          child: const Text('反映する'),
        ),
      ],
    );
  }
}
