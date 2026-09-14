import 'package:app/core/i18n/strings.g.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';

/// 自分のチームとテーブル番号を常時示すチップ。
///
/// 出題中・締切・正解発表の各画面の先頭に置き、遅刻して途中から開いた
/// 参加者でも自分のテーブルをいつでも確認できるようにする。
class QuizTeamBadge extends StatelessWidget {
  const QuizTeamBadge({required this.team, super.key});

  final QuizTeam team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.table_restaurant_outlined,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              Translations.of(context).quiz.team.badge(table: '${team.tableNumber}', name: team.name),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
