import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 最終結果画面（`event.status == finished`）。
///
/// チームを `rank` 昇順で並べ、上位 3 チームを目立たせる。自チームの順位を
/// 強調し、自チームにパーフェクトスポンサーがあればブース誘導を表示する。
class QuizResultView extends ConsumerWidget {
  const QuizResultView({required this.myTeam, super.key});

  final QuizTeam? myTeam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final teamsAsync = ref.watch(quizTeamsProvider);
    final sponsors = ref.watch(quizSponsorsProvider).value;

    return switch (teamsAsync) {
      AsyncData(:final value) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '最終結果',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          ..._sortedByRank(value).map(
            (team) => _RankTile(
              team: team,
              isMine: team.id == myTeam?.id,
            ),
          ),
          if (myTeam != null) ...[
            const SizedBox(height: 24),
            _MyResultCard(team: myTeam!, sponsors: sponsors),
          ],
        ],
      ),
      AsyncError() => const Center(child: Text('結果の取得に失敗しました')),
      AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
    };
  }

  /// `rank` 昇順で並べる。`rank` 未確定のチームは末尾に、その中では
  /// スコア降順で並べる。
  List<QuizTeam> _sortedByRank(List<QuizTeam> teams) {
    final sorted = [...teams]..sort((a, b) {
      final ra = a.rank;
      final rb = b.rank;
      if (ra != null && rb != null) {
        return ra.compareTo(rb);
      }
      if (ra != null) {
        return -1;
      }
      if (rb != null) {
        return 1;
      }
      return b.score.compareTo(a.score);
    });
    return sorted;
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.team, required this.isMine});

  final QuizTeam team;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rank = team.rank;
    final isTop3 = rank != null && rank <= 3;
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
    return Card(
      color: isMine ? theme.colorScheme.primaryContainer : null,
      elevation: isTop3 ? 3 : 1,
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Center(
            child: medal != null
                ? Text(medal, style: const TextStyle(fontSize: 24))
                : Text(
                    rank == null ? '-' : '$rank',
                    style: theme.textTheme.titleLarge,
                  ),
          ),
        ),
        title: Text(
          team.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isTop3 || isMine ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text('テーブル ${team.tableNumber}'),
        trailing: Text(
          '${team.score} 点',
          style: theme.textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _MyResultCard extends StatelessWidget {
  const _MyResultCard({required this.team, required this.sponsors});

  final QuizTeam team;
  final List<Sponsor>? sponsors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('あなたのチーム', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              team.rank == null ? '${team.name}（${team.score} 点）' : '${team.rank} 位 / ${team.name}（${team.score} 点）',
              style: theme.textTheme.headlineSmall,
            ),
            if (team.perfectSponsorIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final sponsorId in team.perfectSponsorIds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${_sponsorName(sponsorId)} のブースへ景品を受け取りに行こう！',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _sponsorName(String sponsorId) {
    return sponsors
            ?.where((sponsor) => sponsor.id == sponsorId)
            .map((sponsor) => sponsor.name.ja)
            .firstOrNull ??
        sponsorId;
  }
}
