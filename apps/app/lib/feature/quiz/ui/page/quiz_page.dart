import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/designsystem/theme/app_gradients.dart';
import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/ui/widget/centered_sign_in_card.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/component/quiz_check_in_view.dart';
import 'package:app/feature/quiz/ui/component/quiz_motion.dart';
import 'package:app/feature/quiz/ui/component/quiz_option_card.dart';
import 'package:app/feature/quiz/ui/component/quiz_question_view.dart';
import 'package:app/feature/quiz/ui/component/quiz_result_view.dart';
import 'package:app/feature/quiz/ui/component/quiz_rules_card.dart';
import 'package:app/feature/quiz/ui/component/quiz_team_badge.dart';
import 'package:app/feature/quiz/ui/component/quiz_team_selection_view.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
/// 参加登録・待機・チェックイン・チーム選択・出題・正解発表・最終結果を切り替える。
/// 状態の切り替えは [AnimatedSwitcher] でフェード + スライドさせ、
/// 会場のライブ進行に合わせて画面が「切り替わった」ことを体感させる。
class QuizPage extends HookWidget {
  const QuizPage({required this.eventId, this.checkInCode, super.key});

  final String eventId;

  /// Code from the venue check-in QR code's link (`quizCheckInQrPayload`),
  /// submitted once the attendee is signed in, registered and check-in is open.
  final String? checkInCode;

  @override
  Widget build(BuildContext context) {
    // 自動送信の記録は、サインインや状態の切り替わりで作り直される画面ではなく
    // ページで持つ。送り直すと誤ったコードのリンク 1 つで試行上限に達してしまう。
    final autoSubmissions = useRef(<QuizCheckInAutoSubmission>{});
    return ProviderScope(
      overrides: [quizEventIdProvider.overrideWithValue(eventId)],
      child: _QuizPageBody(checkInLink: (code: checkInCode, autoSubmissions: autoSubmissions.value)),
    );
  }
}

/// The check-in link code and the page's record of codes already sent for it.
typedef _CheckInLink = ({String? code, Set<QuizCheckInAutoSubmission> autoSubmissions});

class _QuizPageBody extends ConsumerWidget {
  const _QuizPageBody({required this.checkInLink});

  final _CheckInLink checkInLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    // クイズはログイン必須。サインアウトすると即座に案内へ切り替わる。
    final user = ref.watch(quizUserProvider);
    final eventAsync = ref.watch(quizEventProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.quiz.title)),
      body: switch (user) {
        AsyncError() => _Centered(message: t.quiz.errors.signInFailed),
        AsyncLoading() => const _Loading(),
        // QR コードのリンクから開いた場合もコードを失わないよう、この画面でサインインする。
        AsyncData(:final value) when value == null => CenteredSignInCard(
          title: t.auth.signIn.required,
          description: t.quiz.signInRequired.inPage,
        ),
        AsyncData(:final value) => switch (eventAsync) {
          AsyncData(value: null) => const _PreparingView(),
          AsyncData(value: final event?) => _QuizBody(event: event, uid: value!.uid, checkInLink: checkInLink),
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
  const _QuizBody({required this.event, required this.uid, required this.checkInLink});

  final QuizEvent event;
  final String uid;
  final _CheckInLink checkInLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantAsync = ref.watch(myParticipantProvider);
    final team = ref.watch(myTeamProvider).value;

    // 参加者ドキュメントの初回読込が終わるまでは「未登録」と断定しない。
    // 読込中に登録フォームや受付終了画面が一瞬表示されるのを防ぐ。
    final participantLoaded = participantAsync is AsyncData<QuizParticipant?>;
    final participant = participantAsync.value;

    // AnimatedSwitcher が状態の切り替わりを検知するためのキー。
    final (child, stateKey) = switch (event.status) {
      // 公開済み・受付開始前。開催準備中の案内を出す。
      // draft は一覧に出ず、ルール上も読めないため通常ここへは来ない。
      QuizEventStatus.draft || QuizEventStatus.published => (const _PreparingView(), 'preparing'),
      _ when !participantLoaded => (const _Loading(), 'loading'),
      QuizEventStatus.registration when participant == null => (
        _RegistrationForm(event: event),
        'registration',
      ),
      QuizEventStatus.registration when event.teamSelectionStatus != QuizTeamSelectionStatus.notStarted =>
        _checkInOrSelection(participant!),
      QuizEventStatus.registration => (const _Waiting(), 'waiting'),
      // 受付終了後に未登録のまま開いた場合の案内。従来はチーム発表画面の
      // ローディングが出続けていた。
      QuizEventStatus.entryClosed || QuizEventStatus.inProgress when participant == null => (
        const _EntryClosed(),
        'entry-closed',
      ),
      QuizEventStatus.entryClosed when event.teamSelectionStatus != QuizTeamSelectionStatus.notStarted =>
        _checkInOrSelection(participant!),
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

  /// チェックインの受付開始後。チェックインが済むまではチームを選べない。
  (Widget, String) _checkInOrSelection(QuizParticipant participant) => participant.checkedInAt == null
      ? (
          QuizCheckInView(
            event: event,
            uid: uid,
            linkCode: checkInLink.code,
            autoSubmissions: checkInLink.autoSubmissions,
          ),
          'check-in',
        )
      : (QuizTeamSelectionView(event: event, participant: participant), 'selection');

  /// 進行中（`status == inProgress`）の分岐。現在の問題の状態で切り替える。
  (Widget, String) _inProgress(WidgetRef ref, QuizTeam? team) {
    final question = ref.watch(currentQuestionProvider).value;

    // チームの購読が追いつく前の一瞬などは読込中にする。
    // 待機画面はチェックイン開始前の案内なので、進行中には出さない。
    if (team == null) {
      return (const _Loading(), 'loading');
    }
    // 出題前・問題切り替えの合間はチーム発表を出して次の問題を待つ。
    if (question == null) {
      return (_TeamAnnouncement(team: team, uid: uid), 'team');
    }

    return switch (question.status) {
      QuizQuestionStatus.reading || QuizQuestionStatus.open => (
        QuizQuestionView(key: ValueKey(question.id), question: question, team: team),
        'question-${question.id}',
      ),
      QuizQuestionStatus.closed => (_SuspenseView(team: team), 'closed-${question.id}'),
      QuizQuestionStatus.revealed => (
        _RevealedView(question: question, team: team),
        'revealed-${question.id}',
      ),
      // 参加者から見える想定は薄いが、念のため出題前と同じくチーム発表を出す。
      QuizQuestionStatus.draft => (_TeamAnnouncement(team: team, uid: uid), 'team'),
    };
  }
}

/// 参加する回を確認し、コードや追加入力なしで参加表明する。
class _RegistrationForm extends HookConsumerWidget {
  const _RegistrationForm({required this.event});
  final QuizEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final user = ref.watch(quizUserProvider).value;
    final submitting = useState(false);
    final errorMessage = useState<String?>(null);
    final participants = ref.watch(quizParticipantsProvider).value;
    final count = participants?.length ?? 0;
    // 定員はイベントごとの設定値。到達したら新規登録を締め切る。
    final isFull = count >= event.capacity;

    Future<void> register() async {
      if (isFull || user == null || submitting.value) {
        return;
      }
      submitting.value = true;
      errorMessage.value = null;
      try {
        await ref.read(quizParticipantRepositoryProvider).register(ref.read(quizEventIdProvider));
      } on FirebaseFunctionsException catch (error) {
        if (!context.mounted) {
          return;
        }
        errorMessage.value = switch (error.code) {
          'permission-denied' => t.quiz.registration.accountUnavailable,
          'resource-exhausted' => t.quiz.registration.full(max: '${event.capacity}'),
          'already-exists' => t.quiz.registration.alreadyParticipated,
          'failed-precondition' || 'not-found' => t.quiz.registration.closed,
          'unauthenticated' => t.quiz.errors.signInFailed,
          'unavailable' || 'deadline-exceeded' => t.quiz.registration.unavailable,
          _ => t.quiz.registration.failed,
        };
      } on Exception {
        if (!context.mounted) {
          return;
        }
        errorMessage.value = t.quiz.registration.failed;
      } finally {
        if (context.mounted) {
          submitting.value = false;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Entrance(
                  child: _BrandCard(
                    padding: const EdgeInsets.fromLTRB(20, 14, 6, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title.resolve(locale),
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                t.quiz.registration.subtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 装飾のロゴなので読み上げない。説明文が語の途中で折り返さないよう、
                        // 文字の領域を残す大きさに抑える。
                        Image.asset(
                          'res/assets/shuriken-logo.png',
                          width: 104,
                          height: 104,
                          excludeFromSemantics: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Entrance(
                  delay: const Duration(milliseconds: 80),
                  child: _CapacityCard(count: count, capacity: event.capacity),
                ),
                const SizedBox(height: 16),
                const Entrance(
                  delay: Duration(milliseconds: 140),
                  child: _JoinFlow(),
                ),
              ],
            ),
          ),
        ),
        // 参加ボタンは画面下部に固定し、参加の流れを読み進めても押せるようにする。
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.colorScheme.surfaceContainerHigh)),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Entrance(
                  delay: const Duration(milliseconds: 200),
                  child: FilledButton.icon(
                    onPressed: (!isFull && !submitting.value) ? () => unawaited(register()) : null,
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
          ),
        ),
      ],
    );
  }
}

/// ブランドのグラデーションに白文字を載せるカード。
///
/// スタンプラリーの進捗カードと同じ見た目にそろえ、参加表明・チーム発表・
/// 正解発表の主役の情報に使う。
class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.brand),
        // マゼンタ側でも白文字が読めるよう黒を重ねる。
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.16),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// 参加表明画面の参加人数と、定員に対する埋まり具合。
class _CapacityCard extends StatelessWidget {
  const _CapacityCard({required this.count, required this.capacity});

  final int count;
  final int capacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = Translations.of(context);
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.groups_outlined, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(t.quiz.registration.participantCount, style: mutedStyle)),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    CountUpText(
                      count,
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value) => Text(
                        '$value',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(t.quiz.registration.capacity(max: '$capacity'), style: mutedStyle),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 人数は上の数字で読み上げるため、バーは読み上げない。
            ExcludeSemantics(
              child: LinearProgressIndicator(
                value: count >= capacity ? 1 : count / capacity,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color: scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 参加表明から回答までの 4 段階。今いる「参加表明」だけを強調する。
class _JoinFlow extends StatelessWidget {
  const _JoinFlow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flow = Translations.of(context).quiz.registration.flow;
    final steps = <(String, String?)>[
      (flow.step1Title, null),
      (flow.step2Title, flow.step2Body),
      (flow.step3Title, flow.step3Body),
      (flow.step4Title, flow.step4Body),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            flow.title,
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 12),
        for (final (index, (title, body)) in steps.indexed)
          _JoinFlowStep(
            number: index + 1,
            title: title,
            body: body,
            current: index == 0,
            isLast: index == steps.length - 1,
          ),
      ],
    );
  }
}

class _JoinFlowStep extends StatelessWidget {
  const _JoinFlowStep({
    required this.number,
    required this.title,
    required this.body,
    required this.current,
    required this.isLast,
  });

  final int number;
  final String title;
  final String? body;
  final bool current;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = this.body;
    final numberStyle = theme.textTheme.labelLarge?.copyWith(
      color: current ? scheme.onPrimary : scheme.onPrimaryContainer,
      fontWeight: FontWeight.bold,
    );
    // 端末の文字サイズを上げても番号が切れないよう、丸は番号の行の高さに合わせて伸ばす。
    // 標準の文字サイズでは 28（行の高さ 20 + 余白 8）になる。
    final numberLineHeight =
        MediaQuery.textScalerOf(context).scale(numberStyle?.fontSize ?? 14) * (numberStyle?.height ?? 1.43);
    final circleSize = math.max<double>(28, numberLineHeight + 8);
    return MergeSemantics(
      // 番号の丸から次の段階へ、本文の高さに合わせて縦線をつなぐ。
      // 本文のない段階でも線が見えるよう、線には最小の長さを持たせる。
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: circleSize,
              child: Column(
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: current ? scheme.primary : scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text('$number', style: numberStyle),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        constraints: const BoxConstraints(minHeight: 12),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: scheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 3, bottom: isLast ? 0 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    if (body != null) ...[
                      const SizedBox(height: 2),
                      Text(body, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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

/// 確定したチームとメンバー、クイズのルールを表示する。
class _TeamAnnouncement extends HookWidget {
  const _TeamAnnouncement({required this.team, required this.uid});

  final QuizTeam? team;

  /// 自分の uid。メンバー一覧で自分の行を見分けるのに使う。
  final String uid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
    final membersEnd = Duration(milliseconds: 700 + team.members.length * 90);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Entrance(
            child: MergeSemantics(
              child: _BrandCard(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      // 端末の文字サイズに合わせて大きくし、1 行に収まらなければ折り返す。
                      // 標準の文字サイズでは幅 390 の端末でも 1 行に収まる大きさにする。
                      child: Text(
                        t.quiz.team.yourTable,
                        softWrap: true,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Entrance(
                      delay: const Duration(milliseconds: 250),
                      scaleFrom: 0.6,
                      offset: Offset.zero,
                      duration: const Duration(milliseconds: 450),
                      child: Container(
                        width: 112,
                        height: 112,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 3),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            team.name,
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card.filled(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Semantics(
                      header: true,
                      child: Text(
                        t.quiz.team.members(count: '${team.members.length}'),
                        style: theme.textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  for (final (index, member) in team.members.indexed)
                    Entrance(
                      delay: Duration(milliseconds: 700 + index * 90),
                      offset: const Offset(-0.05, 0),
                      child: _MemberTile(member: member, isMe: member.uid == uid),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Entrance(delay: membersEnd, child: const QuizRulesCard()),
          const SizedBox(height: 16),
          Entrance(
            delay: membersEnd + const Duration(milliseconds: 120),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: scheme.primaryContainer, spreadRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          t.quiz.team.gatherHint,
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// チーム発表のメンバー 1 人分の行。自分の行はアバターと名前を強調する。
class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.isMe});

  final QuizTeamMember member;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListTile(
      minTileHeight: 48,
      horizontalTitleGap: 12,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isMe ? scheme.primary : scheme.primaryContainer,
        child: Text(
          member.displayName.characters.first,
          // titleSmall の色（onSurface）が CircleAvatar の foregroundColor より優先されるため、
          // 頭文字の色は背景に合わせて明示する。
          style: theme.textTheme.titleSmall?.copyWith(
            color: isMe ? scheme.onPrimary : scheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        member.displayName,
        style: isMe ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold) : null,
      ),
      trailing: isMe
          ? DecoratedBox(
              decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(999)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                child: Text(
                  Translations.of(context).quiz.team.you,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
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

/// 1問の配点。サーバーの採点（functions/src/quiz_service.ts）と同じ値。
const _pointsPerQuestion = 10;

/// 正解発表画面（`question.status == revealed`）。
///
/// 自チームの正誤と合計点を先頭に置き、問題・正解選択肢・解説を続ける。
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
    // サーバーは未回答も isCorrect: false で採点するため、未回答は選択の有無で判定する。
    final isCorrect = answer == null || answer.selectedOptionIndex == null ? null : answer.isCorrect;
    final explanation = question.explanation?.resolve(locale);
    final number = t.quiz.question.number(n: '${question.order}');

    // 正解が分かった瞬間に 1 度だけハプティクスで祝う。
    useEffect(() {
      if (isCorrect ?? false) {
        unawaited(HapticFeedback.heavyImpact());
      }
      return null;
    }, [isCorrect]);

    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 遅刻者が途中から開いてもテーブルが分かるよう常時表示する。
          Entrance(
            child: Row(
              children: [
                QuizTeamBadge(team: team),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    // 未回答のときは下の見出しに「正解発表」を出すため、ここでは繰り返さない。
                    isCorrect == null ? number : '$number · ${t.quiz.revealed.title}',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isCorrect == null) ...[
            Entrance(
              child: Text(t.quiz.revealed.title, style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: 4),
            Entrance(
              child: Text(
                t.quiz.revealed.teamScore(score: '${team.score}'),
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ] else
            Entrance(
              delay: const Duration(milliseconds: 60),
              scaleFrom: 0.8,
              offset: Offset.zero,
              duration: const Duration(milliseconds: 450),
              child: _VerdictCard(isCorrect: isCorrect, score: team.score),
            ),
          const SizedBox(height: 20),
          Entrance(
            delay: const Duration(milliseconds: 160),
            child: Text(
              question.title.resolve(locale),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < question.options.length; index++) ...[
            Entrance(
              delay: Duration(milliseconds: 220 + index * 70),
              child: QuizOptionCard(
                index: index,
                label: question.options[index].resolve(locale),
                state: index == correctIndex
                    ? QuizOptionState.correct
                    : index == answer?.selectedOptionIndex
                    ? QuizOptionState.wrongChoice
                    : QuizOptionState.dimmed,
                trailingNote: index == answer?.selectedOptionIndex ? t.quiz.revealed.yourAnswer : null,
                minHeight: 64,
                enabled: false,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (explanation != null && explanation.isNotEmpty)
            Entrance(
              delay: Duration(milliseconds: 220 + question.options.length * 70),
              child: Card.filled(
                margin: const EdgeInsets.only(top: 6),
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

/// 正解発表で自チームの正誤と合計点を示すカード。
///
/// 正解はブランドのグラデーションに獲得点を添え、不正解はエラー色で示す。
class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.isCorrect, required this.score});

  final bool isCorrect;
  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = Translations.of(context);
    final foreground = isCorrect ? Colors.white : scheme.onErrorContainer;
    final verdict = Text(
      isCorrect ? t.quiz.revealed.correct : t.quiz.revealed.wrong,
      style: theme.textTheme.displayMedium?.copyWith(color: foreground, fontWeight: FontWeight.w800),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isCorrect)
          Row(
            children: [
              Expanded(child: verdict),
              const SizedBox(width: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Text(
                    t.quiz.revealed.gain(points: '$_pointsPerQuestion'),
                    // グラデーションと同じくテーマによらない色にする。
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimaryFixedVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          verdict,
        const SizedBox(height: 8),
        Text(
          t.quiz.revealed.teamScore(score: '$score'),
          style: theme.textTheme.titleSmall?.copyWith(color: foreground, fontWeight: FontWeight.w700),
        ),
      ],
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: isCorrect
          ? _BrandCard(child: content)
          : Card.filled(
              margin: EdgeInsets.zero,
              color: scheme.errorContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(padding: const EdgeInsets.all(20), child: content),
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
