import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_repository.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_status_label.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 進行コンソール（当日のメイン画面）。
///
/// イベント status・参加者数・チーム編成・チーム一覧・問題の出題/締切/発表・結果確定を
/// 1 画面で操作する。各進行操作は冪等なため、失敗時は同じボタンの再実行で回復できる。
class QuizConsolePage extends HookConsumerWidget {
  const QuizConsolePage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(quizEventProvider(eventId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              BackButton(onPressed: () => context.pop()),
              Text('進行コンソール', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: event.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('エラー: $e')),
            data: (event) => event == null
                ? const Center(child: Text('イベントが見つかりません'))
                : _ConsoleBody(event: event),
          ),
        ),
      ],
    );
  }
}

class _ConsoleBody extends HookConsumerWidget {
  const _ConsoleBody({required this.event});

  final QuizEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = event.id;
    final participants = ref.watch(quizParticipantListProvider(eventId));
    final teams = ref.watch(quizTeamListProvider(eventId));
    final questions = ref.watch(quizQuestionListProvider(eventId));

    // 進行中の操作を 1 つに限定し、実行中はすべての操作ボタンを無効化する。
    final busyLabel = useState<String?>(null);
    final errorMessage = useState<String?>(null);

    Future<void> runOperation(String label, Future<void> Function() action) async {
      if (busyLabel.value != null) return;
      busyLabel.value = label;
      errorMessage.value = null;
      try {
        await action();
      } catch (e) {
        errorMessage.value = '$label に失敗しました: $e\n操作は冪等です。状態を確認して再実行してください。';
      } finally {
        busyLabel.value = null;
      }
    }

    final ops = ref.read(quizOperationsRepositoryProvider);
    final isBusy = busyLabel.value != null;

    final participantCount = participants.asData?.value.length;
    final teamList = teams.asData?.value ?? const <QuizTeam>[];
    final questionList = questions.asData?.value ?? const <QuizQuestion>[];

    // 同時に open にできる問題は 1 問だけ。
    final hasOpenQuestion = questionList.any((q) => q.status == QuizQuestionStatus.open);
    // 全問題が revealed のとき結果確定を許可（問題が 1 問以上ある前提）。
    final allRevealed =
        questionList.isNotEmpty && questionList.every((q) => q.status == QuizQuestionStatus.revealed);

    Future<void> confirmAndRun({
      required String title,
      required String message,
      required String label,
      required Future<void> Function() action,
    }) async {
      final ok = await _confirm(context, title: title, message: message);
      if (ok != true) return;
      await runOperation(label, action);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ヘッダー: status + 参加者数 + チーム編成 ---
          Row(
            children: [
              Text(
                event.title.ja.isEmpty ? '(タイトル未設定)' : event.title.ja,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: 12),
              QuizEventStatusChip(status: event.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.groups_outlined),
              const SizedBox(width: 8),
              Text(
                participantCount == null ? '参加者数: 読み込み中…' : '参加者数: $participantCount 人',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 24),
              FilledButton.icon(
                // teamBuilding 中も有効にして編成のやり直し（クラッシュ回復・誤操作の修正）を可能にする。
                onPressed: ((event.status == QuizEventStatus.registration ||
                            event.status == QuizEventStatus.teamBuilding) &&
                        !isBusy &&
                        participantCount != null)
                    ? () => confirmAndRun(
                        title: event.status == QuizEventStatus.teamBuilding ? 'チーム再編成' : 'チーム編成',
                        message: event.status == QuizEventStatus.teamBuilding
                            ? '既存のチームをすべて削除し、$participantCount 人を${_teamCountText(participantCount)}に編成し直します。よろしいですか？'
                            : '$participantCount 人を${_teamCountText(participantCount)}に編成します。よろしいですか？',
                        label: 'チーム編成',
                        action: () => ops.buildTeams(eventId),
                      )
                    : null,
                icon: const Icon(Icons.shuffle),
                label: Text(event.status == QuizEventStatus.teamBuilding ? 'チーム再編成' : 'チーム編成'),
              ),
            ],
          ),
          if (busyLabel.value != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('${busyLabel.value} を実行中…'),
              ],
            ),
          ],
          if (errorMessage.value != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: errorMessage.value!, onDismiss: () => errorMessage.value = null),
          ],
          const SizedBox(height: 32),

          // --- チーム一覧 ---
          Text('チーム一覧', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          teams.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('チームの取得に失敗しました: $e'),
            data: (teams) => teams.isEmpty
                ? const Text('まだチームが編成されていません')
                : _TeamsTable(teams: teams),
          ),
          const SizedBox(height: 32),

          // --- 問題一覧 ---
          Row(
            children: [
              Text('問題一覧', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => QuizQuestionEditRoute(eventId).push(context),
                icon: const Icon(Icons.add),
                label: const Text('問題を追加'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          questions.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('問題の取得に失敗しました: $e'),
            data: (questions) => questions.isEmpty
                ? const Text('問題がありません。「問題を追加」から登録してください')
                : Column(
                    children: [
                      for (final question in questions)
                        _QuestionRow(
                          eventId: eventId,
                          event: event,
                          question: question,
                          teamCount: teamList.length,
                          isBusy: isBusy,
                          hasOpenQuestion: hasOpenQuestion,
                          onOpen: () => confirmAndRun(
                            title: '出題',
                            message: '「${question.title}」を出題します。制限時間は ${question.durationSeconds} 秒です。',
                            label: '出題',
                            action: () => ops.openQuestion(eventId, question.id),
                          ),
                          onClose: () => confirmAndRun(
                            title: '締切',
                            message: '「${question.title}」を締め切ります。',
                            label: '締切',
                            action: () => ops.closeQuestion(eventId, question.id),
                          ),
                          onReveal: () => confirmAndRun(
                            title: question.status == QuizQuestionStatus.revealed ? '再採点' : '正解発表',
                            message: question.status == QuizQuestionStatus.revealed
                                ? '「${question.title}」を再採点します（採点は冪等のため結果が正しければ変化しません）。'
                                : '「${question.title}」を採点し、正解を発表します。',
                            label: '正解発表',
                            action: () => ops.revealQuestion(eventId, question.id),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 32),

          // --- 結果確定 ---
          Row(
            children: [
              FilledButton.icon(
                onPressed: (allRevealed && !isBusy && event.status != QuizEventStatus.finished)
                    ? () => confirmAndRun(
                        title: '結果確定',
                        message: '順位とスポンサーパーフェクトを確定し、イベントを終了します。よろしいですか？',
                        label: '結果確定',
                        action: () => ops.finalizeEvent(eventId),
                      )
                    : null,
                icon: const Icon(Icons.emoji_events_outlined),
                label: const Text('結果確定'),
              ),
              const SizedBox(width: 12),
              if (event.status == QuizEventStatus.finished)
                Text('確定済み', style: TextStyle(color: Theme.of(context).colorScheme.outline))
              else if (!allRevealed)
                Text('全問題の正解発表後に有効', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            ],
          ),
        ],
      ),
    );
  }
}

/// チーム一覧テーブル。score 降順でソート、rank を表示する。
class _TeamsTable extends StatelessWidget {
  const _TeamsTable({required this.teams});

  final List<QuizTeam> teams;

  @override
  Widget build(BuildContext context) {
    final sorted = [...teams]..sort((a, b) => b.score.compareTo(a.score));
    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('テーブル')),
            DataColumn(label: Text('チーム名')),
            DataColumn(label: Text('メンバー')),
            DataColumn(label: Text('スコア'), numeric: true),
            DataColumn(label: Text('順位'), numeric: true),
          ],
          rows: [
            for (final team in sorted)
              DataRow(
                cells: [
                  DataCell(Text('${team.tableNumber}')),
                  DataCell(Text(team.name)),
                  DataCell(Text(team.members.map((m) => m.displayName).join(', '))),
                  DataCell(Text('${team.score}')),
                  DataCell(Text(team.rank?.toString() ?? '-')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 問題 1 行分。回答数・status・操作ボタンを表示する。
class _QuestionRow extends ConsumerWidget {
  const _QuestionRow({
    required this.eventId,
    required this.event,
    required this.question,
    required this.teamCount,
    required this.isBusy,
    required this.hasOpenQuestion,
    required this.onOpen,
    required this.onClose,
    required this.onReveal,
  });

  final String eventId;
  final QuizEvent event;
  final QuizQuestion question;
  final int teamCount;
  final bool isBusy;
  final bool hasOpenQuestion;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sponsors = ref.watch(quizSponsorListProvider);
    final answers = ref.watch(
      quizAnswersByQuestionProvider((eventId: eventId, questionId: question.id)),
    );

    final sponsorName = sponsors.asData?.value
        .where((s) => s.id == question.sponsorId)
        .map((s) => s.name.ja.isEmpty ? s.name.en : s.name.ja)
        .firstOrNull;

    final answeredCount = answers.asData?.value.where((a) => a.selectedOptionIndex != null).length;

    // 出題可能条件: draft かつ teamBuilding/inProgress かつ 他に open が無い。
    final canOpen =
        question.status == QuizQuestionStatus.draft &&
        (event.status == QuizEventStatus.teamBuilding || event.status == QuizEventStatus.inProgress) &&
        !hasOpenQuestion &&
        !isBusy;
    final canClose = question.status == QuizQuestionStatus.open && !isBusy;
    // revealed でも有効にして再採点（クラッシュ回復。冪等なので安全）を可能にする。
    final canReveal =
        (question.status == QuizQuestionStatus.closed || question.status == QuizQuestionStatus.revealed) && !isBusy;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text('#${question.order}', style: Theme.of(context).textTheme.titleMedium),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    sponsorName ?? question.sponsorId,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            QuizQuestionStatusChip(status: question.status),
            const SizedBox(width: 12),
            SizedBox(
              width: 96,
              child: Text(
                '回答 ${answeredCount ?? '…'} / $teamCount',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: '編集・詳細',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => QuizQuestionEditRoute(eventId, $extra: question).push(context),
            ),
            const SizedBox(width: 4),
            OutlinedButton(onPressed: canOpen ? onOpen : null, child: const Text('出題')),
            const SizedBox(width: 4),
            OutlinedButton(onPressed: canClose ? onClose : null, child: const Text('締切')),
            const SizedBox(width: 4),
            OutlinedButton(onPressed: canReveal ? onReveal : null, child: const Text('正解発表')),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: scheme.onErrorContainer))),
          IconButton(
            icon: Icon(Icons.close, color: scheme.onErrorContainer),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

String _teamCountText(int participantCount) {
  final sizes = splitIntoTeamSizes(participantCount);
  return '${sizes.length} チーム';
}

Future<bool?> _confirm(BuildContext context, {required String title, required String message}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('実行'),
        ),
      ],
    ),
  );
}
