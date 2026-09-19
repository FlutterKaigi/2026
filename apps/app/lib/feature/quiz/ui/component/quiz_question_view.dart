import 'dart:async';

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

/// 出題中（`status == open`）の回答画面。
///
/// スポンサー名・問題文・選択肢カードを表示し、タップで自チームの回答を
/// 送信する。自チームの現在の選択はリアルタイムに反映し、`closesAt` から
/// サーバーと同期したカウントダウンを計算する。受付可否は送信時に
/// サーバーが最終判断し、画面では締切に到達したとき入力をロックする。
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
    final clock = clockAsync.hasError || clockAsync.isLoading ? null : clockAsync.value;
    final tick = useState(0);
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) => tick.value++);
      final resync = Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidate(quizClockProvider));
      final lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(quizClockProvider));
      return () {
        timer.cancel();
        resync.cancel();
        lifecycle.dispose();
      };
    }, const []);
    // Recalibrate as soon as a cached answer stream reconnects.
    ref.listen(teamAnswerProvider, (previous, next) {
      if ((previous?.value?.isFromCache ?? false) && next.value?.isFromCache == false) {
        ref.invalidate(quizClockProvider);
      }
    });
    final reading = question.status == QuizQuestionStatus.reading;
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

    final submitError = useState<String?>(null);
    final sending = useState(false);
    final accepted = useState(false);

    Future<void> submit(int index) async {
      if (locked || sending.value || uid == null) {
        return;
      }
      unawaited(HapticFeedback.mediumImpact());
      submitError.value = null;
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
        submitError.value = switch (error.code) {
          'failed-precondition' => t.quiz.question.locked,
          'unavailable' || 'deadline-exceeded' => t.quiz.question.submitUnconfirmed,
          _ => t.quiz.question.submitFailed,
        };
      } on Exception {
        if (!context.mounted) {
          return;
        }
        submitError.value = t.quiz.question.submitUnconfirmed;
      } finally {
        if (context.mounted) {
          sending.value = false;
        }
      }
    }

    final selectedIndex = answerReady ? teamAnswer.selectedOptionIndex : null;
    final answeredBy = teamAnswer?.answeredBy;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 遅刻者が途中から開いてもテーブルが分かるよう常時表示する。
          Entrance(child: QuizTeamBadge(team: team)),
          const SizedBox(height: 16),
          if (sponsorName != null)
            Entrance(
              child: Text(
                t.quiz.question.sponsoredBy(name: sponsorName),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Entrance(
            delay: const Duration(milliseconds: 60),
            child: Text(question.title.resolve(locale), style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: 16),
          Entrance(
            delay: const Duration(milliseconds: 120),
            child: reading
                ? Text(t.quiz.question.reading, textAlign: TextAlign.center, style: theme.textTheme.titleMedium)
                : _CountdownBar(
                    remaining: remaining,
                    durationSeconds: question.durationSeconds,
                  ),
          ),
          const SizedBox(height: 24),
          for (var index = 0; index < question.options.length; index++) ...[
            Entrance(
              delay: Duration(milliseconds: 180 + index * 70),
              child: QuizOptionCard(
                index: index,
                label: question.options[index].resolve(locale),
                state: selectedIndex == index ? QuizOptionState.selected : QuizOptionState.idle,
                // 選択済みメンバー名は選択中のカード内に表示する。
                trailingNote: selectedIndex == index && answeredBy != null
                    ? t.quiz.question.answeredBy(name: _answeredByName(context, team, answeredBy))
                    : null,
                minHeight: question.options.length <= 2 ? 96 : 72,
                enabled: !locked && !sending.value,
                onTap: () => unawaited(submit(index)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (!reading && expired)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t.quiz.question.locked,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (!reading && !synchronized) ...[
            Text(
              clockAsync.hasError ? t.quiz.question.connectionUnavailable : t.quiz.question.synchronizing,
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () => ref.invalidate(quizClockProvider),
              child: Text(t.common.retry),
            ),
          ],
          if (cached || unconfirmed)
            Text(t.quiz.question.cached, textAlign: TextAlign.center)
          else if (answerAsync.hasError)
            Text(t.quiz.question.connectionUnavailable, textAlign: TextAlign.center),
          if (sending.value)
            Text(t.quiz.question.sending, textAlign: TextAlign.center)
          else if (accepted.value)
            Text(t.quiz.question.received, textAlign: TextAlign.center),
          if (selectedIndex != null) Text(t.quiz.question.teamAnswer, textAlign: TextAlign.center),
          if (submitError.value != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                submitError.value!,
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

    final seconds = remaining == null ? null : (remaining!.inMilliseconds / 1000).ceil().clamp(0, durationSeconds);
    final ratio = seconds == null || durationSeconds == 0 ? 1.0 : seconds / durationSeconds;
    final urgent = ratio <= _urgentRatio;
    final color = urgent ? theme.colorScheme.error : theme.colorScheme.primary;

    final counter = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Icon(Icons.timer_outlined, size: 22, color: color),
        const SizedBox(width: 6),
        Text(
          seconds == null ? '--' : '$seconds',
          style: theme.textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
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
      children: [
        // 残り 10 秒以下は数字を脈動させる。
        if (seconds != null && seconds <= 10 && seconds > 0) Pulse(maxScale: 1.12, child: counter) else counter,
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
