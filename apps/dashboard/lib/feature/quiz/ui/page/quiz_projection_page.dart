import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_check_in_code.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_countdown.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_status_label.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 会場投影用の読み取り専用画面。下書き・正解 secret を購読しない。
///
/// チェックインの受付中だけ、会場で配る参加コードと QR コードを表示する。
/// 会場外に出さないため、この画面は配信映像に映さない。
class QuizProjectionPage extends ConsumerWidget {
  const QuizProjectionPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(quizEventProvider(eventId));
    return Scaffold(
      appBar: AppBar(title: const Text('FlutterKaigi クイズ大会')),
      body: event.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('接続を確認してください')),
        data: (event) => event == null ? const Center(child: Text('イベントが見つかりません')) : _Projection(event: event),
      ),
    );
  }
}

class _Projection extends ConsumerWidget {
  const _Projection({required this.event});

  final QuizEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentQuestionId = event.currentQuestionId;
    final question = currentQuestionId == null
        ? null
        : ref.watch(quizQuestionProvider((eventId: event.id, questionId: currentQuestionId)));
    final questionData = question?.asData?.value;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(event.title.ja, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 24),
          if (event.status == QuizEventStatus.finished)
            _ProjectionTeams(event: event)
          else if (questionData != null && questionData.status != QuizQuestionStatus.draft)
            _ProjectionQuestion(question: questionData)
          else if (question?.hasError ?? false)
            const Text('問題の読み込みに失敗しました。接続を確認してください。')
          else if (currentQuestionId != null)
            const Center(child: CircularProgressIndicator())
          else ...[
            Text(quizEventStatusLabel(event.status), style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            if ((event.status == QuizEventStatus.registration || event.status == QuizEventStatus.entryClosed) &&
                event.teamSelectionStatus == QuizTeamSelectionStatus.open) ...[
              Text(
                'アプリのクイズ大会の画面で QR コードを読み取るか、参加コードを入力してチェックインしてください。',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              QuizCheckInCode(
                eventId: event.id,
                qrSize: 320,
                codeStyle: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 32),
            ],
            _ProjectionTeams(event: event),
          ],
        ],
      ),
    );
  }
}

class _ProjectionQuestion extends StatelessWidget {
  const _ProjectionQuestion({required this.question});

  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 24,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('第 ${question.order} 問', style: theme.textTheme.headlineMedium),
            Text(quizQuestionStatusLabel(question.status), style: theme.textTheme.titleLarge),
            if (question.status == QuizQuestionStatus.open && question.closesAt != null)
              QuizCountdown(closesAt: question.closesAt!, large: true),
          ],
        ),
        const SizedBox(height: 24),
        Text(question.title.ja, style: theme.textTheme.displaySmall),
        if (question.title.en.isNotEmpty) Text(question.title.en, style: theme.textTheme.titleLarge),
        const SizedBox(height: 24),
        for (var i = 0; i < question.options.length; i++)
          Card.filled(
            color: question.status == QuizQuestionStatus.revealed && question.correctOptionIndex == i
                ? theme.colorScheme.primaryContainer
                : null,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '${i + 1}. ${question.options[i].ja}'
                '${question.status == QuizQuestionStatus.revealed && question.correctOptionIndex == i ? '  ✓ 正解' : ''}'
                '${question.options[i].en.isEmpty ? '' : '\n${question.options[i].en}'}',
                style: theme.textTheme.headlineMedium,
              ),
            ),
          ),
        if (question.status == QuizQuestionStatus.reading)
          const Padding(padding: EdgeInsets.only(top: 16), child: Text('読み上げ後に回答受付を開始します。')),
        if (question.status == QuizQuestionStatus.revealed && question.explanation != null)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              '${question.explanation!.ja}\n${question.explanation!.en}',
              style: theme.textTheme.headlineSmall,
            ),
          ),
      ],
    );
  }
}

class _ProjectionTeams extends ConsumerWidget {
  const _ProjectionTeams({required this.event});

  final QuizEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finished = event.status == QuizEventStatus.finished;
    final heading = finished
        ? '結果発表'
        : switch (event.teamSelectionStatus) {
            QuizTeamSelectionStatus.notStarted => 'チェックインの開始をお待ちください。',
            QuizTeamSelectionStatus.open => 'チェックイン後、スタッフに案内されたテーブルのチーム（A〜T）を選択してください。',
            QuizTeamSelectionStatus.closed => 'チェックインとチーム選択は終了しました。出題をお待ちください。',
          };
    final teams = ref.watch(quizTeamListProvider(event.id));
    return teams.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Text('チームの読み込みに失敗しました。接続を確認してください。'),
      data: (teams) {
        final sorted = [...teams]
          ..sort((a, b) {
            final scoreOrder = finished ? b.score.compareTo(a.score) : 0;
            return scoreOrder != 0 ? scoreOrder : a.tableNumber.compareTo(b.tableNumber);
          });
        if (sorted.isEmpty) return Text(heading);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(heading, style: Theme.of(context).textTheme.headlineMedium),
            if (finished) const Text('同点は同順位です。賞品対象チームの決定は司会の案内に従ってください。'),
            const SizedBox(height: 16),
            for (final team in sorted)
              Card.filled(
                child: ListTile(
                  leading: Text(finished ? '${team.rank ?? '-'} 位' : '${team.memberUids.length} 人'),
                  title: Text(team.name, style: Theme.of(context).textTheme.titleLarge),
                  subtitle: Text(
                    finished ? 'チーム ${team.name}' : team.members.map((m) => m.displayName).join(' ・ '),
                  ),
                  trailing: finished ? Text('${team.score} 点', style: Theme.of(context).textTheme.headlineSmall) : null,
                ),
              ),
          ],
        );
      },
    );
  }
}
