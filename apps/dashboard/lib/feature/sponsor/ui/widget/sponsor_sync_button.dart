import 'package:dashboard/core/env.dart';
import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/feature/sponsor/data/provider/sponsor_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// スポンサー全データを本番環境へワンクリックで反映するボタン。
///
/// 実行前に dry run で反映内容（作成・更新・削除の件数）を取得して確認ダイアログを
/// 表示し、承認後に Cloud Functions (`syncSponsorsToProd`) を実行する。
/// 本番フレーバーでは反映元にならないため表示しない。
class SponsorSyncButton extends HookConsumerWidget {
  const SponsorSyncButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = useState(false);

    if (Flavor.current == Flavor.prod) return const SizedBox.shrink();

    Future<void> sync() async {
      final service = ref.read(sponsorSyncServiceProvider);
      isSyncing.value = true;
      try {
        // まず dry run で反映内容を取得し、確認ダイアログを表示する。
        final plan = await service.syncToProd(dryRun: true);
        if (!context.mounted) return;
        final confirmed = await _SponsorSyncConfirmDialog.show(context, plan: plan);
        if (confirmed != true) return;

        final result = await service.syncToProd(dryRun: false);
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

class _SponsorSyncConfirmDialog extends StatelessWidget {
  const _SponsorSyncConfirmDialog({required this.plan});

  final SponsorSyncResult plan;

  static Future<bool?> show(BuildContext context, {required SponsorSyncResult plan}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _SponsorSyncConfirmDialog(plan: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('本番環境への反映'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('スポンサー全データ（全 ${plan.total} 件）を本番環境へ反映します。'),
          const SizedBox(height: 12),
          Text('・作成: ${plan.created} 件'),
          Text('・更新: ${plan.updated} 件'),
          Text(
            '・削除: ${plan.deleted} 件',
            style: plan.deleted > 0 ? TextStyle(color: theme.colorScheme.error) : null,
          ),
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
