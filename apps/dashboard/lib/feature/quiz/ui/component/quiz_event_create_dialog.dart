import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// クイズイベントの新規作成ダイアログ（PoC 用の最小構成）。
///
/// タイトル（日本語 / 英語）・定員・スポンサーの複数選択を受け取り、
/// `status = draft`（非公開）の新規イベントとして保存する。
/// 保存時に現地受付コードも自動生成する。
class QuizEventCreateDialog extends HookConsumerWidget {
  const QuizEventCreateDialog._();

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const QuizEventCreateDialog._(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final titleJaController = useTextEditingController();
    final titleEnController = useTextEditingController();
    final capacityController = useTextEditingController(text: '80');
    final selectedSponsorIds = useState(<String>[]);
    final isSaving = useState(false);

    final sponsors = ref.watch(quizSponsorListProvider);

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;
      isSaving.value = true;
      try {
        final now = DateTime.now();
        // 保存時はプラン順 → 表示名順に整列しておく（問題フォームの
        // ドロップダウンなど、後段の表示順がこの並びになる）。
        final sponsorList = sponsors.value ?? const <Sponsor>[];
        final orderedIds = _sortIdsByTier(selectedSponsorIds.value, sponsorList);
        // 作成時点では非公開。アプリへの表示（公開）・受付開始はコンソールで
        // 運営が明示的に行う。
        final event = QuizEvent(
          id: '',
          title: LocaleMap(ja: titleJaController.text.trim(), en: titleEnController.text.trim()),
          status: QuizEventStatus.draft,
          capacity: int.parse(capacityController.text.trim()),
          sponsorIds: orderedIds,
          createdAt: now,
          updatedAt: now,
        );
        final eventId = await ref.read(quizEventRepositoryProvider).save(event);
        // 現地受付コードを自動生成しておく（コンソールで確認・再生成できる）。
        await ref.read(quizOperationsRepositoryProvider).regenerateEntryCode(eventId);
        if (context.mounted) {
          context.pop();
          context.showSnackBar('クイズイベントを作成しました（非公開）');
        }
      } catch (e) {
        if (context.mounted) context.showSnackBar('作成に失敗しました: $e');
      } finally {
        isSaving.value = false;
      }
    }

    return AlertDialog(
      title: const Text('クイズイベント新規作成'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleJaController,
                  decoration: const InputDecoration(labelText: 'タイトル（日本語）*', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '日本語タイトルを入力してください' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleEnController,
                  decoration: const InputDecoration(labelText: 'タイトル（英語）*', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'English title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '定員（人）*',
                    helperText: '到達すると新規の参加登録を締め切る',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 1) return '1 以上の整数を入力してください';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text('出題スポンサー', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(width: 8),
                    Text(
                      '選択中 ${selectedSponsorIds.value.length} 社',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 本番はスポンサー 30 社規模になるため、プラン別に区切って
                // 探しやすくする。プラン単位の全選択 / 解除も用意する。
                sponsors.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('スポンサーの取得に失敗しました: $e'),
                  data: (sponsors) => sponsors.isEmpty
                      ? const Text('スポンサーが登録されていません')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final entry in _groupByTier(sponsors)) ...[
                              _TierHeader(
                                tier: entry.tier,
                                sponsors: entry.sponsors,
                                selectedIds: selectedSponsorIds.value,
                                onToggleAll: (selectAll) {
                                  final next = {...selectedSponsorIds.value};
                                  final ids = entry.sponsors.map((s) => s.id);
                                  if (selectAll) {
                                    next.addAll(ids);
                                  } else {
                                    next.removeAll(ids);
                                  }
                                  selectedSponsorIds.value = next.toList();
                                },
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final sponsor in entry.sponsors)
                                    FilterChip(
                                      label: Text(sponsor.name.ja.isEmpty ? sponsor.name.en : sponsor.name.ja),
                                      visualDensity: VisualDensity.compact,
                                      selected: selectedSponsorIds.value.contains(sponsor.id),
                                      onSelected: (selected) {
                                        final next = [...selectedSponsorIds.value];
                                        if (selected) {
                                          next.add(sponsor.id);
                                        } else {
                                          next.remove(sponsor.id);
                                        }
                                        selectedSponsorIds.value = next;
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving.value ? null : () => context.pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: isSaving.value ? null : save,
          child: isSaving.value
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('作成'),
        ),
      ],
    );
  }
}

/// プランごとのスポンサーのまとまり。
typedef _TierGroup = ({SponsorTier tier, List<Sponsor> sponsors});

/// スポンサーをプラン順（プラチナ → … → 個人）にグループ化する。
/// プラン内は表示名（かな優先）で整列し、スポンサーのいないプランは省く。
List<_TierGroup> _groupByTier(List<Sponsor> sponsors) {
  return [
    for (final tier in SponsorTier.values)
      if (sponsors.any((s) => s.tier == tier))
        (
          tier: tier,
          sponsors: sponsors.where((s) => s.tier == tier).toList()
            ..sort((a, b) => _sortKey(a).compareTo(_sortKey(b))),
        ),
  ];
}

String _sortKey(Sponsor sponsor) =>
    sponsor.nameKana ?? (sponsor.name.ja.isEmpty ? sponsor.name.en : sponsor.name.ja);

/// 選択済み ID をプラン順 → プラン内の表示名順に整列する。
List<String> _sortIdsByTier(List<String> ids, List<Sponsor> sponsors) {
  if (sponsors.isEmpty) return ids;
  final order = <String, int>{};
  var index = 0;
  for (final group in _groupByTier(sponsors)) {
    for (final sponsor in group.sponsors) {
      order[sponsor.id] = index++;
    }
  }
  return [...ids]..sort((a, b) => (order[a] ?? 1 << 20).compareTo(order[b] ?? 1 << 20));
}

/// プラン名の見出しと「全選択 / 解除」トグル。
class _TierHeader extends StatelessWidget {
  const _TierHeader({
    required this.tier,
    required this.sponsors,
    required this.selectedIds,
    required this.onToggleAll,
  });

  final SponsorTier tier;
  final List<Sponsor> sponsors;
  final List<String> selectedIds;
  final ValueChanged<bool> onToggleAll;

  static const _tierLabels = {
    SponsorTier.platinum: 'プラチナ',
    SponsorTier.gold: 'ゴールド',
    SponsorTier.silver: 'シルバー',
    SponsorTier.bronze: 'ブロンズ',
    SponsorTier.tool: 'ツール',
    SponsorTier.community: 'コミュニティ',
    SponsorTier.individual: '個人',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSelected = sponsors.every((s) => selectedIds.contains(s.id));
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          Text(
            '${_tierLabels[tier] ?? tier.name}（${sponsors.length} 社）',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: theme.textTheme.labelSmall,
            ),
            onPressed: () => onToggleAll(!allSelected),
            child: Text(allSelected ? '解除' : '全選択'),
          ),
        ],
      ),
    );
  }
}
