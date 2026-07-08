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
/// タイトル（日本語 / 英語）とスポンサーの複数選択を受け取り、
/// `status = registration` の新規イベントとして保存する。
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
    final selectedSponsorIds = useState(<String>[]);
    final isSaving = useState(false);

    final sponsors = ref.watch(quizSponsorListProvider);

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;
      isSaving.value = true;
      try {
        final now = DateTime.now();
        final event = QuizEvent(
          id: '',
          title: LocaleMap(ja: titleJaController.text.trim(), en: titleEnController.text.trim()),
          status: QuizEventStatus.registration,
          sponsorIds: selectedSponsorIds.value,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(quizEventRepositoryProvider).save(event);
        if (context.mounted) {
          context.pop();
          context.showSnackBar('クイズイベントを作成しました');
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
                const SizedBox(height: 24),
                Text('出題スポンサー', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                sponsors.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('スポンサーの取得に失敗しました: $e'),
                  data: (sponsors) => sponsors.isEmpty
                      ? const Text('スポンサーが登録されていません')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final sponsor in sponsors)
                              FilterChip(
                                label: Text(sponsor.name.ja.isEmpty ? sponsor.name.en : sponsor.name.ja),
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
