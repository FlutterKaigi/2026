import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/component/quiz_motion.dart';
import 'package:app/feature/quiz/ui/component/quiz_option_card.dart';
import 'package:app/feature/quiz/ui/component/quiz_team_badge.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 残り時間がこの割合を下回ったらタイマーを警告色に切り替える。
const _urgentRatio = 0.2;

/// 回答を送信できなかった理由。
enum _SubmitFailure {
  /// サーバーが締切後として拒否した。
  locked,

  /// 通信が途切れ、受理されたかどうか分からない。
  unconfirmed,

  /// その他の理由で受理されなかった。
  failed,
}

/// サーバーで確定したチームの回答が、受理時刻 [acceptedBefore] の回答から更新されたか。
///
/// キャッシュや未確定の書き込みの回答はサーバーで確定していないため、更新とみなさない。
bool _updatedSince(AsyncValue<QuizAnswer?> answer, DateTime? acceptedBefore) {
  final value = answer.value;
  return answer is AsyncData<QuizAnswer?> &&
      value != null &&
      !value.isFromCache &&
      !value.hasPendingWrites &&
      value.submittedAt != acceptedBefore;
}

/// 出題中（`status == open`）の回答画面。
///
/// スポンサー名・問題文・選択肢カードを表示し、タップで自チームの回答を
/// 送信する。自チームの現在の選択はリアルタイムに反映し、`closesAt` から
/// サーバーと同期したカウントダウンを計算する。受付可否は送信時に
/// サーバーが最終判断し、画面では締切に到達したとき入力をロックする。
/// 回答の状態は下部の 1 つの枠で「送信中」「受理済み」「受理を確認できない」を
/// 切り替える。
///
/// 時刻はサーバーへ定期的に同期し、その間は単調増加の時計で進める。
class QuizQuestionView extends HookConsumerWidget {
  const QuizQuestionView({
    required this.question,
    required this.team,
    super.key,
  });

  final QuizQuestion question;
  final QuizTeam team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final uid = ref.watch(quizUserProvider).value?.uid;
    final answerAsync = ref.watch(teamAnswerProvider);
    final teamAnswer = answerAsync.value;
    final clockAsync = ref.watch(quizClockProvider);
    final clock = clockAsync.value;
    void resynchronizeAfterInterruption() {
      ref.read(quizClockProvider.notifier).resynchronizeAfterInterruption();
    }

    final tick = useState(0);
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) => tick.value++);
      final resync = Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidate(quizClockProvider));
      final lifecycle = AppLifecycleListener(onResume: resynchronizeAfterInterruption);
      return () {
        timer.cancel();
        resync.cancel();
        lifecycle.dispose();
      };
    }, const []);
    // Recalibrate as soon as a cached answer stream reconnects.
    ref.listen(teamAnswerProvider, (previous, next) {
      if ((previous?.value?.isFromCache ?? false) && next.value?.isFromCache == false) {
        resynchronizeAfterInterruption();
      }
    });
    final reading = question.status == QuizQuestionStatus.reading;
    // Periodic refreshes can keep a fresh clock; reconnect/resume must replace it.
    final synchronized = clock != null && clock.isFresh;
    final remaining = synchronized ? question.closesAt?.difference(clock.now) : null;
    final expired = remaining != null && remaining <= Duration.zero;
    final cached = teamAnswer?.isFromCache ?? false;
    final unconfirmed = teamAnswer?.hasPendingWrites ?? false;
    final answerReady = answerAsync is AsyncData<QuizAnswer?> && teamAnswer != null && !cached && !unconfirmed;
    final locked = reading || !synchronized || remaining == null || expired || !answerReady;
    final sponsorName = ref
        .watch(
          quizSponsorsProvider.select(
            (sponsors) => sponsors.value
                ?.where((sponsor) => sponsor.id == question.sponsorId)
                .map((sponsor) => sponsor.name)
                .firstOrNull,
          ),
        )
        ?.resolve(locale);

    // 送信できなかった理由と、その送信を始めたときにサーバーで確定していた回答の受理時刻。
    final submitFailure = useState<({_SubmitFailure reason, DateTime? acceptedBefore})?>(null);
    final sending = useState(false);
    final accepted = useState(false);
    // 送信に失敗したあとでも、サーバーで確定したチームの回答が更新されたら
    // （タイムアウト後に受理された、または別のメンバーが回答した）、失敗の表示を取り下げる。
    ref.listen(teamAnswerProvider, (_, next) {
      final failure = submitFailure.value;
      if (failure != null && _updatedSince(next, failure.acceptedBefore)) {
        submitFailure.value = null;
      }
    });

    Future<void> submit(int index) async {
      if (locked || sending.value || uid == null) {
        return;
      }
      unawaited(HapticFeedback.mediumImpact());
      final acceptedBefore = teamAnswer.submittedAt;
      // 応答を待つ間にサーバーで確定した回答が更新されていれば、失敗ではなくその回答を表示する。
      void fail(_SubmitFailure reason) {
        if (!_updatedSince(ref.read(teamAnswerProvider), acceptedBefore)) {
          submitFailure.value = (reason: reason, acceptedBefore: acceptedBefore);
        }
      }

      submitFailure.value = null;
      accepted.value = false;
      sending.value = true;
      try {
        await ref
            .read(quizAnswerRepositoryProvider)
            .submit(
              ref.read(quizEventIdProvider),
              question.id,
              team.id,
              selectedOptionIndex: index,
            );
        if (!context.mounted) {
          return;
        }
        accepted.value = true;
      } on FirebaseFunctionsException catch (error) {
        if (!context.mounted) {
          return;
        }
        fail(switch (error.code) {
          'failed-precondition' => _SubmitFailure.locked,
          'unavailable' || 'deadline-exceeded' => _SubmitFailure.unconfirmed,
          _ => _SubmitFailure.failed,
        });
      } on Exception {
        if (!context.mounted) {
          return;
        }
        fail(_SubmitFailure.unconfirmed);
      } finally {
        if (context.mounted) {
          sending.value = false;
        }
      }
    }

    final selectedIndex = answerReady ? teamAnswer.selectedOptionIndex : null;
    final answeredBy = teamAnswer?.answeredBy;

    // 受理済みと言えるのは、本人の送信が成功したときか、キャッシュでも
    // 未確定の書き込みでもないチームの回答が届いているときだけ。
    final answerStatus = sending.value
        ? _AnswerStatusBox(tone: _StatusTone.sending, title: t.quiz.question.sending)
        : switch (submitFailure.value?.reason) {
            // 締切後の拒否は、下の「回答を締め切りました」と重ねて出さない。
            _SubmitFailure.locked when expired => null,
            _SubmitFailure.locked => _AnswerStatusBox(tone: _StatusTone.error, title: t.quiz.question.locked),
            _SubmitFailure.unconfirmed => _AnswerStatusBox(
              tone: _StatusTone.unconfirmed,
              title: t.quiz.question.submitUnconfirmed,
            ),
            _SubmitFailure.failed => _AnswerStatusBox(tone: _StatusTone.error, title: t.quiz.question.submitFailed),
            null when cached || unconfirmed => _AnswerStatusBox(
              tone: _StatusTone.unconfirmed,
              title: t.quiz.question.cached,
            ),
            null when answerAsync.hasError => _AnswerStatusBox(
              tone: _StatusTone.unconfirmed,
              title: t.quiz.question.connectionUnavailable,
            ),
            null when accepted.value || selectedIndex != null => _AnswerStatusBox(
              tone: _StatusTone.accepted,
              title: t.quiz.question.accepted,
              detail: t.quiz.question.changeHint,
            ),
            null => null,
          };

    return CustomScrollView(
      slivers: [
        // 回答の状態は、選択肢が少ないときも画面の下端にそろえる。
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
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
                          t.quiz.question.number(n: question.order),
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
                const SizedBox(height: 20),
                if (sponsorName != null) ...[
                  Entrance(
                    child: Text(
                      t.quiz.question.sponsoredBy(name: sponsorName),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Entrance(
                  delay: const Duration(milliseconds: 60),
                  child: Text(
                    question.title.resolve(locale),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Entrance(
                  delay: const Duration(milliseconds: 120),
                  child: reading
                      ? const _ReadingBanner()
                      : _CountdownBar(
                          remaining: remaining,
                          durationSeconds: question.durationSeconds,
                        ),
                ),
                if (!reading && !synchronized) ...[
                  const SizedBox(height: 8),
                  Text(
                    clockAsync.hasError ? t.quiz.question.connectionUnavailable : t.quiz.question.synchronizing,
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(quizClockProvider),
                    child: Text(t.common.retry),
                  ),
                ],
                const SizedBox(height: 20),
                for (var index = 0; index < question.options.length; index++) ...[
                  if (index > 0) const SizedBox(height: 10),
                  Entrance(
                    delay: Duration(milliseconds: 180 + index * 70),
                    child: QuizOptionCard(
                      index: index,
                      label: question.options[index].resolve(locale),
                      // 読み上げ中も選択肢を読めるよう薄くしない。受付前であることは
                      // 上の案内と、押せない状態で伝える。
                      state: selectedIndex == index ? QuizOptionState.selected : QuizOptionState.idle,
                      // 選択済みメンバー名は選択中のカード内に表示する。
                      trailingNote: selectedIndex == index && answeredBy != null
                          ? t.quiz.question.answeredBy(name: _answeredByName(context, team, answeredBy))
                          : null,
                      minHeight: question.options.length <= 2 ? 96 : 68,
                      enabled: !locked && !sending.value,
                      onTap: () => unawaited(submit(index)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Spacer(),
                if (!reading && expired)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      t.quiz.question.locked,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (answerStatus != null)
                  answerStatus
                else if (!locked)
                  Text(
                    t.quiz.question.tapHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// `answeredBy`（uid）を表示名に解決する。見つからなければ「メンバー」。
  String _answeredByName(BuildContext context, QuizTeam team, String uid) {
    return team.members.where((member) => member.uid == uid).map((member) => member.displayName).firstOrNull ??
        Translations.of(context).quiz.question.member;
  }
}

/// 残り時間の数字とプログレスバー。
///
/// サーバーに同期した残り時間を表示する。残りが [_urgentRatio] を
/// 切ると警告色に変わり、10 秒以下では数字が脈動して緊迫感を出す
/// （Kahoot 等のライブクイズで定番の演出）。
class _CountdownBar extends StatelessWidget {
  const _CountdownBar({required this.remaining, required this.durationSeconds});

  final Duration? remaining;
  final int durationSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final seconds = remaining == null ? null : math.max(0, (remaining!.inMilliseconds / 1000).ceil());
    final ratio = seconds == null || durationSeconds <= 0 ? 1.0 : math.min<double>(1, seconds / durationSeconds);
    final urgent = ratio <= _urgentRatio;
    final color = urgent ? theme.colorScheme.error : theme.colorScheme.primary;

    final counter = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Icon(Icons.timer_outlined, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          seconds == null ? '--' : '$seconds',
          style: theme.textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          Translations.of(context).quiz.question.secondsUnit,
          style: theme.textTheme.titleSmall?.copyWith(color: color),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          // 残り 10 秒以下は数字を脈動させる。
          child: seconds != null && seconds <= 10 && seconds > 0 ? Pulse(maxScale: 1.12, child: counter) : counter,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: ratio, end: ratio),
            duration: const Duration(seconds: 1),
            builder: (context, animated, _) => LinearProgressIndicator(
              value: animated,
              minHeight: 8,
              color: color,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
      ],
    );
  }
}

/// 読み上げ中の案内。回答の受付が始まるまで、残り時間の代わりに出す。
class _ReadingBanner extends StatelessWidget {
  const _ReadingBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.volume_up_outlined, size: 22, color: scheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                Translations.of(context).quiz.question.reading,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 回答の状態の種類。
enum _StatusTone {
  /// 送信中。
  sending,

  /// サーバーがチームの回答として受理した。
  accepted,

  /// 受理されたかどうか、または最新の回答を確認できない。
  unconfirmed,

  /// 受理されなかった。
  error,
}

/// 下部に出す回答の状態の枠。状態が変わったら読み上げる。
class _AnswerStatusBox extends StatelessWidget {
  const _AnswerStatusBox({required this.tone, required this.title, this.detail});

  final _StatusTone tone;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final icon = switch (tone) {
      _StatusTone.sending => SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
      ),
      _StatusTone.accepted => Icon(Icons.check_rounded, size: 20, color: scheme.primary),
      _StatusTone.unconfirmed => Icon(Icons.sync_problem_rounded, size: 20, color: scheme.error),
      _StatusTone.error => Icon(Icons.error_outline_rounded, size: 20, color: scheme.error),
    };
    // 長い注意文は太字にせず、短い状態の見出しだけを太字にする。
    final short = tone == _StatusTone.sending || tone == _StatusTone.accepted;
    final detail = this.detail;

    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tone == _StatusTone.error ? scheme.error : scheme.onSurface,
                        fontWeight: short ? FontWeight.bold : null,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
