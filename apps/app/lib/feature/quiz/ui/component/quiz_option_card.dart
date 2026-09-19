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

/// A〜D のレターバッジ付き選択肢カード。
///
/// 出題中の回答ボタンと正解発表の結果表示を同じ見た目で提供する。
/// バッジの配色は Material 3 スキームのコンテナ色をローテーションし、
/// テーブル内での「A だと思う！」といった声掛けの手掛かりにする。
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

  /// 選択肢の添字。レターバッジ（A〜D）と配色の決定に使う。
  final int index;

  final String label;
  final QuizOptionState state;

  /// カード右下に添える補足（「◯◯ が選択」など）。
  final String? trailingNote;

  final double minHeight;
  final bool enabled;
  final VoidCallback? onTap;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // バッジの色は選択肢ごとに固定（状態で変えない）。
    final badgeColors = [
      (scheme.primaryContainer, scheme.onPrimaryContainer),
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      (scheme.surfaceContainerHighest, scheme.onSurface),
    ];
    final (badgeBackground, badgeForeground) = badgeColors[index % badgeColors.length];

    final (background, foreground, border) = switch (state) {
      QuizOptionState.idle => (scheme.surfaceContainerLow, scheme.onSurface, scheme.outlineVariant),
      QuizOptionState.selected => (scheme.primaryContainer, scheme.onPrimaryContainer, scheme.primary),
      QuizOptionState.correct => (scheme.primaryContainer, scheme.onPrimaryContainer, scheme.primary),
      QuizOptionState.wrongChoice => (scheme.errorContainer, scheme.onErrorContainer, scheme.error),
      QuizOptionState.dimmed => (scheme.surfaceContainerLow, scheme.onSurfaceVariant, scheme.outlineVariant),
    };
    final emphasized = state == QuizOptionState.selected || state == QuizOptionState.correct;

    final trailingIcon = switch (state) {
      QuizOptionState.selected || QuizOptionState.correct => Icon(Icons.check_circle, color: scheme.primary),
      QuizOptionState.wrongChoice => Icon(Icons.cancel, color: scheme.error),
      _ => null,
    };

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: state == QuizOptionState.dimmed ? 0.55 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(minHeight: minHeight),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: emphasized || state == QuizOptionState.wrongChoice ? border : scheme.outlineVariant,
            width: emphasized || state == QuizOptionState.wrongChoice ? 2 : 1,
          ),
          boxShadow: emphasized
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
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
                  // レターバッジ。
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
                        _letters[index % _letters.length],
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
                            fontWeight: emphasized ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (trailingNote != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            trailingNote!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: foreground.withValues(alpha: 0.75),
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
      ),
    );
  }
}
