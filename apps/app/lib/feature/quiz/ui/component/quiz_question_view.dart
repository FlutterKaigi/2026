import 'dart:async';

import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 締切の何秒前で UI 側の入力をロックするか。サーバ側の write 拒否を
/// ユーザーに体感させないためのクライアント側マージン。
const _lockLeadSeconds = 3;

/// 出題中（`status == open`）の回答画面。
///
/// スポンサー名・問題文・選択肢ボタンを表示し、タップで自チームの回答を
/// 送信する。自チームの現在の選択はリアルタイムに反映し、`closesAt` から
/// カウントダウンをクライアント計算する。残り [_lockLeadSeconds] 秒で入力を
/// ロックする。
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
    final uid = ref.watch(quizSignInProvider).value;
    final teamAnswer = ref.watch(teamAnswerProvider).value;
    final sponsors = ref.watch(quizSponsorsProvider).value;
    final sponsorName = sponsors
        ?.where((sponsor) => sponsor.id == question.sponsorId)
        .map((sponsor) => sponsor.name.ja)
        .firstOrNull;

    // 送信失敗を静かに表示するためのインラインメッセージ。締切直後の
    // permission-denied は正常系として扱う。
    final submitError = useState<String?>(null);

    // 毎秒更新する現在時刻。カウントダウンの再計算に使う。
    final now = useState(DateTime.now());
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        now.value = DateTime.now();
      });
      return timer.cancel;
    }, const []);

    final remaining = question.closesAt?.difference(now.value).inSeconds;
    // closesAt 未設定時はロックしない（出題直後の一瞬を許容）。
    final locked = remaining != null && remaining <= _lockLeadSeconds;

    Future<void> submit(int index) async {
      if (locked || uid == null) {
        return;
      }
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
        submitError.value = '送信できませんでした。締め切られた可能性があります。';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sponsorName != null)
            Text(
              '提供: $sponsorName',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          const SizedBox(height: 12),
          Text(question.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          _Countdown(remaining: remaining),
          const SizedBox(height: 24),
          for (var index = 0; index < question.options.length; index++) ...[
            _OptionButton(
              label: question.options[index],
              selected: teamAnswer?.selectedOptionIndex == index,
              enabled: !locked,
              // 2 択は大きく、選択肢が多い場合はやや控えめの高さにする。
              height: question.options.length <= 2 ? 96 : 64,
              onTap: () => unawaited(submit(index)),
            ),
            const SizedBox(height: 16),
          ],
          if (locked)
            Text(
              '回答を締め切りました',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          if (teamAnswer?.selectedOptionIndex != null && teamAnswer?.answeredBy != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_answeredByName(team, teamAnswer!.answeredBy!)} が選択',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
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
  String _answeredByName(QuizTeam team, String uid) {
    return team.members
            .where((member) => member.uid == uid)
            .map((member) => member.displayName)
            .firstOrNull ??
        'メンバー';
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining});

  final int? remaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seconds = remaining == null ? null : (remaining! < 0 ? 0 : remaining!);
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          seconds == null ? '--' : '残り $seconds 秒',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.height,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
