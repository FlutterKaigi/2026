import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/core/event_environment/event_environment.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_repository.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_status_label.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_countdown.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_promotion_controls.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 進行コンソール（当日のメイン画面）。
///
/// イベント status・参加者数・チーム選択・チーム一覧・問題の出題/締切/発表・結果確定を
/// 1 画面で操作する。進行状態の検証・更新はサーバーで行う。
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
            data: (event) => event == null ? const Center(child: Text('イベントが見つかりません')) : _ConsoleBody(event: event),
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
        if (context.mounted) {
          errorMessage.value = '$label の完了を確認できませんでした: $e\n現在の状態を確認してください。通信エラー後は同じ画面で再試行できます。';
        }
      } finally {
        if (context.mounted) busyLabel.value = null;
      }
    }

    final ops = ref.read(quizOperationsRepositoryProvider);
    final isBusy = busyLabel.value != null;

    final participantList = participants.asData?.value;
    final participantCount = participantList?.length;
    final unselectedCount = participantList?.where((person) => person.teamId == null).length;
    final onlyUnselected = useState(false);
    final canStart =
        event.teamSelectionStatus == QuizTeamSelectionStatus.closed &&
        participantList != null &&
        participantList.isNotEmpty &&
        participantList.every((person) => quizTeamIds.contains(person.teamId));
    final teamList = teams.asData?.value ?? const <QuizTeam>[];
    final questionList = questions.asData?.value ?? const <QuizQuestion>[];

    // 同時に open にできる問題は 1 問だけ。
    final hasOpenQuestion = questionList.any(
      (q) =>
          q.status == QuizQuestionStatus.reading ||
          q.status == QuizQuestionStatus.open ||
          q.status == QuizQuestionStatus.closed,
    );
    final isPrestart = event.status != QuizEventStatus.inProgress && event.status != QuizEventStatus.finished;
    final revealedCount = questionList.where((q) => q.status == QuizQuestionStatus.revealed).length;
    final draftCount = questionList.where((q) => q.status == QuizQuestionStatus.draft).length;
    // 時間切れ時は未出題を残して終了できる。出題済みの問題はすべて正解発表が必要。
    final canFinalize = revealedCount > 0 && !hasOpenQuestion;

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
          // --- ヘッダー: status + 参加者数 + チーム選択 ---
          Row(
            children: [
              Text(
                event.title.ja.isEmpty ? '(タイトル未設定)' : event.title.ja,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: 12),
              QuizEventStatusChip(status: event.status),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => pushEventRoute(context, QuizProjectionRoute(eventId).location),
                icon: const Icon(Icons.present_to_all),
                label: const Text('投影画面'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          QuizPromotionControls(event: event, busy: isBusy),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.groups_outlined),
              const SizedBox(width: 8),
              Text(
                participantCount == null ? '参加者数: 読み込み中…' : '参加者数: $participantCount / ${event.capacity} 人',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (participantCount != null && participantCount >= event.capacity) ...[
                const SizedBox(width: 8),
                Chip(
                  label: const Text('定員到達'),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  visualDensity: VisualDensity.compact,
                ),
              ],
              const SizedBox(width: 24),
              // ライフサイクル操作: 非公開 → 公開 → 受付開始 → 受付終了 → チーム選択。
              // 各遷移は運営の明示操作で、リポジトリ側でも遷移元を検証する。
              if (event.status == QuizEventStatus.draft) ...[
                FilledButton.icon(
                  onPressed: !isBusy
                      ? () => confirmAndRun(
                          title: 'イベントを公開',
                          message:
                              '参加者アプリのイベント一覧に「開催準備中」として表示されるようになります。よろしいですか？'
                              '（参加登録はまだ始まりません）',
                          label: '公開',
                          action: () => ops.publishEvent(eventId),
                        )
                      : null,
                  icon: const Icon(Icons.public),
                  label: const Text('公開する'),
                ),
              ],
              if (event.status == QuizEventStatus.published) ...[
                FilledButton.icon(
                  onPressed: !isBusy
                      ? () => confirmAndRun(
                          title: '参加登録を開始',
                          message: '参加受付を開始します。参加者はアプリでこの回を選んで参加表明できるようになります。よろしいですか？',
                          label: '参加登録を開始',
                          action: () => ops.openRegistration(eventId),
                        )
                      : null,
                  icon: const Icon(Icons.how_to_reg_outlined),
                  label: const Text('参加登録を開始'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: !isBusy
                      ? () => confirmAndRun(
                          title: '非公開に戻す',
                          message: '参加者アプリのイベント一覧から非表示にします。よろしいですか？',
                          label: '非公開化',
                          action: () => ops.unpublishEvent(eventId),
                        )
                      : null,
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: const Text('非公開に戻す'),
                ),
              ],
              if (event.status == QuizEventStatus.registration) ...[
                FilledButton.tonalIcon(
                  onPressed: !isBusy
                      ? () => confirmAndRun(
                          title: '参加登録を終了',
                          message: '以降の新規参加登録はできなくなります（$participantCount 人で締切）。よろしいですか？',
                          label: '参加登録を終了',
                          action: () => ops.closeRegistration(eventId),
                        )
                      : null,
                  icon: const Icon(Icons.person_off_outlined),
                  label: const Text('参加登録を終了'),
                ),
              ],
              if (event.status == QuizEventStatus.entryClosed) ...[
                OutlinedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () => confirmAndRun(
                          title: '参加受付を再開',
                          message: '受付を再開します。選択済みのチームは保持され、空き枠に新しい参加者を案内できます。',
                          label: '受付再開',
                          action: () => ops.reopenRegistration(eventId),
                        ),
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('受付を再開'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (event.status == QuizEventStatus.registration || event.status == QuizEventStatus.entryClosed)
            Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'チーム選択: ${switch (event.teamSelectionStatus) {
                        QuizTeamSelectionStatus.notStarted => '未開始',
                        QuizTeamSelectionStatus.open => '受付中',
                        QuizTeamSelectionStatus.closed => '終了',
                      }}',
                    ),
                    Text(
                      '選択済み ${participantCount == null ? '…' : participantCount - unselectedCount!} 人 / 未選択 ${unselectedCount ?? '…'} 人',
                    ),
                    const Text('着席人数とチーム別の一覧を照合してください。出題前に参加受付・チーム選択を終了し、未選択者を確認してください。'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (event.teamSelectionStatus != QuizTeamSelectionStatus.open)
                          OutlinedButton(
                            onPressed: isBusy
                                ? null
                                : () => confirmAndRun(
                                    title: 'チーム選択を開始',
                                    message: event.teamSelectionStatus == QuizTeamSelectionStatus.notStarted
                                        ? 'A〜T のチーム選択を開始します。旧方式の割り当てがあれば解除し、参加者に座ったテーブルを選び直してもらいます。'
                                        : 'チーム選択を再開します。選択済みの所属は保持されます。',
                                    label: 'チーム選択開始',
                                    action: () => ops.openTeamSelection(eventId),
                                  ),
                            child: const Text('チーム選択を開始'),
                          ),
                        if (event.teamSelectionStatus == QuizTeamSelectionStatus.open)
                          OutlinedButton(
                            onPressed: isBusy
                                ? null
                                : () => confirmAndRun(
                                    title: 'チーム選択を終了',
                                    message: 'チーム選択と変更を締め切ります。初出題前なら再開できます。',
                                    label: 'チーム選択終了',
                                    action: () => ops.closeTeamSelection(eventId),
                                  ),
                            child: const Text('チーム選択を終了'),
                          ),
                        OutlinedButton(
                          onPressed:
                              isBusy ||
                                  event.status != QuizEventStatus.entryClosed ||
                                  event.teamSelectionStatus == QuizTeamSelectionStatus.notStarted ||
                                  unselectedCount == null ||
                                  unselectedCount == 0
                              ? null
                              : () => confirmAndRun(
                                  title: '未選択者を一括取消',
                                  message: '現在未選択の $unselectedCount 人を取り消して枠を空けます。実行時に選択済みになった人は対象に含めません。',
                                  label: '未選択者の取消',
                                  action: () async {
                                    final count = await ops.removeUnselectedParticipants(eventId);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('$count 人の参加を取り消しました')),
                                      );
                                    }
                                  },
                                ),
                          child: const Text('未選択者を一括取消'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
          const SizedBox(height: 24),
          if (isPrestart)
            participants.when(
              loading: () => const SizedBox.shrink(),
              error: (error, _) => Text('参加者の読み込みに失敗しました: $error'),
              data: (list) => ExpansionTile(
                title: Text('参加者の確認・取消（${list.length} 人）'),
                children: [
                  CheckboxListTile(
                    title: const Text('未選択者のみ表示'),
                    value: onlyUnselected.value,
                    onChanged: (value) => onlyUnselected.value = value ?? false,
                  ),
                  for (final participant in list.where((person) => !onlyUnselected.value || person.teamId == null))
                    ListTile(
                      title: Text(participant.displayName),
                      subtitle: Text(
                        '${participant.teamId == null ? '未選択' : 'チーム ${participant.teamId}'} / ${participant.id}',
                      ),
                      trailing: TextButton(
                        onPressed: isBusy
                            ? null
                            : () => confirmAndRun(
                                title: '参加登録を取消',
                                message: '「${participant.displayName}」の登録を取り消します。他の参加者の所属は保持されます。',
                                label: '参加取消',
                                action: () => ops.removeParticipant(eventId, participant.id),
                              ),
                        child: const Text('取消'),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // --- チーム一覧 ---
          Text('チーム一覧', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          teams.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('チームの取得に失敗しました: $e'),
            data: (list) => _TeamsTable(
              teams:
                  isPrestart &&
                      event.teamSelectionStatus != QuizTeamSelectionStatus.notStarted &&
                      participantList != null
                  ? quizTeamsFromParticipants(participantList, includeEmpty: true)
                  : list,
            ),
          ),
          const SizedBox(height: 32),

          // --- 問題一覧 ---
          Row(
            children: [
              Text('問題一覧', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: isPrestart ? () => pushEventRoute(context, QuizQuestionEditRoute(eventId).location) : null,
                icon: const Icon(Icons.add),
                label: const Text('問題を追加'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (questionList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${questionList.length} 問・回答時間合計 ${(questionList.fold<int>(0, (total, q) => total + q.durationSeconds) / 60).ceil()} 分。'
                '読み上げ各 1 分なら約 ${(questionList.fold<int>(0, (total, q) => total + q.durationSeconds + 60) / 60).ceil()} 分 ＋ 正解発表・移動時間を確保してください。',
              ),
            ),
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
                          canStart: canStart,
                          isBusy: isBusy,
                          hasOpenQuestion: hasOpenQuestion,
                          onPresent: () => confirmAndRun(
                            title: '問題を表示',
                            message: '「${question.title.ja}」を表示して読み上げを始めます。回答タイマーはまだ開始しません。',
                            label: '問題表示',
                            action: () => ops.presentQuestion(eventId, question.id),
                          ),
                          onOpen: () => confirmAndRun(
                            title: '回答受付を開始',
                            message: '読み上げ後、回答受付を開始します。制限時間は ${question.durationSeconds} 秒です。',
                            label: '回答受付開始',
                            action: () => ops.openQuestion(eventId, question.id),
                          ),
                          onExtend: () => confirmAndRun(
                            title: '回答時間を 30 秒延長',
                            message: '期限を 30 秒延長します。締切済みなら現在時刻から 30 秒間、回答を再び受け付けます。',
                            label: '回答時間延長',
                            action: () => ops.extendQuestion(eventId, question.id, seconds: 30),
                          ),
                          onClose: () => confirmAndRun(
                            title: '締切',
                            message: '「${question.title.ja}」を締め切ります。',
                            label: '締切',
                            action: () => ops.closeQuestion(eventId, question.id),
                          ),
                          onReveal: () => confirmAndRun(
                            title: question.status == QuizQuestionStatus.revealed ? '発表済みの結果を確認' : '正解発表',
                            message: question.status == QuizQuestionStatus.revealed
                                ? '「${question.title.ja}」は発表済みです。再実行しても採点結果は変更されません。'
                                : '「${question.title.ja}」を採点し、正解を発表します。',
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
                onPressed: (canFinalize && !isBusy && event.status == QuizEventStatus.inProgress)
                    ? () => confirmAndRun(
                        title: '結果確定',
                        message: draftCount > 0
                            ? '未出題の問題が $draftCount 問残っています。未出題を採点・スポンサーパーフェクトの判定から除外し、発表済み $revealedCount 問だけで結果を確定して終了します。よろしいですか？'
                            : '発表済み $revealedCount 問で順位とスポンサーパーフェクトを確定し、イベントを終了します。よろしいですか？',
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
              else if (!canFinalize)
                Text('1 問以上を発表し、出題済みの全問題を正解発表すると有効', style: TextStyle(color: Theme.of(context).colorScheme.outline))
              else if (draftCount > 0)
                Text('未出題 $draftCount 問を除外して終了できます', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamsTable extends StatelessWidget {
  const _TeamsTable({required this.teams});
  final List<QuizTeam> teams;

  @override
  Widget build(BuildContext context) {
    final sorted = [...teams]
      ..sort((a, b) {
        final score = b.score.compareTo(a.score);
        return score == 0 ? a.tableNumber.compareTo(b.tableNumber) : score;
      });
    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('チーム')),
            DataColumn(label: Text('人数'), numeric: true),
            DataColumn(label: Text('メンバー')),
            DataColumn(label: Text('スコア'), numeric: true),
            DataColumn(label: Text('順位'), numeric: true),
          ],
          rows: [
            for (final team in sorted)
              DataRow(
                cells: [
                  DataCell(Text(team.name)),
                  DataCell(Text('${team.memberUids.length}')),
                  DataCell(Text(team.members.map((member) => member.displayName).join(', '))),
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
    required this.canStart,
    required this.isBusy,
    required this.hasOpenQuestion,
    required this.onPresent,
    required this.onOpen,
    required this.onExtend,
    required this.onClose,
    required this.onReveal,
  });

  final String eventId;
  final QuizEvent event;
  final QuizQuestion question;
  final int teamCount;
  final bool canStart;
  final bool isBusy;
  final bool hasOpenQuestion;
  final VoidCallback onPresent;
  final VoidCallback onOpen;
  final VoidCallback onExtend;
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

    // 出題可能条件: draft かつ 受付終了後（チーム選択済み）/進行中 かつ 他に open が無い。
    final canPresent =
        question.status == QuizQuestionStatus.draft &&
        ((event.status == QuizEventStatus.entryClosed && canStart) || event.status == QuizEventStatus.inProgress) &&
        teamCount > 0 &&
        !hasOpenQuestion &&
        !isBusy;
    final canOpen = question.status == QuizQuestionStatus.reading && !isBusy;
    final canClose = question.status == QuizQuestionStatus.open && !isBusy;
    // 発表済みの場合はサーバーで完了を確認する。採点は繰り返さない。
    final canReveal =
        (question.status == QuizQuestionStatus.closed || question.status == QuizQuestionStatus.revealed) && !isBusy;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(width: 48, child: Text('#${question.order}', style: Theme.of(context).textTheme.titleMedium)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(question.title.ja, maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text(sponsorName ?? question.sponsorId, style: Theme.of(context).textTheme.bodySmall),
                      if (question.status == QuizQuestionStatus.open && question.closesAt != null)
                        QuizCountdown(closesAt: question.closesAt!),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                QuizQuestionStatusChip(status: question.status),
                const SizedBox(width: 12),
                Text('回答 ${answeredCount ?? '…'} / $teamCount'),
                IconButton(
                  tooltip: '編集・詳細',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      pushEventRoute(context, QuizQuestionEditRoute(eventId, questionId: question.id).location),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton(onPressed: canPresent ? onPresent : null, child: const Text('問題表示')),
                OutlinedButton(onPressed: canOpen ? onOpen : null, child: const Text('回答開始')),
                OutlinedButton(
                  onPressed:
                      !isBusy &&
                          (question.status == QuizQuestionStatus.open || question.status == QuizQuestionStatus.closed)
                      ? onExtend
                      : null,
                  child: const Text('+30 秒'),
                ),
                OutlinedButton(onPressed: canClose ? onClose : null, child: const Text('締切')),
                OutlinedButton(onPressed: canReveal ? onReveal : null, child: const Text('正解発表')),
              ],
            ),
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
          Expanded(
            child: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
          ),
          IconButton(
            icon: Icon(Icons.close, color: scheme.onErrorContainer),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
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
