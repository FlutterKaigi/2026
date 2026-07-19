import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/ui/component/quiz_motion.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 最終結果画面（`event.status == finished`）。
///
/// 上位 3 チームを表彰台で見せ、以降のチームはリストで表示する。
/// 表彰台は 3 位 → 2 位 → 1 位の順にせり上がり、授賞式の高揚感を演出する。
/// 自チームは常にハイライトし、パーフェクトスポンサーがあればブース誘導を
/// 表示する。
class QuizResultView extends ConsumerWidget {
  const QuizResultView({required this.myTeam, super.key});

  final QuizTeam? myTeam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final teamsAsync = ref.watch(quizTeamsProvider);

    return switch (teamsAsync) {
      AsyncData(:final value) => _buildBody(context, theme, value),
      AsyncError() => Center(child: Text(Translations.of(context).quiz.result.error)),
      AsyncLoading() => const Center(child: CircularProgressIndicator.adaptive()),
    };
  }

  Widget _buildBody(BuildContext context, ThemeData theme, List<QuizTeam> teams) {
    final sorted = _sortedByRank(teams);
    // 順位確定済みの上位 3 チームだけを表彰台に載せる。
    final podium = sorted.where((team) => team.rank != null && team.rank! <= 3).toList();
    final rest = sorted.where((team) => !podium.contains(team)).toList();
    final podiumDone = 900 + podium.length * 100;

    return Consumer(
      builder: (context, ref, _) {
        final sponsors = ref.watch(quizSponsorsProvider).value;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Entrance(
              child: Column(
                children: [
                  Icon(Icons.emoji_events, size: 40, color: theme.colorScheme.primary),
                  const SizedBox(height: 4),
                  Text(
                    Translations.of(context).quiz.result.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (podium.isNotEmpty) ...[
              _Podium(teams: podium, myTeamId: myTeam?.id),
              const SizedBox(height: 24),
            ],
            for (final (index, team) in rest.indexed)
              Entrance(
                delay: Duration(milliseconds: podiumDone + index * 60),
                offset: const Offset(0, 0.2),
                child: _RankTile(team: team, isMine: team.id == myTeam?.id),
              ),
            if (myTeam != null) ...[
              const SizedBox(height: 24),
              Entrance(
                delay: Duration(milliseconds: podiumDone + rest.length * 60 + 150),
                child: _MyResultCard(team: myTeam!, sponsors: sponsors),
              ),
            ],
          ],
        );
      },
    );
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

/// 上位 3 チームの表彰台。中央が 1 位で、左右に 2 位・3 位を配置する。
class _Podium extends StatelessWidget {
  const _Podium({required this.teams, required this.myTeamId});

  final List<QuizTeam> teams;
  final String? myTeamId;

  @override
  Widget build(BuildContext context) {
    QuizTeam? byRank(int rank) => teams.where((team) => team.rank == rank).firstOrNull;
    final first = byRank(1);
    final second = byRank(2);
    final third = byRank(3);

    // 3 位 → 2 位 → 1 位の順に登場させる（授賞式と同じ流れ）。
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: second == null
              ? const SizedBox.shrink()
              : _PodiumColumn(
                  team: second,
                  height: 84,
                  // 銀メダル相当の色。絵文字はアプリのフォント設定で豆腐に
                  // なるため Material アイコン + メダル色で表現する。
                  medalColor: const Color(0xFF9E9E9E),
                  delay: const Duration(milliseconds: 400),
                  isMine: second.id == myTeamId,
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: first == null
              ? const SizedBox.shrink()
              : _PodiumColumn(
                  team: first,
                  height: 116,
                  medalColor: const Color(0xFFF9A825),
                  delay: const Duration(milliseconds: 800),
                  isMine: first.id == myTeamId,
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: third == null
              ? const SizedBox.shrink()
              : _PodiumColumn(
                  team: third,
                  height: 64,
                  medalColor: const Color(0xFF8D6E63),
                  delay: Duration.zero,
                  isMine: third.id == myTeamId,
                ),
        ),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.team,
    required this.height,
    required this.medalColor,
    required this.delay,
    required this.isMine,
  });

  final QuizTeam team;
  final double height;
  final Color medalColor;
  final Duration delay;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (blockColor, onBlockColor) = switch (team.rank) {
      1 => (scheme.primaryContainer, scheme.onPrimaryContainer),
      2 => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      _ => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };

    return Entrance(
      delay: delay,
      duration: const Duration(milliseconds: 450),
      offset: const Offset(0, 0.35),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 32, color: medalColor),
          const SizedBox(height: 4),
          Text(
            team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            Translations.of(context).quiz.result.table(table: '${team.tableNumber}'),
            style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          CountUpText(
            team.score,
            duration: const Duration(milliseconds: 900),
            builder: (context, value) => Text(
              Translations.of(context).quiz.result.points(score: '$value'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: isMine ? Border.all(color: scheme.primary, width: 2) : null,
            ),
            child: Text(
              '${team.rank}',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: onBlockColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
    return Card(
      color: isMine ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Center(
            child: Text(
              rank == null ? '-' : '$rank',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          team.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isMine ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(Translations.of(context).quiz.result.table(table: '${team.tableNumber}')),
        trailing: Text(
          Translations.of(context).quiz.result.points(score: '${team.score}'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
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
    final t = Translations.of(context);
    return Card.filled(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.quiz.result.yourTeam,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              team.rank == null
                  ? t.quiz.result.yourTeamUnranked(name: team.name, score: '${team.score}')
                  : t.quiz.result.yourTeamRanked(
                      rank: '${team.rank}',
                      name: team.name,
                      score: '${team.score}',
                    ),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (team.perfectSponsorIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final sponsorId in team.perfectSponsorIds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.card_giftcard, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.quiz.result.perfect(sponsor: _sponsorName(context, sponsorId)),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
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

  String _sponsorName(BuildContext context, String sponsorId) {
    final locale = Localizations.localeOf(context);
    return sponsors
            ?.where((sponsor) => sponsor.id == sponsorId)
            .map((sponsor) => sponsor.name.resolve(locale))
            .firstOrNull ??
        sponsorId;
  }
}
