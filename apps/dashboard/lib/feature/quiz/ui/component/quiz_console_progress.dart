import 'package:data/data.dart';
import 'package:flutter/material.dart';

/// 進行コンソールの段階。運営はこの順に進める。
enum QuizConsoleStep {
  prepare('準備・公開'),
  registration('参加受付'),
  checkIn('チェックイン'),
  questions('出題'),
  result('結果確定');

  const QuizConsoleStep(this.label);

  final String label;
}

/// 次に押すボタン。コンソールはこのボタンだけを強調する。
enum QuizConsoleAction {
  publish,
  openRegistration,
  closeRegistration,
  openCheckIn,
  closeCheckIn,
  presentQuestion,
  openQuestion,
  closeQuestion,
  revealQuestion,
  finalize,
}

/// 現在の段階と次の操作。
class QuizConsoleGuide {
  const QuizConsoleGuide({required this.step, required this.message, this.action, this.questionId});

  final QuizConsoleStep step;

  /// 次に押すボタン。条件が揃っておらず押すボタンがない場合は `null`。
  final QuizConsoleAction? action;

  /// 問題ごとの操作の対象。
  final String? questionId;
  final String message;

  /// 結果確定後はすべての段階が完了している。
  bool isDone(QuizConsoleStep other) => (step == QuizConsoleStep.result && action == null) || other.index < step.index;

  /// [action] が次の操作か。問題ごとの操作は [questionId] も一致する場合に限る。
  bool isNext(QuizConsoleAction action, {String? questionId}) =>
      this.action == action && (questionId == null || this.questionId == questionId);
}

/// コンソールのボタンの有効条件と同じ値から、現在の段階と次の操作を決める。
QuizConsoleGuide quizConsoleGuide({
  required QuizEvent event,
  required List<QuizParticipant>? participants,
  required List<QuizQuestion> questions,
  required bool canStart,
}) {
  final ordered = [...questions]..sort((a, b) => a.order.compareTo(b.order));
  final active = ordered
      .where(
        (q) =>
            q.status == QuizQuestionStatus.reading ||
            q.status == QuizQuestionStatus.open ||
            q.status == QuizQuestionStatus.closed,
      )
      .firstOrNull;
  final nextDraft = ordered.where((q) => q.status == QuizQuestionStatus.draft).firstOrNull;
  final unselected = participants?.where((person) => person.teamId == null).length;

  QuizConsoleGuide present(QuizQuestion question, {required String prefix}) => QuizConsoleGuide(
    step: QuizConsoleStep.questions,
    action: QuizConsoleAction.presentQuestion,
    questionId: question.id,
    message: '$prefix問題 #${question.order} の「問題表示」を押し、問題を読み上げます。',
  );

  switch (event.status) {
    case QuizEventStatus.draft:
      return QuizConsoleGuide(
        step: QuizConsoleStep.prepare,
        action: questions.isEmpty ? null : QuizConsoleAction.publish,
        message: questions.isEmpty ? '「問題を追加」で問題を登録してから「公開する」を押します。' : '問題と設定を確認して「公開する」を押します。参加者アプリに「開催準備中」として表示されます。',
      );
    case QuizEventStatus.published:
      return const QuizConsoleGuide(
        step: QuizConsoleStep.registration,
        action: QuizConsoleAction.openRegistration,
        message: '受付を始める時間になったら「参加登録を開始」を押します。',
      );
    case QuizEventStatus.registration:
      return const QuizConsoleGuide(
        step: QuizConsoleStep.registration,
        action: QuizConsoleAction.closeRegistration,
        message: '参加者が集まったら「参加登録を終了」を押します。終了するとチェックインを始められます。',
      );
    case QuizEventStatus.entryClosed:
      switch (event.teamSelectionStatus) {
        case QuizTeamSelectionStatus.notStarted:
          return const QuizConsoleGuide(
            step: QuizConsoleStep.checkIn,
            action: QuizConsoleAction.openCheckIn,
            message: '「チェックインを開始」を押し、会場で QR コードと参加コードを案内します。参加者は着席したテーブルのチームを選びます。',
          );
        case QuizTeamSelectionStatus.open:
          return QuizConsoleGuide(
            step: QuizConsoleStep.checkIn,
            action: QuizConsoleAction.closeCheckIn,
            message:
                '全員がチームを選んだら「チェックインを終了」を押します。'
                '${unselected == null || unselected == 0 ? '' : '（未選択 $unselected 人）'}',
          );
        case QuizTeamSelectionStatus.closed:
          if (!canStart) {
            return QuizConsoleGuide(
              step: QuizConsoleStep.checkIn,
              message: participants != null && participants.isEmpty
                  ? '参加者がいないため出題できません。「受付を再開」で参加者を募ってください。'
                  : 'チームを選んでいない参加者がいます。「チェックインを開始」で再開するか、「未選択者を一括取消」で取り消してください。',
            );
          }
          if (nextDraft == null) {
            return const QuizConsoleGuide(
              step: QuizConsoleStep.questions,
              message: '問題がありません。「問題を追加」で登録してください。',
            );
          }
          return present(nextDraft, prefix: '');
      }
    case QuizEventStatus.inProgress:
      if (active != null) {
        final number = '問題 #${active.order}';
        return switch (active.status) {
          QuizQuestionStatus.reading => QuizConsoleGuide(
            step: QuizConsoleStep.questions,
            action: QuizConsoleAction.openQuestion,
            questionId: active.id,
            message: '$number を読み上げ終えたら「回答開始」を押します。制限時間のカウントが始まります。',
          ),
          QuizQuestionStatus.open => QuizConsoleGuide(
            step: QuizConsoleStep.questions,
            action: QuizConsoleAction.closeQuestion,
            questionId: active.id,
            message: '$number の回答を受付中です。制限時間が過ぎたら「締切」を押します（自動では締め切りません）。',
          ),
          _ => QuizConsoleGuide(
            step: QuizConsoleStep.questions,
            action: QuizConsoleAction.revealQuestion,
            questionId: active.id,
            message: '$number を締め切りました。「正解発表」を押して採点します。',
          ),
        };
      }
      if (nextDraft != null) {
        return present(nextDraft, prefix: '次は');
      }
      return const QuizConsoleGuide(
        step: QuizConsoleStep.result,
        action: QuizConsoleAction.finalize,
        message: 'すべての問題を発表しました。「結果確定」を押して順位とスポンサー賞を確定します。',
      );
    case QuizEventStatus.finished:
      return const QuizConsoleGuide(step: QuizConsoleStep.result, message: '結果を確定しました。');
  }
}

/// 進行の段階と次の操作の案内。
class QuizConsoleProgress extends StatelessWidget {
  const QuizConsoleProgress({super.key, required this.guide});

  final QuizConsoleGuide guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 8,
              children: [
                for (final step in QuizConsoleStep.values) ...[
                  if (step.index > 0) Icon(Icons.chevron_right, size: 18, color: scheme.outline),
                  _StepLabel(
                    number: step.index + 1,
                    label: step.label,
                    done: guide.isDone(step),
                    current: step == guide.step && !guide.isDone(step),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  guide.action == null ? Icons.info_outline : Icons.arrow_forward,
                  size: 20,
                  color: guide.action == null ? scheme.onSurfaceVariant : scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: guide.isDone(QuizConsoleStep.result) ? '' : '次の操作: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: guide.message),
                      ],
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.number, required this.label, required this.done, required this.current});

  final int number;
  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = current ? scheme.primary : (done ? scheme.onSurface : scheme.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: current ? scheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: done ? scheme.primary : color,
          ),
          const SizedBox(width: 4),
          Text(
            '$number. $label',
            style: theme.textTheme.labelLarge?.copyWith(
              color: current ? scheme.onPrimaryContainer : color,
              fontWeight: current ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}
