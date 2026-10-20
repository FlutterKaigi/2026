import 'package:app/core/designsystem/theme/app_gradients.dart';
import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/ui/component/quiz_motion.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 最終結果画面（`event.status == finished`）。
///
/// 先頭で自チームの順位を大きく見せ、スポンサー賞があれば引換券の案内を
/// 添える。その下に上位 3 チームの表彰台と以降のチームの一覧を並べる。
/// 表彰台は 3 位 → 2 位 → 1 位の順にせり上がり、授賞式の高揚感を演出する。
/// 未参加で開いた場合は順位だけを表示する。
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
    final t = Translations.of(context);
    final sorted = _sortedByRank(teams);
    // 自チームは順位一覧と同じ値で見せる（別ストリームの到着差で食い違わないように）。
    final myTeamId = myTeam?.id;
    final mine = myTeamId == null ? null : teams.where((team) => team.id == myTeamId).firstOrNull ?? myTeam;
    final awardSponsorIds = mine?.perfectSponsorIds ?? const <String>[];
    // 同率上位は全員を同じ一覧で表示する。表彰台が代表 1 チームを選んで
    // 残りの同率チームを消してしまわないようにする。
    final topTeams = sorted.where((team) => team.rank != null && team.rank! <= 3).toList();
    final hasTopTie = topTeams.map((team) => team.rank).toSet().length != topTeams.length;
    final podium = hasTopTie ? <QuizTeam>[] : topTeams;
    final rest = sorted.where((team) => !podium.contains(team)).toList();
    // 自チームの結果（順位とスポンサー賞）を見せてから順位の演出を始める。
    final rankingStart = 100 + (mine == null ? 0 : 100) + (awardSponsorIds.isEmpty ? 0 : 100);
    final podiumDone = podium.isEmpty ? rankingStart + 100 : rankingStart + 900 + podium.length * 100;

    return Consumer(
      builder: (context, ref, _) {
        final sponsors = ref.watch(quizSponsorsProvider).value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Entrance(
              child: Row(
                children: [
                  Icon(Icons.emoji_events_outlined, size: 28, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        t.quiz.result.title,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (mine != null) ...[
              const SizedBox(height: 16),
              Entrance(
                delay: const Duration(milliseconds: 100),
                child: _MyTeamHero(team: mine),
              ),
            ],
            if (awardSponsorIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Entrance(
                delay: const Duration(milliseconds: 200),
                child: _SponsorAwardCard(sponsorIds: awardSponsorIds, sponsors: sponsors),
              ),
            ],
            const SizedBox(height: 24),
            Entrance(
              delay: Duration(milliseconds: rankingStart),
              child: Semantics(
                header: true,
                child: Text(
                  t.quiz.result.ranking,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (podium.isNotEmpty) ...[
              _Podium(
                teams: podium,
                myTeamId: myTeamId,
                delay: Duration(milliseconds: rankingStart),
              ),
              const SizedBox(height: 16),
            ],
            for (final (index, team) in rest.indexed)
              Entrance(
                delay: Duration(milliseconds: podiumDone + index * 60),
                offset: const Offset(0, 0.2),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RankTile(team: team, isMine: team.id == myTeamId),
                ),
              ),
            const SizedBox(height: 8),
            Entrance(
              delay: Duration(milliseconds: podiumDone + rest.length * 60),
              child: _TieNote(text: t.quiz.result.tieNote),
            ),
          ],
        );
      },
    );
  }

  /// `rank` 昇順で並べる。`rank` 未確定のチームは末尾に、その中では
  /// スコア降順で並べる。
  List<QuizTeam> _sortedByRank(List<QuizTeam> teams) {
    final sorted = [...teams]
      ..sort((a, b) {
        final ra = a.rank;
        final rb = b.rank;
        if (ra != null && rb != null) {
          final rankComparison = ra.compareTo(rb);
          return rankComparison != 0 ? rankComparison : a.tableNumber.compareTo(b.tableNumber);
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

/// [text] のうち [number] の部分だけを [numberStyle] で表示する。
///
/// 「2位」と「#2」、「60 点」と「60 pts」のように数値の前後が言語で変わるため、
/// 翻訳済みの文字列から数値の位置を探して分ける。見つからなければそのまま表示する。
Widget _emphasizedNumber(String text, String number, {required TextStyle? style, required TextStyle? numberStyle}) {
  final index = text.indexOf(number);
  if (index < 0) {
    return Text(text, style: style);
  }
  return Text.rich(
    TextSpan(
      style: style,
      children: [
        TextSpan(text: text.substring(0, index)),
        TextSpan(text: number, style: numberStyle),
        TextSpan(text: text.substring(index + number.length)),
      ],
    ),
  );
}

/// 自チームの順位と得点。ブランドのグラデーションに黒を重ね、白文字を載せる。
class _MyTeamHero extends StatelessWidget {
  const _MyTeamHero({required this.team});

  final QuizTeam team;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final rank = team.rank;
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.brand),
        // グラデーションのマゼンタ側でも白文字が読めるようにする。
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.quiz.result.yourTeam,
                    style: textTheme.titleSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (rank != null) ...[
                        _emphasizedNumber(
                          t.quiz.result.rank(rank: '$rank'),
                          '$rank',
                          style: textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                          numberStyle: textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: rank != null ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.quiz.result.table(name: team.name),
                              textAlign: rank != null ? TextAlign.end : TextAlign.start,
                              style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            CountUpText(
                              team.score,
                              duration: const Duration(milliseconds: 900),
                              builder: (context, value) => _emphasizedNumber(
                                t.quiz.result.points(score: '$value'),
                                '$value',
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                numberStyle: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 自チームが全問正解したスポンサーの一覧と、景品の引換券の案内。
class _SponsorAwardCard extends StatelessWidget {
  const _SponsorAwardCard({required this.sponsorIds, required this.sponsors});

  final List<String> sponsorIds;
  final List<Sponsor>? sponsors;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.card_giftcard, size: 26, color: scheme.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      t.quiz.result.award.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // カード自体の読み上げは見出しだけにし、本文はそれぞれ別の項目にする。
            // 本文がカードに混ざると、カード全体が見出しとして読まれてしまう。
            for (final sponsorId in sponsorIds)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MergeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        t.quiz.result.award.perfect(sponsor: _sponsorName(context, sponsorId)),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            MergeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: 22, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.quiz.result.award.voucher,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.quiz.result.award.voucherHint,
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

/// 上位 3 チームの表彰台。中央が 1 位で、左右に 2 位・3 位を配置する。
class _Podium extends StatelessWidget {
  const _Podium({required this.teams, required this.myTeamId, required this.delay});

  final List<QuizTeam> teams;
  final String? myTeamId;

  /// せり上がりを始めるまでの待ち時間。
  final Duration delay;

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
                  medalSize: 28,
                  delay: delay + const Duration(milliseconds: 400),
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
                  medalSize: 32,
                  delay: delay + const Duration(milliseconds: 800),
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
                  medalSize: 28,
                  delay: delay,
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
    required this.medalSize,
    required this.delay,
    required this.isMine,
  });

  final QuizTeam team;

  /// 標準の文字の大きさでの台の高さ。文字を大きくするとその分だけ伸びる。
  final double height;
  final Color medalColor;
  final double medalSize;
  final Duration delay;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // 表彰台には順位の決まったチームだけを載せる。
    final rank = team.rank!;
    final (blockColor, onBlockColor) = switch (rank) {
      1 => (scheme.primaryContainer, scheme.onPrimaryContainer),
      2 => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      _ => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };
    final numberStyle = theme.textTheme.headlineMedium?.copyWith(
      color: onBlockColor,
      fontWeight: FontWeight.bold,
    );
    // 文字を大きくした分だけ台を伸ばし、台の中の順位の数字が切れないようにする。
    // どの台も同じだけ伸ばして、台どうしの高さの差（1 位がいちばん高い）は保つ。
    final numberFontSize = numberStyle?.fontSize ?? 28.0;
    final numberGrowth =
        (MediaQuery.textScalerOf(context).scale(numberFontSize) - numberFontSize) * (numberStyle?.height ?? 1.5);

    return Entrance(
      delay: delay,
      duration: const Duration(milliseconds: 450),
      offset: const Offset(0, 0.35),
      child: MergeSemantics(
        // 並びは 2 位・1 位・3 位だが、読み上げは 1 位から順にする。
        // 台の数字の代わりに「1位」を先頭で読ませる。
        child: Semantics(
          sortKey: OrdinalSortKey(rank.toDouble()),
          label: t.quiz.result.rank(rank: '$rank'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMine)
                DecoratedBox(
                  // 文字を大きくして折り返したときも角丸が文字にかからないよう、
                  // 半径は控えめにする（1 行のときは両端が丸くなる）。
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    child: Text(
                      t.quiz.result.yourTeam,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              Icon(Icons.emoji_events, size: medalSize, color: medalColor),
              const SizedBox(height: 2),
              Text(
                t.quiz.result.table(name: team.name),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              CountUpText(
                team.score,
                duration: const Duration(milliseconds: 900),
                builder: (context, value) => Text(
                  t.quiz.result.points(score: '$value'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(minHeight: numberGrowth > 0 ? height + numberGrowth : height),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: isMine ? Border.all(color: scheme.primary, width: 2) : null,
                ),
                child: ExcludeSemantics(
                  child: Text('$rank', style: numberStyle),
                ),
              ),
            ],
          ),
        ),
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
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rank = team.rank;
    final foreground = isMine ? scheme.onPrimaryContainer : null;
    return Card.outlined(
      margin: EdgeInsets.zero,
      color: isMine ? scheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        textColor: foreground,
        // 文字を大きくしても 2 桁の順位が折り返さないよう、幅は中身に合わせて広げる。
        leading: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 28),
          child: Text(
            rank == null ? '-' : '$rank',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: foreground ?? scheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          t.quiz.result.table(name: team.name),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: foreground,
            fontWeight: isMine ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Text(
          t.quiz.result.points(score: '${team.score}'),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: foreground,
            fontWeight: isMine ? FontWeight.bold : FontWeight.normal,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// 同点時の扱いの注記。
class _TieNote extends StatelessWidget {
  const _TieNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color)),
        ),
      ],
    );
  }
}
