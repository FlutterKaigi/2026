import 'package:dashboard/core/event_environment/event_environment.dart';
import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/feature/sponsor/data/provider/sponsor_list_state.dart';
import 'package:dashboard/feature/stamp_rally/data/provider/stamp_rally_state.dart';
import 'package:dashboard/feature/stamp_rally/ui/print/stamp_rally_print.dart';
import 'package:dashboard/feature/support_lt/ui/widget/support_lt_load_error.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Parses `7, 14, 22`: 1–5 positive integers in strictly ascending order.
/// Returns `null` for anything else.
List<int>? parseCheckpoints(String text) {
  final values = text.split(',').map((part) => int.tryParse(part.trim())).toList();
  if (values.isEmpty || values.length > 5 || values.any((value) => value == null || value <= 0)) return null;
  final checkpoints = values.cast<int>();
  for (var i = 1; i < checkpoints.length; i++) {
    if (checkpoints[i] <= checkpoints[i - 1]) return null;
  }
  return checkpoints;
}

class StampRallyPage extends StatelessWidget {
  const StampRallyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('スタンプラリー', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('このダッシュボードの接続先プロジェクトの設定を編集します。'),
        const SizedBox(height: 24),
        const _SettingsCard(),
        const SizedBox(height: 16),
        const _SponsorsCard(),
        const SizedBox(height: 16),
        const _QrCodesCard(),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.description});

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (description != null) ...[const SizedBox(height: 8), Text(description!)],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(stampRallySettingsProvider);
    return _SectionCard(
      title: '設定',
      description: '受付中のみスタンプを獲得できます。景品・サンクスカードの交換は受付状態に関係なく行えます。',
      child: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => SupportLtLoadError(
          message: supportLtErrorMessage(error, fallback: '設定を読み込めませんでした。'),
          retryKey: const Key('retry-stamp-rally-settings'),
          onRetry: () => ref.invalidate(stampRallySettingsProvider),
        ),
        // Reset the form whenever the saved values change.
        data: (value) => _SettingsForm(key: ValueKey('${value.checkpoints}/${value.isOpen}'), settings: value),
      ),
    );
  }
}

class _SettingsForm extends HookConsumerWidget {
  const _SettingsForm({super.key, required this.settings});

  final StampRallySettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(text: settings.checkpoints.join(', '));
    final error = useState<String?>(null);
    final saving = useState(false);

    Future<void> save(StampRallySettings next) async {
      saving.value = true;
      try {
        await ref.read(stampRallyRepositoryProvider).saveSettings(next);
        if (context.mounted) context.showSnackBar('保存しました');
      } catch (e) {
        if (context.mounted) context.showSnackBar('保存に失敗しました: $e');
      } finally {
        if (context.mounted) saving.value = false;
      }
    }

    void saveCheckpoints() {
      final checkpoints = parseCheckpoints(controller.text);
      error.value = checkpoints == null ? '1〜5個の正の整数を昇順にカンマ区切りで入力してください' : null;
      if (checkpoints != null) save(StampRallySettings(checkpoints: checkpoints, isOpen: settings.isOpen));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const Key('stamp-rally-is-open'),
          contentPadding: EdgeInsets.zero,
          title: Text(settings.isOpen ? 'スタンプ受付中' : 'スタンプ受付停止中'),
          value: settings.isOpen,
          onChanged: saving.value
              ? null
              : (isOpen) => save(StampRallySettings(checkpoints: settings.checkpoints, isOpen: isOpen)),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const Key('stamp-rally-checkpoints'),
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'チェックポイント（必要スタンプ数）',
                  helperText: '並び順が景品の番号（#1, #2, …）になります。例: 7, 14, 22',
                  errorText: error.value,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(onPressed: saving.value ? null : saveCheckpoints, child: const Text('保存')),
          ],
        ),
      ],
    );
  }
}

class _SponsorsCard extends ConsumerWidget {
  const _SponsorsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sponsors = ref.watch(sponsorListProvider);
    final ids = ref.watch(stampRallySponsorIdsProvider);

    Future<void> toggle(String sponsorId, bool enabled) async {
      try {
        await ref.read(stampRallyRepositoryProvider).setSponsorEnabled(sponsorId, enabled: enabled);
      } catch (e) {
        if (context.mounted) context.showSnackBar('更新に失敗しました: $e');
      }
    }

    Widget tile(String id, String name, bool enabled) => SwitchListTile(
      key: ValueKey('stamp-rally-sponsor-$id'),
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: Text(id),
      value: enabled,
      onChanged: (value) => toggle(id, value),
    );

    return _SectionCard(
      title: ids.hasValue ? '対象スポンサー ${ids.requireValue.length}社' : '対象スポンサー',
      description: 'オンにしたスポンサーのブースでスタンプを配布します。',
      child: switch ((sponsors, ids)) {
        (AsyncData(value: final sponsors), AsyncData(value: final ids)) => Column(
          children: [
            for (final sponsor in sponsors) tile(sponsor.id, sponsor.name.ja, ids.contains(sponsor.id)),
            // Targets whose sponsor was deleted stay listed so they can be removed.
            for (final id in ids.where((id) => sponsors.every((sponsor) => sponsor.id != id)))
              tile(id, '（削除済みのスポンサー）', true),
          ],
        ),
        (AsyncError(:final error), _) || (_, AsyncError(:final error)) => SupportLtLoadError(
          message: supportLtErrorMessage(error, fallback: 'スポンサーを読み込めませんでした。'),
          retryKey: const Key('retry-stamp-rally-sponsors'),
          onRetry: () {
            ref
              ..invalidate(sponsorListProvider)
              ..invalidate(stampRallySponsorIdsProvider);
          },
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _QrCodesCard extends HookConsumerWidget {
  const _QrCodesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codes = useState<AsyncValue<StampRallyQrCodes>?>(null);
    final origin = stampRallyOrigin(ref.watch(dashboardFlavorProvider));
    final sponsorNames = {
      for (final sponsor in ref.watch(sponsorListProvider).asData?.value ?? const <Sponsor>[])
        sponsor.id: sponsor.name.ja,
    };

    Future<void> fetch() async {
      codes.value = const AsyncLoading();
      try {
        final result = await ref.read(stampRallyRepositoryProvider).fetchQrCodes();
        if (context.mounted) codes.value = AsyncData(result);
      } catch (e, stackTrace) {
        if (context.mounted) codes.value = AsyncError(e, stackTrace);
      }
    }

    final labeled = switch (codes.value) {
      AsyncData(:final value) => [
        for (final sponsor in value.sponsors)
          (
            label: '${sponsorNames[sponsor.sponsorId] ?? sponsor.sponsorId}（${sponsor.sponsorId}）',
            url: '$origin/s/${sponsor.token}',
          ),
        (label: '景品交換', url: '$origin/s/${value.reward}'),
        (label: 'サンクスカード', url: '$origin/s/${value.thanksCard}'),
      ],
      _ => const <({String label, String url})>[],
    };

    return _SectionCard(
      title: 'QRコード',
      description: 'スポンサーのQRコードはブースのスタッフが持ち、掲示しないでください。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: codes.value is AsyncLoading ? null : fetch,
                icon: const Icon(Icons.qr_code),
                label: const Text('QRコードを表示'),
              ),
              FilledButton.icon(
                onPressed: labeled.isEmpty ? null : () => openHtml(stampRallyPrintHtml(labeled)),
                icon: const Icon(Icons.print),
                label: const Text('印刷'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          switch (codes.value) {
            null => const SizedBox.shrink(),
            AsyncLoading() => const Center(child: CircularProgressIndicator()),
            AsyncError(:final error) => SupportLtLoadError(
              message: supportLtErrorMessage(error, fallback: 'QRコードを取得できませんでした。'),
              retryKey: const Key('retry-stamp-rally-qr-codes'),
              onRetry: fetch,
            ),
            _ => Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final code in labeled)
                  SizedBox(
                    width: 240,
                    child: Column(
                      children: [
                        Text(code.label, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        QrImageView(data: code.url, size: 200, backgroundColor: Colors.white),
                        SelectableText(code.url, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
          },
        ],
      ),
    );
  }
}
