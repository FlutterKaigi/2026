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
              // ライフサイクル操作: 非公開 → 公開 → 受付開始 → 受付終了 → チーム編成。
              // 各遷移は運営の明示操作で、リポジトリ側でも遷移元を検証する。
              if (event.status == QuizEventStatus.draft) ...[
                FilledButton.icon(
                  onPressed: !isBusy
                      ? () => confirmAndRun(
                          title: 'イベントを公開',
                          message: '参加者アプリのイベント一覧に「開催準備中」として表示されるようになります。よろしいですか？'
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
                          message: '参加受付を開始します。参加者のアプリに受付コード入力つきの受付画面が表示されるようになります。よろしいですか？',
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
                FilledButton.icon(
                  // 編成後も有効にして編成のやり直し（クラッシュ回復・誤操作の修正）を可能にする。
                  onPressed: (!isBusy && participantCount != null)
                      ? () => confirmAndRun(
                          title: teamList.isNotEmpty ? 'チーム再編成' : 'チーム編成',
                          message: teamList.isNotEmpty
                              ? '既存のチームをすべて削除し、$participantCount 人を${_teamCountText(participantCount)}に編成し直します。よろしいですか？'
                              : '$participantCount 人を${_teamCountText(participantCount)}に編成します。よろしいですか？',
                          label: 'チーム編成',
                          action: () => ops.buildTeams(eventId),
                        )
                      : null,
                  icon: const Icon(Icons.shuffle),
                  label: Text(teamList.isNotEmpty ? 'チーム再編成' : 'チーム編成'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _EntryCodePanel(eventId: eventId, isBusy: isBusy, onRegenerate: runOperation),
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
          Row(
            children: [
              Text('チーム一覧', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showTeamNamePoolDialog(context, ref, event),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('チーム名を管理'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          teams.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('チームの取得に失敗しました: $e'),
            data: (teams) => teams.isEmpty
                ? const Text('まだチームが編成されていません')
                : _TeamsTable(eventId: eventId, teams: teams),
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
                            message: '「${question.title.ja}」を出題します。制限時間は ${question.durationSeconds} 秒です。',
                            label: '出題',
                            action: () => ops.openQuestion(eventId, question.id),
                          ),
                          onClose: () => confirmAndRun(
                            title: '締切',
                            message: '「${question.title.ja}」を締め切ります。',
                            label: '締切',
                            action: () => ops.closeQuestion(eventId, question.id),
                          ),
                          onReveal: () => confirmAndRun(
                            title: question.status == QuizQuestionStatus.revealed ? '再採点' : '正解発表',
                            message: question.status == QuizQuestionStatus.revealed
                                ? '「${question.title.ja}」を再採点します（採点は冪等のため結果が正しければ変化しません）。'
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
/// チーム名は行の鉛筆アイコンから個別に変更できる。
class _TeamsTable extends ConsumerWidget {
  const _TeamsTable({required this.eventId, required this.teams});

  final String eventId;
  final List<QuizTeam> teams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(team.name),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'チーム名を変更',
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showRenameTeamDialog(context, ref, eventId, team),
                        ),
                      ],
                    ),
                  ),
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

    // 出題可能条件: draft かつ 受付終了後（チーム編成済み）/進行中 かつ 他に open が無い。
    final canOpen =
        question.status == QuizQuestionStatus.draft &&
        (event.status == QuizEventStatus.entryClosed || event.status == QuizEventStatus.inProgress) &&
        teamCount > 0 &&
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
                  Text(question.title.ja, maxLines: 2, overflow: TextOverflow.ellipsis),
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

/// チーム名プール（テーブル番号順に使う名前リスト）の編集ダイアログ。
///
/// 1 行 1 チーム名で編集し、イベントドキュメントの `teamNamePool` に保存する。
/// 反映は次回の「チーム編成 / チーム再編成」実行時。既存チームの名前だけを
/// 直したい場合はチーム一覧の鉛筆アイコンを使う。
Future<void> _showTeamNamePoolDialog(BuildContext context, WidgetRef ref, QuizEvent event) async {
  final controller = TextEditingController(text: event.teamNamePool.join('\n'));
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('チーム名を管理'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1 行につき 1 チーム名。テーブル番号順に割り当てられます。'),
            const SizedBox(height: 4),
            Text(
              '空のままにすると既定の Flutter Widget 名（${quizTeamWidgetNames.take(3).join(', ')}…）を使います。'
              '変更の反映は次回の「チーム編成」実行時です。',
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 10,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: quizTeamWidgetNames.take(4).join('\n'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('保存'),
        ),
      ],
    ),
  );
  if (saved != true) {
    controller.dispose();
    return;
  }

  final pool = controller.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  controller.dispose();
  try {
    await ref.read(quizEventRepositoryProvider).save(event.copyWith(teamNamePool: pool));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pool.isEmpty ? 'チーム名を既定（Widget 名）に戻しました' : 'チーム名プールを保存しました（${pool.length} 件）')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('チーム名プールの保存に失敗しました: $e')),
      );
    }
  }
}

/// 編成済みチームの名前を個別に変更するダイアログ。
Future<void> _showRenameTeamDialog(
  BuildContext context,
  WidgetRef ref,
  String eventId,
  QuizTeam team,
) async {
  final controller = TextEditingController(text: team.name);
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('チーム名を変更（テーブル ${team.tableNumber}）'),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'チーム名',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('保存'),
        ),
      ],
    ),
  );
  final name = controller.text.trim();
  controller.dispose();
  if (saved != true || name.isEmpty || name == team.name) {
    return;
  }
  try {
    await ref.read(quizTeamRepositoryProvider).updateName(eventId, team.id, name);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('チーム名を「$name」に変更しました')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('チーム名の変更に失敗しました: $e')),
      );
    }
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

/// 現地受付コードの表示パネル。
///
/// 受付スタッフが会場掲示に使う 6 桁コードを大きく表示する。
/// コードは `secret/entry` に保存され、運営のみ読める。
/// 漏洩時は再生成できる（以降は新しいコードのみ有効）。
class _EntryCodePanel extends ConsumerWidget {
  const _EntryCodePanel({
    required this.eventId,
    required this.isBusy,
    required this.onRegenerate,
  });

  final String eventId;
  final bool isBusy;
  final Future<void> Function(String label, Future<void> Function() action) onRegenerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final code = ref.watch(quizEntryCodeProvider(eventId)).value;
    final ops = ref.read(quizOperationsRepositoryProvider);

    return Card.filled(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pin_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('現地受付コード', style: theme.textTheme.labelMedium),
                Text(
                  code ?? '未生成',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: theme.colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            IconButton(
              tooltip: 'コードを再生成',
              onPressed: !isBusy
                  ? () async {
                      final ok = await _confirm(
                        context,
                        title: '受付コードを再生成',
                        message: '新しいコードを生成します。以前のコードでは登録できなくなります。よろしいですか？',
                      );
                      if (ok != true) return;
                      await onRegenerate('受付コード再生成', () async {
                        await ops.regenerateEntryCode(eventId);
                      });
                    }
                  : null,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 4),
            Text(
              '受付で参加者に案内するコード。\nアプリの参加登録で入力してもらう。',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
