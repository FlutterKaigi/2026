import 'dart:async';

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/component/quiz_motion.dart';
import 'package:app/feature/quiz/ui/component/quiz_option_card.dart';
import 'package:app/feature/quiz/ui/component/quiz_team_badge.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 締切の何秒前で UI 側の入力をロックするか。サーバ側の write 拒否を
/// ユーザーに体感させないためのクライアント側マージン。
const _lockLeadSeconds = 3;

/// 残り時間がこの割合を下回ったらタイマーを警告色に切り替える。
const _urgentRatio = 0.2;

/// 出題中（`status == open`）の回答画面。
///
/// スポンサー名・問題文・選択肢カードを表示し、タップで自チームの回答を
/// 送信する。自チームの現在の選択はリアルタイムに反映し、`closesAt` から
/// カウントダウンをクライアント計算する。残り [_lockLeadSeconds] 秒で入力を
/// ロックする。
///
/// 毎秒の時計更新は [_CountdownBar] の内部に閉じているため、選択肢カードを
/// 含む本体は回答・ロック状態が変化したときだけ再構築される。
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
    final uid = ref.watch(quizSignInProvider).value;
    final teamAnswer = ref.watch(teamAnswerProvider).value;
    final sponsorName = ref.watch(
      quizSponsorsProvider.select(
        (sponsors) => sponsors.value
            ?.where((sponsor) => sponsor.id == question.sponsorId)
            .map((sponsor) => sponsor.name)
            .firstOrNull,
      ),
    )?.resolve(locale);

    // 送信失敗を静かに表示するためのインラインメッセージ。締切直後の
    // permission-denied は正常系として扱う。
    final submitError = useState<String?>(null);

    // 締切 [_lockLeadSeconds] 秒前に一度だけ入力をロックする。毎秒の再計算は
    // 行わず、締切時刻から逆算したワンショットタイマーで切り替える。
    final locked = useState(false);
    useEffect(() {
      final closesAt = question.closesAt;
      if (closesAt == null) {
        // closesAt 未設定時はロックしない（出題直後の一瞬を許容）。
        locked.value = false;
        return null;
      }
      final lockAt = closesAt.subtract(const Duration(seconds: _lockLeadSeconds));
      final untilLock = lockAt.difference(DateTime.now());
      if (untilLock.isNegative) {
        locked.value = true;
        return null;
      }
      locked.value = false;
      final timer = Timer(untilLock, () => locked.value = true);
      return timer.cancel;
    }, [question.closesAt]);

    Future<void> submit(int index) async {
      if (locked.value || uid == null) {
        return;
      }
      unawaited(HapticFeedback.mediumImpact());
      submitError.value = null;
      try {
        await ref
            .read(quizAnswerRepositoryProvider)
            .submit(
              ref.read(quizEventIdProvider),
              question.id,
              team.id,
              selectedOptionIndex: index,
              uid: uid,
            );
      } on Exception {
        // 締切直後の拒否などは静かに扱い、小さなインラインメッセージのみ出す。
        submitError.value = t.quiz.question.submitFailed;
      }
    }

    final selectedIndex = teamAnswer?.selectedOptionIndex;
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
            child: _CountdownBar(
              closesAt: question.closesAt,
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
                enabled: !locked.value,
                onTap: () => unawaited(submit(index)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (locked.value)
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
    return team.members
            .where((member) => member.uid == uid)
            .map((member) => member.displayName)
            .firstOrNull ??
        Translations.of(context).quiz.question.member;
  }
}

/// 残り時間の数字とプログレスバー。
///
/// 毎秒の時計はこのウィジェット内で完結させ、親（選択肢カードを含む
/// 回答画面全体）を毎秒再構築しないようにする。残りが [_urgentRatio] を
/// 切ると警告色に変わり、10 秒以下では数字が脈動して緊迫感を出す
/// （Kahoot 等のライブクイズで定番の演出）。
class _CountdownBar extends HookWidget {
  const _CountdownBar({required this.closesAt, required this.durationSeconds});

  final DateTime? closesAt;
  final int durationSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 毎秒更新する現在時刻。カウントダウンの再計算に使う。
    final now = useState(DateTime.now());
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        now.value = DateTime.now();
      });
      return timer.cancel;
    }, const []);

    final remaining = closesAt?.difference(now.value).inSeconds;
    final seconds = remaining?.clamp(0, durationSeconds);
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
