import 'package:app/core/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// 選択肢カードの表示状態。
enum QuizOptionState {
  /// 未選択（タップ可能な通常状態）。
  idle,

  /// 自チームが現在選択している。
  selected,

  /// 正解発表で正解として強調する。
  correct,

  /// 正解発表で「自チームの誤答」として強調する。
  wrongChoice,

  /// 正解発表でその他の選択肢を沈める。
  dimmed,
}

/// 1〜4 の番号付き選択肢カード。
///
/// 出題中の回答ボタンと正解発表の結果表示を同じ見た目で提供する。
class QuizOptionCard extends StatelessWidget {
  const QuizOptionCard({
    required this.index,
    required this.label,
    required this.state,
    this.trailingNote,
    this.minHeight = 72,
    this.enabled = true,
    this.onTap,
    super.key,
  });

  /// 選択肢の添字。番号（1〜4）と配色の決定に使う。
  final int index;

  final String label;
  final QuizOptionState state;

  /// カード右下に添える補足（「◯◯ が選択」など）。
  final String? trailingNote;

  final double minHeight;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // バッジの色は選択肢ごとに固定し、沈めた選択肢だけ控えめにする。
    final badgeColors = [
      (scheme.primaryContainer, scheme.onPrimaryContainer),
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      (scheme.surfaceContainerHighest, scheme.onSurface),
    ];
    final (badgeBackground, badgeForeground) = state == QuizOptionState.dimmed
        ? (scheme.surfaceContainerHighest, scheme.onSurfaceVariant)
        : badgeColors[index % badgeColors.length];

    // 沈めた選択肢は、カード全体を透過させず背景と文字の色で控えめにして、文字のコントラストを保つ。
    final (background, foreground, border) = switch (state) {
      QuizOptionState.idle => (scheme.surfaceContainerLow, scheme.onSurface, scheme.outlineVariant),
      QuizOptionState.selected => (scheme.primaryContainer, scheme.onPrimaryContainer, scheme.primary),
      QuizOptionState.correct => (scheme.primaryContainer, scheme.onPrimaryContainer, scheme.primary),
      QuizOptionState.wrongChoice => (scheme.errorContainer, scheme.onErrorContainer, scheme.error),
      QuizOptionState.dimmed => (scheme.surface, scheme.onSurfaceVariant, scheme.outlineVariant),
    };
    final emphasized = state == QuizOptionState.selected || state == QuizOptionState.correct;
    final highlighted = emphasized || state == QuizOptionState.wrongChoice;

    final trailingIcon = switch (state) {
      QuizOptionState.selected || QuizOptionState.correct => Icon(Icons.check_circle, color: scheme.primary),
      QuizOptionState.wrongChoice => Icon(Icons.cancel, color: scheme.error),
      _ => null,
    };

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? border : scheme.outlineVariant,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 選択肢の番号。
                AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  scale: emphasized ? 1.08 : 1,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: badgeBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: badgeForeground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: foreground,
                          fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (trailingNote != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          trailingNote!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    scale: 1,
                    child: trailingIcon,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // 回答ボタンとして使うときは、押せるかどうかと選択中かを読み上げる。
    // 正解発表（表示専用）では、色とアイコンでしか示していない正解・自チームの誤答を値として読み上げる。
    final t = Translations.of(context).quiz.revealed;
    final revealed = switch (state) {
      QuizOptionState.correct => t.correctLabel,
      QuizOptionState.wrongChoice => t.wrongLabel,
      _ => null,
    };
    return Semantics(
      container: true,
      button: onTap != null,
      enabled: onTap == null ? null : enabled,
      selected: onTap == null ? null : state == QuizOptionState.selected,
      value: onTap == null ? revealed : null,
      child: card,
    );
  }
}
