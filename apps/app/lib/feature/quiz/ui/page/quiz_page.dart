import 'dart:async';

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/component/quiz_motion.dart';
import 'package:app/feature/quiz/ui/component/quiz_option_card.dart';
import 'package:app/feature/quiz/ui/component/quiz_question_view.dart';
import 'package:app/feature/quiz/ui/component/quiz_result_view.dart';
import 'package:app/feature/quiz/ui/component/quiz_team_badge.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// クイズ大会の単一イベントページ。
///
/// イベント一覧から `eventId` を受け取り、`ProviderScope` の override で
/// 配下のプロバイダ群に対象イベントを供給する。
/// `quizEvents.status` と自分の参加状態を組み合わせたステートマシンで、
/// 参加登録・待機・チーム発表・出題・正解発表・最終結果を切り替える。
/// 状態の切り替えは [AnimatedSwitcher] でフェード + スライドさせ、
/// 会場のライブ進行に合わせて画面が「切り替わった」ことを体感させる。
class QuizPage extends StatelessWidget {
  const QuizPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [quizEventIdProvider.overrideWithValue(eventId)],
      child: const _QuizPageBody(),
    );
  }
}

class _QuizPageBody extends ConsumerWidget {
  const _QuizPageBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    // 画面表示時に匿名サインインを開始する（副作用として評価させる）。
    final signIn = ref.watch(quizSignInProvider);
    final eventAsync = ref.watch(quizEventProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.quiz.title)),
      body: switch (signIn) {
        AsyncError() => _Centered(message: t.quiz.errors.signInFailed),
        AsyncLoading() => const _Loading(),
        AsyncData() => switch (eventAsync) {
          AsyncData(:final value) when value == null => const _PreparingView(),
          AsyncData(:final value) => _QuizBody(event: value!),
          AsyncError() => _Centered(message: t.quiz.errors.eventLoadFailed),
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
    final participantAsync = ref.watch(myParticipantProvider);
    final team = ref.watch(myTeamProvider).value;

    // 参加者ドキュメントの初回読込が終わるまでは「未登録」と断定しない。
    // 読込中に登録フォームや受付終了画面が一瞬表示されるのを防ぐ。
    final participantLoaded = participantAsync is AsyncData<QuizParticipant?>;
    final participant = participantAsync.value;

    // 登録済みでチームが割り当てられていれば、イベントの status に依らず
    // チーム発表以降を優先して表示する（遅刻者もチームと進行中の問題を
    // 見続けられる）。
    final hasTeam = participant?.teamId != null;

    // AnimatedSwitcher が状態の切り替わりを検知するためのキー。
    final (child, stateKey) = switch (event.status) {
      // 公開済み・受付開始前。開催準備中の案内を出す。
      // draft は一覧に出ず、ルール上も読めないため通常ここへは来ない。
      QuizEventStatus.draft || QuizEventStatus.published => (const _PreparingView(), 'preparing'),
      _ when !participantLoaded => (const _Loading(), 'loading'),
      QuizEventStatus.registration when hasTeam => (_TeamAnnouncement(team: team), 'team'),
      QuizEventStatus.registration when participant == null => (
        _RegistrationForm(event: event),
        'registration',
      ),
      QuizEventStatus.registration => (const _Waiting(), 'waiting'),
      // 受付終了後に未登録のまま開いた場合の案内。従来はチーム発表画面の
      // ローディングが出続けていた。
      QuizEventStatus.entryClosed || QuizEventStatus.inProgress when participant == null => (
        const _EntryClosed(),
        'entry-closed',
      ),
      QuizEventStatus.entryClosed when hasTeam => (_TeamAnnouncement(team: team), 'team'),
      QuizEventStatus.entryClosed => (const _Waiting(), 'waiting'),
      QuizEventStatus.inProgress => _inProgress(ref, team),
      // 終了後は未参加者にもランキングを見せる（自チームカードは非表示）。
      QuizEventStatus.finished => (QuizResultView(myTeam: team), 'result'),
    };

    if (!motionEnabled(context)) {
      return child;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }

  /// 進行中（`status == inProgress`）の分岐。現在の問題の状態で切り替える。
  (Widget, String) _inProgress(WidgetRef ref, QuizTeam? team) {
    final question = ref.watch(currentQuestionProvider).value;

    // チーム未確定なら発表待ち（編成直後の一瞬など）。
    if (team == null) {
      return (const _Waiting(), 'waiting');
    }
    // 出題前・問題切り替えの合間はチーム発表を出して次の問題を待つ。
    if (question == null) {
      return (_TeamAnnouncement(team: team), 'team');
    }

    return switch (question.status) {
      QuizQuestionStatus.open => (
        QuizQuestionView(question: question, team: team),
        'question-${question.id}',
      ),
      QuizQuestionStatus.closed => (_SuspenseView(team: team), 'closed-${question.id}'),
      QuizQuestionStatus.revealed => (
        _RevealedView(question: question, team: team),
        'revealed-${question.id}',
      ),
      // 参加者から見える想定は薄いが、念のため待機扱いにする。
      QuizQuestionStatus.draft => (const _Waiting(), 'waiting'),
    };
  }
}

/// 参加登録フォーム。イベント名・参加人数のリアルタイム表示と
/// ニックネーム・現地受付コードの入力。
///
/// 受付コードは会場の受付で案内される 6 桁の数字。コードの照合は
/// セキュリティルールが行い、不一致は permission-denied で失敗する。
class _RegistrationForm extends HookConsumerWidget {
  const _RegistrationForm({required this.event});

  final QuizEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final controller = useTextEditingController();
    final codeController = useTextEditingController();
    // TextField の入力に追従して参加ボタンの活性を更新する。
    final text = useState('');
    final codeText = useState('');
    useEffect(() {
      void listener() => text.value = controller.text;
      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);
    useEffect(() {
      void listener() => codeText.value = codeController.text;
      codeController.addListener(listener);
      return () => codeController.removeListener(listener);
    }, [codeController]);

    final submitting = useState(false);
    final errorMessage = useState<String?>(null);
    final participants = ref.watch(quizParticipantsProvider).value;
    final count = participants?.length ?? 0;
    // 定員はイベントごとの設定値。到達したら新規登録を締め切る。
    final isFull = count >= event.capacity;

    final trimmed = text.value.trim();
    final code = codeText.value.trim();
    final isValid = trimmed.isNotEmpty && trimmed.length <= 20 && code.isNotEmpty;

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
            .register(ref.read(quizEventIdProvider), uid, trimmed, code);
      } on Exception {
        // 主因は受付コード不一致（ルールで permission-denied）。
        errorMessage.value = t.quiz.registration.codeMismatch;
      } finally {
        submitting.value = false;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Entrance(
            child: Card.filled(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 40,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.title.resolve(locale),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.quiz.registration.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Entrance(
            delay: const Duration(milliseconds: 80),
            child: _ParticipantCounter(count: count),
          ),
          const SizedBox(height: 24),
          Entrance(
            delay: const Duration(milliseconds: 160),
            child: TextField(
              controller: controller,
              maxLength: 20,
              enabled: !isFull && !submitting.value,
              decoration: InputDecoration(
                labelText: t.quiz.registration.nickname,
                hintText: t.quiz.registration.nicknameHint,
                prefixIcon: const Icon(Icons.badge_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Entrance(
            delay: const Duration(milliseconds: 180),
            child: TextField(
              controller: codeController,
              maxLength: 6,
              keyboardType: TextInputType.number,
              enabled: !isFull && !submitting.value,
              decoration: InputDecoration(
                labelText: t.quiz.registration.entryCode,
                hintText: t.quiz.registration.entryCodeHint,
                helperText: t.quiz.registration.entryCodeHelper,
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.pin_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Entrance(
            delay: const Duration(milliseconds: 200),
            child: FilledButton.icon(
              onPressed: (isValid && !isFull && !submitting.value) ? () => unawaited(register()) : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              icon: submitting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(t.quiz.registration.join),
            ),
          ),
          if (isFull)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                t.quiz.registration.full(max: '${event.capacity}'),
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

/// 現在の参加人数。人が増えるたびに数字がカウントアップする。
class _ParticipantCounter extends StatelessWidget {
  const _ParticipantCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = Translations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.groups_outlined, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(t.quiz.registration.participantCount, style: theme.textTheme.bodyMedium),
        const SizedBox(width: 8),
        CountUpText(
          count,
          duration: const Duration(milliseconds: 500),
          builder: (context, value) => Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(t.quiz.registration.participantUnit, style: theme.textTheme.bodyMedium),
      ],
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
            Pulse(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              Translations.of(context).quiz.waiting.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.of(context).quiz.waiting.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _ParticipantCounter(count: count),
          ],
        ),
      ),
    );
  }
}

/// チーム発表画面。物理テーブル番号を主役に、チーム名・メンバーを表示する。
///
/// 「あなたのテーブルは」→ テーブル番号 → チーム名 → メンバーの順に
/// 段階的に登場させ、会場でのチーム発表の高揚感を演出する。
class _TeamAnnouncement extends HookWidget {
  const _TeamAnnouncement({required this.team});

  final QuizTeam? team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = Translations.of(context);
    final team = this.team;

    // 発表時に軽いハプティクスを 1 度だけ鳴らす。
    useEffect(() {
      if (team != null) {
        unawaited(HapticFeedback.lightImpact());
      }
      return null;
    }, [team?.id]);

    if (team == null) {
      // teamId は付いたがチームドキュメント購読が追いつく前の一瞬など。
      return const _Loading();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Entrance(
            child: Text(
              t.quiz.team.yourTable,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          Entrance(
            delay: const Duration(milliseconds: 250),
            scaleFrom: 0.6,
            offset: Offset.zero,
            duration: const Duration(milliseconds: 450),
            child: Center(
              child: Container(
                width: 160,
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary, width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.quiz.team.table,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '${team.tableNumber}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Entrance(
            delay: const Duration(milliseconds: 550),
            child: Column(
              children: [
                Text(
                  t.quiz.team.teamLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  team.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card.filled(
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final (index, member) in team.members.indexed)
                    Entrance(
                      delay: Duration(milliseconds: 700 + index * 90),
                      offset: const Offset(-0.05, 0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          child: Text(
                            member.displayName.characters.first,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(member.displayName),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Entrance(
            delay: Duration(milliseconds: 700 + team.members.length * 90),
            child: Text(
              t.quiz.team.gatherHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// イベント未作成・受付開始前（開催前）の案内画面。
class _PreparingView extends StatelessWidget {
  const _PreparingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = Translations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.upcoming_outlined,
                size: 48,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.quiz.preparing.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              t.quiz.preparing.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 受付終了後に未登録のまま開いた場合の案内画面。
///
/// クイズは進行中だが参加はできない。終了後は自動的に最終結果へ
/// 切り替わるため、その旨を伝えて画面を開いたままにしてもらう。
class _EntryClosed extends StatelessWidget {
  const _EntryClosed();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_clock_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              Translations.of(context).quiz.entryClosed.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.of(context).quiz.entryClosed.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 回答締切〜正解発表までのサスペンス画面。
class _SuspenseView extends StatelessWidget {
  const _SuspenseView({required this.team});

  final QuizTeam team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuizTeamBadge(team: team),
            const SizedBox(height: 24),
            Pulse(
              maxScale: 1.15,
              duration: const Duration(milliseconds: 700),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: 48,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              Translations.of(context).quiz.suspense.title,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.of(context).quiz.suspense.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 正解発表画面（`question.status == revealed`）。
///
/// 正解選択肢・解説・自チームの正誤・現在のチームスコアを表示する。
/// 正解時は紙吹雪とハプティクスで祝う。
class _RevealedView extends HookConsumerWidget {
  const _RevealedView({required this.question, required this.team});

  final QuizQuestion question;
  final QuizTeam team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final answer = ref.watch(teamAnswerProvider).value;
    final correctIndex = question.correctOptionIndex;
    final isCorrect = answer?.isCorrect;
    final explanation = question.explanation?.resolve(locale);

    // 正解が分かった瞬間に 1 度だけハプティクスで祝う。
    useEffect(() {
      if (isCorrect ?? false) {
        unawaited(HapticFeedback.heavyImpact());
      }
      return null;
    }, [isCorrect]);

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 遅刻者が途中から開いてもテーブルが分かるよう常時表示する。
          Entrance(child: QuizTeamBadge(team: team)),
          const SizedBox(height: 16),
          Entrance(
            child: Text(t.quiz.revealed.title, style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: 12),
          Entrance(
            delay: const Duration(milliseconds: 60),
            child: Text(question.title.resolve(locale), style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < question.options.length; index++) ...[
            Entrance(
              delay: Duration(milliseconds: 120 + index * 70),
              child: QuizOptionCard(
                index: index,
                label: question.options[index].resolve(locale),
                state: index == correctIndex
                    ? QuizOptionState.correct
                    : index == answer?.selectedOptionIndex
                    ? QuizOptionState.wrongChoice
                    : QuizOptionState.dimmed,
                trailingNote: index == answer?.selectedOptionIndex ? t.quiz.revealed.yourAnswer : null,
                enabled: false,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (explanation != null && explanation.isNotEmpty)
            Entrance(
              delay: const Duration(milliseconds: 400),
              child: Card.filled(
                color: theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, color: theme.colorScheme.tertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(explanation, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (isCorrect != null)
            Entrance(
              delay: const Duration(milliseconds: 550),
              scaleFrom: 0.5,
              offset: Offset.zero,
              duration: const Duration(milliseconds: 450),
              child: Text(
                isCorrect ? t.quiz.revealed.correct : t.quiz.revealed.wrong,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: isCorrect ? theme.colorScheme.primary : theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Entrance(
            delay: const Duration(milliseconds: 700),
            child: Card.filled(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.scoreboard_outlined, color: theme.colorScheme.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      t.quiz.revealed.teamScore(score: '${team.score}'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isCorrect ?? false) {
      return Stack(
        children: [
          content,
          const Positioned.fill(
            child: IgnorePointer(child: ConfettiBurst()),
          ),
        ],
      );
    }
    return content;
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
