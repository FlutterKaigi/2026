import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// クイズイベントの新規作成・編集ダイアログ。
///
/// 新規作成ではタイトル（日本語 / 英語）・定員・スポンサーの複数選択を受け取り、
/// `status = draft`（非公開）の新規イベントとして保存する。
///
/// [event] を渡すと編集になり、タイトルと出題スポンサーだけを変更する。
/// 定員は受付開始後に変えられず、その判定に要る状態をクライアントが持たないため、
/// 編集では扱わず現在の値をそのまま保存する。
class QuizEventFormDialog extends HookConsumerWidget {
  const QuizEventFormDialog._({this.event, this.lockedSponsorIds = const {}});

  /// 編集するイベント。`null` なら新規作成。
  final QuizEvent? event;

  /// 問題で使用中のため外せないスポンサー。外すと問題のスポンサーが
  /// イベントに含まれなくなり、本番への反映や問題の編集ができなくなる。
  final Set<String> lockedSponsorIds;

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    QuizEvent? event,
    Set<String> lockedSponsorIds = const {},
  }) async {
    final container = ProviderScope.containerOf(context);
    await showDialog<void>(
      context: context,
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: QuizEventFormDialog._(event: event, lockedSponsorIds: lockedSponsorIds),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = event;
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final titleJaController = useTextEditingController(text: editing?.title.ja);
    final titleEnController = useTextEditingController(text: editing?.title.en);
    final capacityController = useTextEditingController(text: '80');
    final selectedSponsorIds = useState(<String>[...?editing?.sponsorIds]);
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
        final title = LocaleMap(ja: titleJaController.text.trim(), en: titleEnController.text.trim());
        if (editing != null) {
          // ダイアログを開いた後に変わった定員などを古い値で戻さないよう、
          // 保存時点の最新のイベントに変更点だけを重ねる。
          final current = ref.read(quizEventProvider(editing.id)).value ?? editing;
          await ref
              .read(quizEventRepositoryProvider)
              .save(current.copyWith(title: title, sponsorIds: orderedIds, updatedAt: now));
          if (context.mounted) {
            context.showSnackBar('イベントを更新しました');
            context.pop();
          }
          return;
        }
        // 作成時点では非公開。アプリへの表示（公開）・受付開始はコンソールで
        // 運営が明示的に行う。
        final event = QuizEvent(
          id: '',
          title: title,
          status: QuizEventStatus.draft,
          capacity: int.parse(capacityController.text.trim()),
          sponsorIds: orderedIds,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(quizEventRepositoryProvider).save(event);
        if (context.mounted) {
          context.showSnackBar('クイズイベントを作成しました（非公開）');
          context.pop();
        }
      } catch (e) {
        if (context.mounted) context.showSnackBar('${editing == null ? '作成' : '更新'}に失敗しました: $e');
      } finally {
        if (context.mounted) isSaving.value = false;
      }
    }

    void toggleSponsor(String id, bool selected) {
      final next = [...selectedSponsorIds.value];
      if (selected) {
        next.add(id);
      } else {
        next.remove(id);
      }
      selectedSponsorIds.value = next;
    }

    Widget sponsorChip(String id, String label) {
      final selected = selectedSponsorIds.value.contains(id);
      final locked = selected && lockedSponsorIds.contains(id);
      return FilterChip(
        label: Text(label),
        visualDensity: VisualDensity.compact,
        tooltip: locked ? '問題で使用中のため外せません' : null,
        selected: selected,
        onSelected: locked ? null : (selected) => toggleSponsor(id, selected),
      );
    }

    return AlertDialog(
      title: Text(editing == null ? 'クイズイベント新規作成' : 'クイズイベント編集'),
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
                if (editing == null) ...[
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
                      if (n == null || n < 3 || n > 80) return '3〜80 の整数を入力してください';
                      return null;
                    },
                  ),
                ],
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
                if (lockedSponsorIds.isNotEmpty)
                  Text(
                    '問題で使用中のスポンサーは外せません。外す場合は先に問題のスポンサーを変更してください。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
                  data: (sponsors) {
                    // 削除済みのスポンサーが設定に残っていても、見えないまま
                    // 保存し続けないよう ID で表示して外せるようにする。
                    final knownIds = {for (final s in sponsors) s.id};
                    final missingIds = selectedSponsorIds.value.where((id) => !knownIds.contains(id)).toList();
                    if (sponsors.isEmpty && missingIds.isEmpty) return const Text('スポンサーが登録されていません');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in _groupByTier(sponsors)) ...[
                          _TierHeader(
                            tier: entry.tier,
                            sponsors: entry.sponsors,
                            selectedIds: selectedSponsorIds.value,
                            lockedIds: lockedSponsorIds,
                            onToggleAll: (selectAll) {
                              final next = {...selectedSponsorIds.value};
                              final ids = entry.sponsors.map((s) => s.id);
                              if (selectAll) {
                                next.addAll(ids);
                              } else {
                                next.removeAll(ids.where((id) => !lockedSponsorIds.contains(id)));
                              }
                              selectedSponsorIds.value = next.toList();
                            },
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final sponsor in entry.sponsors)
                                sponsorChip(sponsor.id, sponsor.name.ja.isEmpty ? sponsor.name.en : sponsor.name.ja),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (missingIds.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 6),
                            child: Text(
                              '見つからないスポンサー（${missingIds.length} 社）',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [for (final id in missingIds) sponsorChip(id, id)],
                          ),
                        ],
                      ],
                    );
                  },
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
              : Text(editing == null ? '作成' : '保存'),
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
          sponsors: sponsors.where((s) => s.tier == tier).toList()..sort((a, b) => _sortKey(a).compareTo(_sortKey(b))),
        ),
  ];
}

String _sortKey(Sponsor sponsor) => sponsor.nameKana ?? (sponsor.name.ja.isEmpty ? sponsor.name.en : sponsor.name.ja);

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
    required this.lockedIds,
    required this.onToggleAll,
  });

  final SponsorTier tier;
  final List<Sponsor> sponsors;
  final List<String> selectedIds;

  /// 「解除」でも外さないスポンサー。
  final Set<String> lockedIds;
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
    final removable = sponsors.any((s) => selectedIds.contains(s.id) && !lockedIds.contains(s.id));
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
            onPressed: allSelected && !removable ? null : () => onToggleAll(!allSelected),
            child: Text(allSelected ? '解除' : '全選択'),
          ),
        ],
      ),
    );
  }
}
