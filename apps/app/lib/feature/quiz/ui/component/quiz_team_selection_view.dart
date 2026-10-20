import 'dart:math' as math;

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/component/quiz_progress_steps.dart';
import 'package:app/feature/quiz/ui/component/quiz_rules_card.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// チェックイン後に、着席したテーブルのチーム（A〜T）を選ぶ画面。
///
/// タイルを選んだだけでは保存せず、下部の「このチームに決定」で送信する。
/// 保存済みのチームはサーバーの参加記録から表示し、送信の完了だけでは決定扱いにしない。
class QuizTeamSelectionView extends HookConsumerWidget {
  const QuizTeamSelectionView({required this.event, required this.participant, super.key});
  final QuizEvent event;
  final QuizParticipant participant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context).quiz.selection;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final choice = useState(participant.teamId);
    final submitting = useState(false);
    final error = useState<String?>(null);
    final participants = ref.watch(quizParticipantsProvider).value;
    final isOpen = event.teamSelectionStatus == QuizTeamSelectionStatus.open;
    final savedTeamId = participant.teamId;
    useEffect(() {
      choice.value = participant.teamId;
      return null;
    }, [participant.teamId]);
    // 送信の失敗は「このチームに決定」の押し直しを促すため、受付が閉じたら消す。
    // 受付の終了後に届いた失敗も、再開したときに残っていないよう切り替わりごとに消す。
    useEffect(() {
      error.value = null;
      return null;
    }, [isOpen]);

    Future<void> select() async {
      final teamId = choice.value;
      if (teamId == null || submitting.value || !isOpen) {
        return;
      }
      submitting.value = true;
      error.value = null;
      try {
        await ref
            .read(quizParticipantRepositoryProvider)
            .selectTeam(
              event.id,
              teamId,
              expectedTeamId: participant.teamId,
            );
      } on FirebaseFunctionsException catch (failure) {
        if (!context.mounted) {
          return;
        }
        final details = failure.details;
        error.value = details is Map && details['reason'] == 'team-changed' ? t.changed : t.failed;
      } on Exception {
        if (context.mounted) {
          error.value = t.failed;
        }
      } finally {
        if (context.mounted) {
          submitting.value = false;
        }
      }
    }

    final status = Row(
      children: [
        Icon(Icons.groups_outlined, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            savedTeamId == null ? t.unselected : t.current(team: savedTeamId),
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
    final errorText = error.value == null
        ? null
        : Semantics(
            liveRegion: true,
            child: Text(error.value!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.error)),
          );

    final header = <Widget>[
      const QuizProgressSteps(current: QuizProgressStep.selectTeam),
      const SizedBox(height: 24),
      Semantics(
        header: true,
        child: Text(t.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 8),
    ];

    if (!isOpen) {
      // 受付終了後は選び直せないため、保存済みのチームと案内だけを出す。送信の失敗は押し直せないので出さない。
      // チームが決まっていれば、初出題までの説明の間にルールを確認できるよう添える。
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...header,
            Text(
              savedTeamId == null ? t.closedUnselected : t.closed,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            status,
            if (savedTeamId != null) ...[
              const SizedBox(height: 20),
              const QuizRulesCard(),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...header,
                Text(t.instructions, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 20),
                GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    // 大きな文字でも人数が切れないよう、高さは中の文字の拡大後の高さから決める。
                    mainAxisExtent: _TeamTile.extent(context),
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final teamId in quizTeamIds)
                      _TeamTile(
                        teamId: teamId,
                        memberCount: participants?.where((person) => person.teamId == teamId).length,
                        picked: choice.value == teamId,
                        saved: savedTeamId == teamId,
                        onTap: submitting.value ? null : () => choice.value = teamId,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // 状態と決定ボタンは、グリッドをスクロールしても常に見えるよう下部に固定する。
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.surfaceContainerHigh)),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  status,
                  if (errorText != null) errorText,
                  FilledButton(
                    onPressed: submitting.value || choice.value == null || choice.value == savedTeamId ? null : select,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    child: Text(submitting.value ? t.sending : t.confirm),
                  ),
                  Text(
                    t.changeHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// チーム 1 つ分の選択タイル。チーム名と現在の人数を出す。
///
/// 選択中は primary で塗り、保存済み（選択中でない）は primaryContainer に枠を付けて区別する。
class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.teamId,
    required this.memberCount,
    required this.picked,
    required this.saved,
    required this.onTap,
  });

  final String teamId;

  /// 参加者一覧を読み込むまでは `null`。
  final int? memberCount;
  final bool picked;
  final bool saved;
  final VoidCallback? onTap;

  /// 人数の前に添えるアイコンの大きさ。アイコンは文字の拡大に合わせて伸ばさない。
  static const _countIconSize = 12.0;

  static TextStyle? _nameStyle(TextTheme textTheme) =>
      textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.2);

  static TextStyle? _countStyle(TextTheme textTheme) => textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500);

  /// タイルの高さ。チーム名と人数の行を拡大した後の高さに上下の余白を足して求める（最小 60）。
  ///
  /// Android の文字の拡大は大きさごとに倍率が異なり、大きな値ほど伸びが小さい。
  /// タイルの高さそのものを拡大すると中の文字より伸びが足りず人数の行が切れるため、
  /// 文字ごとに拡大した高さを足し合わせる。
  static double extent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textScaler = MediaQuery.textScalerOf(context);
    double lineHeight(TextStyle? style) => textScaler.scale(style?.fontSize ?? 14) * (style?.height ?? 1.2);
    final name = lineHeight(_nameStyle(textTheme));
    final count = math.max(_countIconSize, lineHeight(_countStyle(textTheme)));
    return math.max<double>(60, name + count + 16);
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context).quiz.selection;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground, subdued) = picked
        ? (scheme.primary, scheme.onPrimary, scheme.onPrimary)
        : saved
        ? (scheme.primaryContainer, scheme.onSurface, scheme.onSurfaceVariant)
        : (scheme.surfaceContainerLow, scheme.onSurface, scheme.onSurfaceVariant);
    final memberCount = this.memberCount;

    return Semantics(
      container: true,
      button: true,
      selected: picked,
      enabled: onTap != null,
      label: memberCount == null ? teamId : t.option(team: teamId, count: '$memberCount'),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: picked || saved
              ? BorderSide(color: scheme.primary, width: 2)
              : BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(teamId, style: _nameStyle(theme.textTheme)?.copyWith(color: foreground)),
                if (memberCount != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: _countIconSize, color: subdued),
                      const SizedBox(width: 2),
                      Text('$memberCount', style: _countStyle(theme.textTheme)?.copyWith(color: subdued)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
