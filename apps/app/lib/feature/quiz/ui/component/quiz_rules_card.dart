import 'package:app/core/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// 出題前に確認してもらうクイズのルール。
///
/// チーム選択の終了後に初出題を待つ画面と、チーム発表で表示する。
class QuizRulesCard extends StatelessWidget {
  const QuizRulesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rules = Translations.of(context).quiz.rules;
    final items = [
      (
        icon: Icons.groups_outlined,
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
        title: rules.teamAnswerTitle,
        body: rules.teamAnswerBody,
      ),
      (
        icon: Icons.emoji_events_outlined,
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
        title: rules.scoringTitle,
        body: rules.scoringBody,
      ),
      (
        icon: Icons.redeem_outlined,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
        title: rules.sponsorAwardTitle,
        body: rules.sponsorAwardBody,
      ),
    ];
    return Card.outlined(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(rules.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            for (final item in items) ...[
              const SizedBox(height: 14),
              MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, size: 20, color: item.foreground),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(item.body, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
