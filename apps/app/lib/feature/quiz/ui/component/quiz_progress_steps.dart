import 'dart:math' as math;

import 'package:app/core/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// 参加表明からチーム選択までの段階。
enum QuizProgressStep { join, checkIn, selectTeam }

/// 「参加表明 → チェックイン → チーム選択」の進み具合。
///
/// チェックイン画面とチーム選択画面の先頭に置き、いまどの段階かを示す。
/// 丸を線でつないで並べ、段階の名前は丸の下に置く。
/// 完了した段階はチェック、現在の段階は枠付きの番号と太字の名前で表す。
class QuizProgressSteps extends StatelessWidget {
  const QuizProgressSteps({required this.current, super.key});

  final QuizProgressStep current;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context).quiz.progress;
    final scheme = Theme.of(context).colorScheme;
    String label(QuizProgressStep step) => switch (step) {
      QuizProgressStep.join => t.join,
      QuizProgressStep.checkIn => t.checkIn,
      QuizProgressStep.selectTeam => t.selectTeam,
    };
    const steps = QuizProgressStep.values;
    // [from] 段目とその次の段をつなぐ線の色。進んだ区間は primary にする。
    Color lineColor(int from) => from < current.index ? scheme.primary : scheme.outlineVariant;

    return Semantics(
      container: true,
      label: t.semantic(total: steps.length, current: current.index + 1),
      value: label(current),
      child: ExcludeSemantics(
        // 段階ごとに同じ幅を割り当て、名前は丸の下に置く。狭い画面や大きな文字でも
        // 横にはみ出さないよう、名前は割り当てた幅で折り返す。
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final step in steps)
              Expanded(
                child: _Step(
                  number: step.index + 1,
                  label: label(step),
                  done: step.index < current.index,
                  current: step == current,
                  // 丸の左右に、前後の段とつなぐ線を半分ずつ引く。
                  leadingLine: step.index == 0 ? null : lineColor(step.index - 1),
                  trailingLine: step.index == steps.length - 1 ? null : lineColor(step.index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.label,
    required this.done,
    required this.current,
    required this.leadingLine,
    required this.trailingLine,
  });

  final int number;
  final String label;
  final bool done;
  final bool current;

  /// 前の段とつなぐ線の色。最初の段は `null` で線を引かない。
  final Color? leadingLine;

  /// 次の段とつなぐ線の色。最後の段は `null` で線を引かない。
  final Color? trailingLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final numberStyle = theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold);
    // 大きな文字でも番号が縦に切れないよう、丸は拡大後の番号の高さに余白を足した大きさにする（最小 24）。
    final textScaler = MediaQuery.textScalerOf(context);
    final numberHeight = textScaler.scale(numberStyle?.fontSize ?? 12) * (numberStyle?.height ?? 1.2);
    final diameter = math.max<double>(24, numberHeight + 8);

    // 隣の段の線と途切れずにつながるよう、丸の側だけ隙間を空ける。
    Widget line(Color? color, EdgeInsets gap) => Expanded(
      child: color == null
          ? const SizedBox.shrink()
          : Padding(
              padding: gap,
              child: SizedBox(height: 2, child: ColoredBox(color: color)),
            ),
    );

    return Column(
      children: [
        Row(
          children: [
            line(leadingLine, const EdgeInsets.only(right: 4)),
            Container(
              width: diameter,
              height: diameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? scheme.primary
                    : current
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                border: current ? Border.all(color: scheme.primary, width: 2) : null,
              ),
              child: done
                  ? Icon(Icons.check_rounded, size: diameter - 8, color: scheme.onPrimary)
                  : Text(
                      '$number',
                      style: numberStyle?.copyWith(
                        color: current ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                      ),
                    ),
            ),
            line(trailingLine, const EdgeInsets.only(left: 4)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: current ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: current ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
