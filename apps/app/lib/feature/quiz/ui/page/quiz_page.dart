import 'dart:async';

import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/component/quiz_question_view.dart';
import 'package:app/feature/quiz/ui/component/quiz_result_view.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// クイズ大会の単一ページ。
///
/// `quizEvents.status` と自分の参加状態を組み合わせたステートマシンで、
/// 参加登録・待機・チーム発表・出題・正解発表・最終結果を切り替える。
class QuizPage extends ConsumerWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 画面表示時に匿名サインインを開始する（副作用として評価させる）。
    final signIn = ref.watch(quizSignInProvider);
    final eventAsync = ref.watch(quizEventProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('クイズ大会')),
      body: switch (signIn) {
        AsyncError() => const _Centered(message: 'サインインに失敗しました'),
        AsyncLoading() => const _Loading(),
        AsyncData() => switch (eventAsync) {
          AsyncData(:final value) when value == null => const _Centered(
            message: 'クイズは開催準備中です',
          ),
          AsyncData(:final value) => _QuizBody(event: value!),
          AsyncError() => const _Centered(message: 'イベント情報の取得に失敗しました'),
          AsyncLoading() => const _Loading(),
        },
      },
    );
  }
}

/// サインイン・イベント取得が完了した後の本体。イベントの状態と自分の
/// 参加状態から表示すべきビューを決定する。
class _QuizBody extends ConsumerWidget {
  const _QuizBody({required this.event});

  final QuizEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participant = ref.watch(myParticipantProvider).value;
    final team = ref.watch(myTeamProvider).value;

    // 登録済みでチームが割り当てられていれば、イベントの status に依らず
    // チーム発表以降を優先して表示する（遅刻者もチームと進行中の問題を
    // 見続けられる）。
    final hasTeam = participant?.teamId != null;

    return switch (event.status) {
      QuizEventStatus.registration when hasTeam => _TeamAnnouncement(team: team),
      QuizEventStatus.registration when participant == null => const _RegistrationForm(),
      QuizEventStatus.registration => const _Waiting(),
      QuizEventStatus.teamBuilding => _TeamAnnouncement(team: team),
      QuizEventStatus.inProgress => _InProgress(team: team),
      QuizEventStatus.finished => QuizResultView(myTeam: team),
    };
  }
}

/// 進行中（`status == inProgress`）の分岐。現在の問題の状態で切り替える。
class _InProgress extends ConsumerWidget {
  const _InProgress({required this.team});

  final QuizTeam? team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = ref.watch(currentQuestionProvider).value;
    final team = this.team;

    // チーム未確定なら発表待ち（編成直後の一瞬など）。
    if (team == null) {
      return const _Waiting();
    }
    // 出題前・問題切り替えの合間はチーム発表を出して次の問題を待つ。
    if (question == null) {
      return _TeamAnnouncement(team: team);
    }

    return switch (question.status) {
      QuizQuestionStatus.open => QuizQuestionView(question: question, team: team),
      QuizQuestionStatus.closed => const _Centered(message: '回答締切。正解発表をお待ちください'),
      QuizQuestionStatus.revealed => _RevealedView(question: question, team: team),
      // 参加者から見える想定は薄いが、念のため待機扱いにする。
      QuizQuestionStatus.draft => const _Waiting(),
    };
  }
}

/// 参加登録フォーム。ニックネーム入力と参加人数のリアルタイム表示。
class _RegistrationForm extends HookConsumerWidget {
  const _RegistrationForm();

  static const _maxParticipants = 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = useTextEditingController();
    // TextField の入力に追従して参加ボタンの活性を更新する。
    final text = useState('');
    useEffect(() {
      void listener() => text.value = controller.text;
      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    final submitting = useState(false);
    final errorMessage = useState<String?>(null);
    final participants = ref.watch(quizParticipantsProvider).value;
    final count = participants?.length ?? 0;
    final isFull = count >= _maxParticipants;

    final trimmed = text.value.trim();
    final isValid = trimmed.isNotEmpty && trimmed.length <= 20;

    Future<void> register() async {
      final uid = ref.read(quizSignInProvider).value;
      if (!isValid || uid == null || submitting.value) {
        return;
      }
      submitting.value = true;
      errorMessage.value = null;
      try {
        await ref
            .read(quizParticipantRepositoryProvider)
            .register(ref.read(quizEventIdProvider), uid, trimmed);
      } on Exception {
        errorMessage.value = '登録できませんでした。時間をおいて再度お試しください。';
      } finally {
        submitting.value = false;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('クイズ大会に参加', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('現在の参加人数: $count 人', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            maxLength: 20,
            enabled: !isFull && !submitting.value,
            decoration: const InputDecoration(
              labelText: 'ニックネーム',
              hintText: '1〜20文字',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: (isValid && !isFull && !submitting.value) ? () => unawaited(register()) : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: submitting.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('参加する'),
          ),
          if (isFull)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '定員（$_maxParticipants 人）に達しました',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (errorMessage.value != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                errorMessage.value!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 登録完了後、チーム発表までの待機画面。
class _Waiting extends ConsumerWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final count = ref.watch(quizParticipantsProvider).value?.length ?? 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              '登録完了。チーム発表をお待ちください',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('現在の参加人数: $count 人', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// チーム発表画面。物理テーブル番号を主役に、チーム名・メンバーを表示する。
class _TeamAnnouncement extends StatelessWidget {
  const _TeamAnnouncement({required this.team});

  final QuizTeam? team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final team = this.team;
    if (team == null) {
      // teamId は付いたがチームドキュメント購読が追いつく前の一瞬など。
      return const _Loading();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text('あなたのテーブルは', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'テーブル ${team.tableNumber} へ！',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(team.name, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                for (final member in team.members)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(member.displayName),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 正解発表画面（`question.status == revealed`）。
///
/// 正解選択肢・解説・自チームの正誤・現在のチームスコアを表示する。
class _RevealedView extends ConsumerWidget {
  const _RevealedView({required this.question, required this.team});

  final QuizQuestion question;
  final QuizTeam team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final answer = ref.watch(teamAnswerProvider).value;
    final correctIndex = question.correctOptionIndex;
    final isCorrect = answer?.isCorrect;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('正解発表', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(question.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          for (var index = 0; index < question.options.length; index++)
            _OptionResultTile(
              label: question.options[index],
              isCorrect: index == correctIndex,
              isMyChoice: index == answer?.selectedOptionIndex,
            ),
          if (question.explanation != null && question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(question.explanation!, style: theme.textTheme.bodyMedium),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (isCorrect != null)
            Text(
              isCorrect ? '正解！' : '不正解',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: isCorrect ? theme.colorScheme.primary : theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '現在のチームスコア: ${team.score} 点',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _OptionResultTile extends StatelessWidget {
  const _OptionResultTile({
    required this.label,
    required this.isCorrect,
    required this.isMyChoice,
  });

  final String label;
  final bool isCorrect;
  final bool isMyChoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: isCorrect ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        leading: Icon(
          isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCorrect ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        title: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isMyChoice ? const Text('あなたの回答') : null,
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator.adaptive(),
  );
}

class _Centered extends StatelessWidget {
  const _Centered({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ),
  );
}
