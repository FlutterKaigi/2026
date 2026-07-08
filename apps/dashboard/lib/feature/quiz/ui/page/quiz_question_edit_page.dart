import 'package:dashboard/core/extension/build_context_extension.dart';
import 'package:dashboard/core/ui/form_action_bar.dart';
import 'package:dashboard/core/ui/outlined_text_form_field.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_repository.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_status_label.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 問題の追加・編集フォーム。
///
/// 編集できるのは `draft` の問題のみ。`open` 以降は読み取り専用で表示する。
class QuizQuestionEditPage extends HookConsumerWidget {
  const QuizQuestionEditPage({super.key, required this.eventId, this.question});

  final String eventId;
  final QuizQuestion? question;

  bool get _isNew => question == null;

  bool get _isEditable => question == null || question!.status == QuizQuestionStatus.draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(quizEventProvider(eventId));
    final sponsors = ref.watch(quizSponsorListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              BackButton(onPressed: () => context.pop()),
              Text(
                _isNew ? '問題を追加' : (_isEditable ? '問題を編集' : '問題の詳細'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: switch ((event, sponsors)) {
            (AsyncData(value: final ev), AsyncData(value: final sponsorList)) when ev != null => _QuizQuestionForm(
              eventId: eventId,
              question: question,
              sponsorIds: ev.sponsorIds,
              sponsors: sponsorList,
              isEditable: _isEditable,
            ),
            (AsyncError(:final error), _) || (_, AsyncError(:final error)) => Center(child: Text('エラー: $error')),
            (AsyncData(value: null), _) => const Center(child: Text('イベントが見つかりません')),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

class _QuizQuestionForm extends HookConsumerWidget {
  const _QuizQuestionForm({
    required this.eventId,
    required this.question,
    required this.sponsorIds,
    required this.sponsors,
    required this.isEditable,
  });

  final String eventId;
  final QuizQuestion? question;
  final List<String> sponsorIds;
  final List<Sponsor> sponsors;
  final bool isEditable;

  bool get _isNew => question == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final titleController = useTextEditingController(text: question?.title ?? '');
    final orderController = useTextEditingController(text: question?.order.toString() ?? '');
    final durationController = useTextEditingController(text: (question?.durationSeconds ?? 180).toString());
    final explanationController = useTextEditingController(text: question?.explanation ?? '');
    final sponsorId = useState<String?>(question?.sponsorId ?? (sponsorIds.isNotEmpty ? sponsorIds.first : null));

    // 選択肢は 2〜4 件。デフォルトは 2 件の空欄。
    final optionControllers = useState<List<TextEditingController>>(
      question != null && question!.options.isNotEmpty
          ? question!.options.map((o) => TextEditingController(text: o)).toList()
          : [TextEditingController(), TextEditingController()],
    );
    final correctOptionIndex = useState<int?>(question?.correctOptionIndex);

    useEffect(() {
      return () {
        for (final c in optionControllers.value) {
          c.dispose();
        }
      };
    }, const []);

    // イベントの sponsorIds を、名前解決のためスポンサー実体に対応付ける。
    final sponsorById = {for (final s in sponsors) s.id: s};

    void addOption() {
      if (optionControllers.value.length >= 4) return;
      optionControllers.value = [...optionControllers.value, TextEditingController()];
    }

    void removeOption(int index) {
      if (optionControllers.value.length <= 2) return;
      final removed = optionControllers.value[index];
      optionControllers.value = [...optionControllers.value]..removeAt(index);
      removed.dispose();
      // 正解インデックスの整合を保つ。
      final current = correctOptionIndex.value;
      if (current != null) {
        if (current == index) {
          correctOptionIndex.value = null;
        } else if (current > index) {
          correctOptionIndex.value = current - 1;
        }
      }
    }

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;
      if (sponsorId.value == null) {
        context.showSnackBar('スポンサーを選択してください');
        return;
      }
      if (correctOptionIndex.value == null) {
        context.showSnackBar('正解の選択肢を選んでください');
        return;
      }

      final options = optionControllers.value.map((c) => c.text.trim()).toList();

      final questionToSave = QuizQuestion(
        id: question?.id ?? '',
        sponsorId: sponsorId.value!,
        order: int.parse(orderController.text.trim()),
        title: titleController.text.trim(),
        options: options,
        durationSeconds: int.parse(durationController.text.trim()),
        // 編集は draft のみのため status は draft を維持する。
        status: QuizQuestionStatus.draft,
      );
      final secret = QuizQuestionSecret(
        correctOptionIndex: correctOptionIndex.value!,
        explanation: explanationController.text.trim(),
      );

      try {
        await ref.read(quizQuestionRepositoryProvider).save(eventId, questionToSave, secret);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) context.showSnackBar('保存に失敗しました: $e');
      }
    }

    final isSaving = useState(false);

    Future<void> onSave() async {
      isSaving.value = true;
      try {
        await save();
      } finally {
        isSaving.value = false;
      }
    }

    String sponsorLabel(String id) {
      final s = sponsorById[id];
      if (s == null) return id;
      return s.name.ja.isEmpty ? s.name.en : s.name.ja;
    }

    if (!isEditable) {
      return _ReadOnlyQuestionView(question: question!, sponsorLabel: sponsorLabel);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: sponsorIds.contains(sponsorId.value) ? sponsorId.value : null,
                      decoration: const InputDecoration(labelText: 'スポンサー *', border: OutlineInputBorder()),
                      items: [
                        for (final id in sponsorIds) DropdownMenuItem(value: id, child: Text(sponsorLabel(id))),
                      ],
                      onChanged: (v) => sponsorId.value = v,
                      validator: (v) => v == null ? 'スポンサーを選択してください' : null,
                    ),
                    const SizedBox(height: 24),
                    OutlinedTextFormField(
                      controller: orderController,
                      labelText: '出題順 (order) *',
                      hintText: '例: 1',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '出題順を入力してください';
                        if (int.tryParse(v.trim()) == null) return '数値を入力してください';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: '問題文 *', border: OutlineInputBorder()),
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty) ? '問題文を入力してください' : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text('選択肢（2〜4件、正解をラジオで選択）*', style: Theme.of(context).textTheme.labelLarge),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: optionControllers.value.length >= 4 ? null : addOption,
                          icon: const Icon(Icons.add),
                          label: const Text('追加'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < optionControllers.value.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: i,
                              // ignore: deprecated_member_use
                              groupValue: correctOptionIndex.value,
                              // ignore: deprecated_member_use
                              onChanged: (v) => correctOptionIndex.value = v,
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: optionControllers.value[i],
                                decoration: InputDecoration(
                                  labelText: '選択肢 ${i + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? '選択肢を入力してください' : null,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              tooltip: '削除',
                              onPressed: optionControllers.value.length <= 2 ? null : () => removeOption(i),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: explanationController,
                      decoration: const InputDecoration(labelText: '解説', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    OutlinedTextFormField(
                      controller: durationController,
                      labelText: '制限時間（秒）*',
                      hintText: '例: 180',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return '制限時間を入力してください';
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) return '正の数値を入力してください';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        FormActionBar(onSave: onSave, isSaving: isSaving.value, isNew: _isNew),
      ],
    );
  }
}

/// draft 以外の問題の読み取り専用表示。
class _ReadOnlyQuestionView extends StatelessWidget {
  const _ReadOnlyQuestionView({required this.question, required this.sponsorLabel});

  final QuizQuestion question;
  final String Function(String id) sponsorLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                QuizQuestionStatusChip(status: question.status),
                const SizedBox(width: 8),
                Text('出題順 ${question.order} ・ ${sponsorLabel(question.sponsorId)}', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text('出題中以降の問題は編集できません（読み取り専用）', style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),
            Text('問題文', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(question.title, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text('選択肢', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            for (var i = 0; i < question.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      question.correctOptionIndex == i ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: question.correctOptionIndex == i ? Colors.green : theme.disabledColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(question.options[i]),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text('解説', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(question.explanation?.isEmpty ?? true ? '(なし)' : question.explanation!),
            const SizedBox(height: 24),
            Text('制限時間: ${question.durationSeconds} 秒', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
