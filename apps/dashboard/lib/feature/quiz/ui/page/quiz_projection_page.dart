import 'dart:math' as math;

import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_check_in_code.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_countdown.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_projection_theme.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_status_label.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 会場投影用の読み取り専用画面。下書き・正解 secret を購読しない。
///
/// チェックインの受付中だけ、会場で配る参加コードと QR コードを表示する。
/// 会場外に出さないため、この画面は配信映像に映さない。
///
/// 1920×1080 のプロジェクターでスクロールせずに読める文字の大きさで組み、この画面だけダーク配色にする。
class QuizProjectionPage extends ConsumerWidget {
  const QuizProjectionPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(quizEventProvider(eventId));
    return Theme(
      data: quizProjectionTheme,
      child: Scaffold(
        body: event.when(
          loading: () => const _ProjectionFrame(child: Center(child: CircularProgressIndicator())),
          error: (_, _) => const _ProjectionFrame(child: _CenteredMessage('接続を確認してください')),
          data: (event) => event == null
              ? const _ProjectionFrame(child: _CenteredMessage('イベントが見つかりません'))
              : _Projection(event: event),
        ),
      ),
    );
  }
}

class _Projection extends ConsumerWidget {
  const _Projection({required this.event});

  final QuizEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = event.title.ja;
    final status = quizProjectionEventStatusLabel(event);
    if (event.status == QuizEventStatus.finished) {
      return _ProjectionFrame(
        title: title,
        status: status,
        child: _ProjectionResult(event: event),
      );
    }
    final currentQuestionId = event.currentQuestionId;
    if (currentQuestionId != null) {
      final question = ref.watch(quizQuestionProvider((eventId: event.id, questionId: currentQuestionId)));
      final questionData = question.asData?.value;
      if (questionData != null && questionData.status != QuizQuestionStatus.draft) {
        return _questionStage(questionData);
      }
      return _ProjectionFrame(
        title: title,
        status: status,
        child: question.hasError
            ? const _CenteredMessage('問題の読み込みに失敗しました。接続を確認してください。')
            : const Center(child: CircularProgressIndicator()),
      );
    }
    final beforeStart = event.status == QuizEventStatus.registration || event.status == QuizEventStatus.entryClosed;
    return _ProjectionFrame(
      title: title,
      status: status,
      child: switch (event.teamSelectionStatus) {
        // 参加コードと QR コードはチェックインの受付中だけ出す。
        QuizTeamSelectionStatus.open when beforeStart => _ProjectionCheckIn(event: event),
        QuizTeamSelectionStatus.closed => _ProjectionBriefing(event: event),
        _ => const _CenteredMessage('チェックインの開始をお待ちください。'),
      },
    );
  }

  /// 読み上げ中から時刻の同期を続け、回答開始と同時に残り時間を出す。
  /// 締切後は同期をやめ、次の問題の読み上げで同期し直す。
  Widget _questionStage(QuizQuestion question) => switch (question.status) {
    QuizQuestionStatus.reading || QuizQuestionStatus.open => QuizCountdown.builder(
      closesAt: question.status == QuizQuestionStatus.open ? question.closesAt : null,
      builder: (context, remaining) => _ProjectionQuestion(event: event, question: question, remaining: remaining),
    ),
    _ => _ProjectionQuestion(event: event, question: question),
  };
}

/// 投影画面の文字。[lineHeight] は1行の高さ（論理ピクセル）。
TextStyle _text(double size, double lineHeight, {FontWeight? weight, Color? color}) =>
    TextStyle(fontSize: size, height: lineHeight / size, fontWeight: weight, color: color);

const _tabularFigures = [FontFeature.tabularFigures()];

/// ブランドのグラデーションのヘッダーと、その下の本文。
class _ProjectionFrame extends StatelessWidget {
  const _ProjectionFrame({this.title, this.status, required this.child});

  final String? title;
  final String? status;
  final Widget child;

  static const _padding = EdgeInsets.symmetric(horizontal: 64, vertical: 48);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectionHeader(title: title, status: status),
        Expanded(
          // 通常の内容は 1920×1080 で収まる大きさにし、長い問題文などで収まらないときだけスクロールする。
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: _padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: math.max(0.0, constraints.maxHeight - _padding.vertical)),
                child: IntrinsicHeight(child: child),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectionHeader extends StatelessWidget {
  const _ProjectionHeader({required this.title, required this.status});

  final String? title;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final status = this.status;
    return SizedBox(
      height: 120,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: quizProjectionBrandGradient),
        // 白い文字がグラデーションの明るい端でも読めるよう、黒16%を重ねる。
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Row(
              children: [
                // 大会名の横に置く飾りなので、読み上げの対象にしない。
                Image.asset('res/assets/shuriken-logo.png', width: 96, height: 96, excludeFromSemantics: true),
                const SizedBox(width: 24),
                if (title != null)
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(40, 48, weight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                if (title != null && status != null) const SizedBox(width: 24),
                if (status != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text(
                        status,
                        style: _text(26, 34, weight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: _text(52, 64, weight: FontWeight.w800),
    ),
  );
}

/// 番号やアイコンの背景に使う配色。
enum _Tone {
  primary,
  secondary,
  tertiary,
  neutral;

  (Color background, Color foreground) colors(ColorScheme scheme) => switch (this) {
    _Tone.primary => (scheme.primaryContainer, scheme.onPrimaryContainer),
    _Tone.secondary => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    _Tone.tertiary => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    _Tone.neutral => (scheme.surfaceContainerHighest, scheme.onSurface),
  };
}

// --- チェックイン受付中 ---

class _ProjectionCheckIn extends ConsumerWidget {
  const _ProjectionCheckIn({required this.event});

  final QuizEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final participants = ref.watch(quizParticipantListProvider(event.id));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 560,
          child: Align(
            alignment: Alignment.topCenter,
            child: QuizCheckInCode(
              eventId: event.id,
              qrSize: 496,
              projection: true,
              codeStyle: _text(120, 128, weight: FontWeight.w800).copyWith(letterSpacing: 20),
            ),
          ),
        ),
        const SizedBox(width: 72),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('チェックインして、チームを選んでください', style: _text(52, 64, weight: FontWeight.w800)),
              const SizedBox(height: 36),
              const _CheckInStep(number: 1, title: 'QR コードを読み取る', description: '読み取れないときは、アプリで参加コードを入力'),
              const SizedBox(height: 24),
              const _CheckInStep(number: 2, title: '案内されたテーブルに着席する', description: 'スタッフがテーブルをご案内します'),
              const SizedBox(height: 24),
              const _CheckInStep(number: 3, title: 'アプリでチームを選ぶ', description: 'テーブルに表示されたチーム（A〜T）'),
              // 参加受付の再開中は、当日参加の人に先に参加表明してもらう。
              if (event.status == QuizEventStatus.registration) ...[
                const SizedBox(height: 28),
                Card.filled(
                  margin: EdgeInsets.zero,
                  color: scheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Text(
                      'まだ参加表明していない方は、先にアプリで「参加する」を押してください',
                      style: _text(26, 36, weight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              const SizedBox(height: 24),
              participants.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => Text(
                  '参加者の読み込みに失敗しました。接続を確認してください。',
                  style: _text(26, 34, color: scheme.onSurfaceVariant),
                ),
                data: (participants) => _CheckInProgress(participants: participants),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckInStep extends StatelessWidget {
  const _CheckInStep({required this.number, required this.title, required this.description});

  final int number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Text('$number', style: _text(36, 44, weight: FontWeight.w800)),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _text(36, 48, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(description, style: _text(24, 32, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

/// チェックインとチーム選択の進み具合。参加者の名前や UID は会場に出さず、人数だけを出す。
class _CheckInProgress extends StatelessWidget {
  const _CheckInProgress({required this.participants});

  final List<QuizParticipant> participants;

  @override
  Widget build(BuildContext context) {
    final checkedIn = participants.where((person) => person.checkedInAt != null).length;
    final selected = participants.where((person) => person.teamId != null).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            _CountText(spans: ['チェックイン ', '$checkedIn', ' / 登録 ${participants.length} 人'], numberSize: 56),
            const SizedBox(width: 48),
            _CountText(spans: ['チーム選択 ', '$selected', ' 人'], numberSize: 56),
          ],
        ),
        const SizedBox(height: 20),
        _TeamTiles(
          counts: {
            for (final id in quizTeamIds) id: participants.where((person) => person.teamId == id).length,
          },
        ),
      ],
    );
  }
}

/// 説明と大きな数字を交互に並べた1行。[spans] の奇数番目を数字として強調する。
class _CountText extends StatelessWidget {
  const _CountText({required this.spans, required this.numberSize});

  final List<String> spans;
  final double numberSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final number = _text(
      numberSize,
      numberSize + 8,
      weight: FontWeight.w800,
      color: scheme.primary,
    ).copyWith(fontFeatures: _tabularFigures);
    return Text.rich(
      TextSpan(
        style: _text(26, 34, color: scheme.onSurfaceVariant),
        children: [
          for (final (index, text) in spans.indexed) TextSpan(text: text, style: index.isOdd ? number : null),
        ],
      ),
    );
  }
}

/// A〜T のチームごとの人数。0人のチームは薄く表示する。
class _TeamTiles extends StatelessWidget {
  const _TeamTiles({required this.counts});

  final Map<String, int> counts;

  static const _perRow = 10;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var start = 0; start < quizTeamIds.length; start += _perRow) ...[
          if (start > 0) const SizedBox(height: 12),
          Row(
            children: [
              for (final (index, id) in quizTeamIds.skip(start).take(_perRow).indexed) ...[
                if (index > 0) const SizedBox(width: 12),
                Expanded(
                  child: _TeamTile(id: id, count: counts[id] ?? 0),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({required this.id, required this.count});

  final String id;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = count > 0;
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: filled ? scheme.surfaceContainerHigh : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: filled ? scheme.outline : scheme.surfaceContainerHighest, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              id,
              style: _text(30, 36, weight: FontWeight.w800, color: filled ? scheme.onSurface : scheme.outline),
            ),
            if (filled) ...[
              const SizedBox(width: 8),
              Text(
                '$count人',
                style: _text(20, 28, weight: FontWeight.w700, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- チェックイン終了後の出題待ち ---

class _ProjectionBriefing extends ConsumerWidget {
  const _ProjectionBriefing({required this.event});

  final QuizEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final teams = ref.watch(quizTeamListProvider(event.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('クイズのルール', style: _text(52, 64, weight: FontWeight.w800)),
        const SizedBox(height: 32),
        const _RuleRow(
          first: _RuleCard(
            tone: _Tone.primary,
            leading: Icon(Icons.groups_outlined),
            title: '回答はチームで1つ',
            description: '締切までチームの誰でも変更できます。最後に受理された回答が採用されます',
          ),
          second: _RuleCard(
            tone: _Tone.tertiary,
            leading: Icon(Icons.emoji_events_outlined),
            title: '1問10点',
            description: '同点のチームは同じ順位です',
          ),
        ),
        const SizedBox(height: 24),
        const _RuleRow(
          first: _RuleCard(
            tone: _Tone.neutral,
            leading: Text('1–4'),
            title: '選択肢は 1〜4 の番号',
            description: 'アプリで選択肢をタップすると、チームの回答になります',
          ),
          second: _RuleCard(
            tone: _Tone.secondary,
            leading: Icon(Icons.redeem_outlined),
            title: 'スポンサー賞',
            description: '同じスポンサーの問題にすべて正解したチームが対象です',
          ),
        ),
        const Spacer(),
        const SizedBox(height: 24),
        teams.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => Text(
            'チームの読み込みに失敗しました。接続を確認してください。',
            style: _text(26, 34, color: scheme.onSurfaceVariant),
          ),
          data: (teams) => _BriefingTeams(teams: teams),
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: first),
        const SizedBox(width: 24),
        Expanded(child: second),
      ],
    ),
  );
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.tone, required this.leading, required this.title, required this.description});

  final _Tone tone;
  final Widget leading;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = tone.colors(scheme);
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(24)),
              child: IconTheme.merge(
                data: IconThemeData(size: 44, color: foreground),
                child: DefaultTextStyle.merge(
                  style: _text(34, 40, weight: FontWeight.w800, color: foreground),
                  child: leading,
                ),
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _text(36, 48, weight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(description, style: _text(26, 38, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BriefingTeams extends StatelessWidget {
  const _BriefingTeams({required this.teams});

  final List<QuizTeam> teams;

  @override
  Widget build(BuildContext context) {
    final counts = {for (final team in teams) team.id: team.memberUids.length};
    final teamCount = counts.values.where((count) => count > 0).length;
    final people = counts.values.fold<int>(0, (sum, count) => sum + count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text('参加チーム', style: _text(32, 44, weight: FontWeight.w800)),
            ),
            _CountText(spans: ['', '$teamCount', ' チーム · ', '$people', ' 人'], numberSize: 44),
          ],
        ),
        const SizedBox(height: 16),
        _TeamTiles(counts: counts),
      ],
    );
  }
}

// --- 出題中 ---

class _ProjectionQuestion extends ConsumerWidget {
  const _ProjectionQuestion({required this.event, required this.question, this.remaining});

  final QuizEvent event;
  final QuizQuestion question;

  /// 読み上げ中・回答受付中の残り時間。締切後は `null`。
  final QuizRemaining? remaining;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final sponsor = _sponsorName(ref.watch(quizSponsorListProvider).asData?.value, question.sponsorId);
    final expired = question.status == QuizQuestionStatus.open && remaining?.seconds == 0;
    // 正解と解説は正解発表のときだけ出す。
    final revealed = question.status == QuizQuestionStatus.revealed;
    final correctIndex = revealed ? question.correctOptionIndex : null;
    final correct = correctIndex != null && correctIndex >= 0 && correctIndex < question.options.length
        ? correctIndex
        : null;
    final explanation = revealed ? question.explanation : null;
    return _ProjectionFrame(
      title: event.title.ja,
      status: quizProjectionQuestionStatusLabel(question.status, expired: expired),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '第 ${question.order} 問',
                      style: _text(32, 40, weight: FontWeight.w800, color: scheme.primary),
                    ),
                    if (sponsor != null) ...[
                      const SizedBox(width: 24),
                      Flexible(
                        child: Text(
                          '$sponsor の問題',
                          style: _text(26, 34, weight: FontWeight.w700, color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text(question.title.ja, style: _text(52, 68, weight: FontWeight.w800)),
                if (question.title.en.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(question.title.en, style: _text(28, 38, color: scheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 32),
                _OptionGrid(options: question.options, correctIndex: correct),
                if (explanation != null && (explanation.ja.isNotEmpty || explanation.en.isNotEmpty)) ...[
                  const SizedBox(height: 28),
                  _Explanation(explanation: explanation),
                ],
              ],
            ),
          ),
          const SizedBox(width: 56),
          SizedBox(
            width: 440,
            child: _QuestionPanel(question: question, remaining: remaining, expired: expired, correctIndex: correct),
          ),
        ],
      ),
    );
  }
}

/// 選択肢を 2 列に並べる。参加者アプリと同じく番号は 1〜4（テーブルの A〜T と混ざらないように）。
class _OptionGrid extends StatelessWidget {
  const _OptionGrid({required this.options, required this.correctIndex});

  final List<LocaleMap> options;
  final int? correctIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var row = 0; row < options.length; row += 2) ...[
          if (row > 0) const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final index in [row, row + 1]) ...[
                  if (index > row) const SizedBox(width: 24),
                  Expanded(
                    child: index < options.length
                        ? _OptionCard(index: index, option: options[index], correctIndex: correctIndex)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.index, required this.option, required this.correctIndex});

  final int index;
  final LocaleMap option;
  final int? correctIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final correct = correctIndex == index;
    // 正解発表後の不正解の選択肢は、背景と番号の色を控えめにする。
    // プロジェクターでも読めるよう、カード全体は透過させず文字のコントラストを保つ。
    final dimmed = correctIndex != null && !correct;
    final (badgeBackground, badgeForeground) = correct
        ? (scheme.primary, scheme.onPrimary)
        : dimmed
        ? (scheme.surfaceContainerHighest, scheme.onSurfaceVariant)
        : _Tone.values[index % _Tone.values.length].colors(scheme);
    return Card.outlined(
      margin: EdgeInsets.zero,
      color: correct ? scheme.primaryContainer : (dimmed ? scheme.surface : scheme.surfaceContainer),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: correct ? scheme.primary : scheme.outlineVariant, width: correct ? 4 : 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 140),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: badgeBackground,
                foregroundColor: badgeForeground,
                child: Text('${index + 1}', style: _text(40, 48, weight: FontWeight.w800)),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.ja,
                      style: _text(44, 56, weight: FontWeight.w700, color: dimmed ? scheme.onSurfaceVariant : null),
                    ),
                    if (option.en.isNotEmpty)
                      Text(option.en, style: _text(26, 34, color: dimmed ? scheme.outline : scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (correct) ...[
                const SizedBox(width: 16),
                Icon(Icons.check_circle, size: 56, color: scheme.primary, semanticLabel: '正解'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({required this.explanation});

  final LocaleMap explanation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, size: 44, color: scheme.tertiary),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (explanation.ja.isNotEmpty) Text(explanation.ja, style: _text(30, 42)),
                  if (explanation.ja.isNotEmpty && explanation.en.isNotEmpty) const SizedBox(height: 6),
                  if (explanation.en.isNotEmpty)
                    Text(explanation.en, style: _text(22, 32, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 右側のパネル。読み上げ中・残り時間・締切・正解を切り替える。
class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel({
    required this.question,
    required this.remaining,
    required this.expired,
    required this.correctIndex,
  });

  final QuizQuestion question;
  final QuizRemaining? remaining;
  final bool expired;
  final int? correctIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget content = switch ((question.status, correctIndex)) {
      (QuizQuestionStatus.draft || QuizQuestionStatus.reading, _) => _PanelMessage(
        icon: Icons.volume_up_outlined,
        color: scheme.primary,
        title: '読み上げ中',
        description: '回答開始までお待ちください',
      ),
      (QuizQuestionStatus.open, _) when !expired => _RemainingTime(
        question: question,
        remaining: remaining ?? (seconds: null, failed: false),
      ),
      // 回答受付中のまま締切を過ぎたら、サーバーも回答を受け付けない。
      (QuizQuestionStatus.open || QuizQuestionStatus.closed, _) => _PanelMessage(
        icon: Icons.timer_off_outlined,
        color: scheme.error,
        title: '回答締切',
        description: '正解発表をお待ちください',
        large: true,
      ),
      (QuizQuestionStatus.revealed, final int index) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '正解',
            style: _text(36, 44, weight: FontWeight.w800, color: scheme.primary),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 100,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: Text('${index + 1}', style: _text(120, 132, weight: FontWeight.w800)),
          ),
          const SizedBox(height: 20),
          Text(
            question.options[index].ja,
            textAlign: TextAlign.center,
            style: _text(48, 60, weight: FontWeight.w800),
          ),
        ],
      ),
      (QuizQuestionStatus.revealed, null) => Text('正解発表', style: _text(48, 60, weight: FontWeight.w800)),
    };
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: content),
      ),
    );
  }
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.large = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 96, color: color),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: large ? _text(56, 68, weight: FontWeight.w800) : _text(48, 60, weight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        // 説明はパネルの幅（360）の1行に収まる大きさにする。
        Text(
          description,
          textAlign: TextAlign.center,
          style: _text(large ? 28 : 26, large ? 38 : 36, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// サーバー同期後の残り時間。残り10秒以下は警告色にする。
class _RemainingTime extends StatelessWidget {
  const _RemainingTime({required this.question, required this.remaining});

  final QuizQuestion question;
  final QuizRemaining remaining;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final seconds = remaining.seconds;
    final color = seconds != null && seconds <= 10 ? scheme.error : scheme.primary;
    final openedAt = question.openedAt;
    final closesAt = question.closesAt;
    // 延長しても回答開始の時刻は変わらないため、回答開始から締切までを全体の長さにする。
    final total = openedAt != null && closesAt != null
        ? closesAt.difference(openedAt).inSeconds
        : question.durationSeconds;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (seconds == null)
          Text(
            quizProjectionClockMessage(remaining),
            textAlign: TextAlign.center,
            style: _text(36, 48, weight: FontWeight.w700),
          )
        else ...[
          Text(
            '残り',
            textAlign: TextAlign.center,
            style: _text(32, 40, weight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              quizRemainingText(seconds),
              style: _text(140, 148, weight: FontWeight.w800, color: color).copyWith(fontFeatures: _tabularFigures),
            ),
          ),
          const SizedBox(height: 32),
          LinearProgressIndicator(
            value: (seconds / math.max(total, 1)).clamp(0.0, 1.0),
            minHeight: 16,
            borderRadius: BorderRadius.circular(8),
            color: color,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ],
        const SizedBox(height: 32),
        Text(
          'アプリで選択肢をタップして回答',
          textAlign: TextAlign.center,
          style: _text(22, 32, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// --- 結果発表 ---

class _ProjectionResult extends ConsumerWidget {
  const _ProjectionResult({required this.event});

  final QuizEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sponsors = ref.watch(quizSponsorListProvider).asData?.value;
    return ref
        .watch(quizTeamListProvider(event.id))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _CenteredMessage('チームの読み込みに失敗しました。接続を確認してください。'),
          data: (teams) {
            // メンバーのいないチームには順位も賞もないため出さない。
            final ranked =
                [
                  for (final team in teams)
                    if (team.memberUids.isNotEmpty) team,
                ]..sort((a, b) {
                  final score = b.score.compareTo(a.score);
                  return score != 0 ? score : a.tableNumber.compareTo(b.tableNumber);
                });
            final podium = _podium(ranked);
            final rest = podium == null ? ranked : ranked.sublist(podium.length);
            // チームが多いときは表彰台を低くし、1920×1080 に収める。
            final compact = rest.length > 9;
            // 名前を引けたスポンサーの賞があるときだけ欄を出す（空の枠と引換券の案内だけを映さない）。
            final awards = _sponsorAwards(event, ranked, sponsors);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (podium != null) ...[
                        _Podium(teams: podium, compact: compact),
                        SizedBox(height: compact ? 24 : 32),
                      ],
                      _RankList(teams: rest, compact: compact),
                      const Spacer(),
                      const SizedBox(height: 24),
                      const _TieNote(),
                    ],
                  ),
                ),
                if (awards.isNotEmpty) ...[
                  const SizedBox(width: 56),
                  SizedBox(width: 560, child: _SponsorAwards(awards: awards)),
                ],
              ],
            );
          },
        );
  }
}

/// 表彰台に載せる上位3チーム（1位・2位・3位の順）。
///
/// 上位3位に同率のチームがいるときは、入賞チームを会場で決めるため表彰台を出さない。
List<QuizTeam>? _podium(List<QuizTeam> ranked) {
  if (ranked.length < 3) return null;
  final [first, second, third, ...] = ranked;
  final distinct = first.score > second.score && second.score > third.score;
  final tiedWithFourth = ranked.length > 3 && ranked[3].score == third.score;
  return distinct && !tiedWithFourth ? [first, second, third] : null;
}

class _Podium extends StatelessWidget {
  const _Podium({required this.teams, required this.compact});

  final List<QuizTeam> teams;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PodiumStep(team: teams[1], place: 2, tone: _Tone.secondary, compact: compact),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _PodiumStep(team: teams[0], place: 1, tone: _Tone.primary, compact: compact),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _PodiumStep(team: teams[2], place: 3, tone: _Tone.tertiary, compact: compact),
        ),
      ],
    );
  }
}

class _PodiumStep extends StatelessWidget {
  const _PodiumStep({required this.team, required this.place, required this.tone, required this.compact});

  final QuizTeam team;
  final int place;
  final _Tone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = tone.colors(scheme);
    final first = place == 1;
    // 台の高さは最小値。文字を大きくしたときは順位の数字に合わせて伸ばす。
    final height = switch ((place, compact)) {
      (1, false) => 240.0,
      (2, false) => 180.0,
      (_, false) => 130.0,
      (1, true) => 140.0,
      (2, true) => 108.0,
      (_, true) => 84.0,
    };
    // トロフィーは金・銀・銅のメダルの色にする（台の色はテーマ色）。
    final trophy = switch (place) {
      1 => const Color(0xFFF9A825),
      2 => const Color(0xFFBDBDBD),
      _ => const Color(0xFFA1887F),
    };
    return Column(
      children: [
        Icon(Icons.emoji_events, size: compact ? (first ? 56 : 48) : (first ? 80 : 64), color: trophy),
        const SizedBox(height: 8),
        Text(
          'チーム ${team.name}',
          textAlign: TextAlign.center,
          style: first ? _text(48, 56, weight: FontWeight.w800) : _text(40, 48, weight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '${team.score} 点',
          style: (first ? _text(36, 44, weight: FontWeight.w800) : _text(32, 40, weight: FontWeight.w800)).copyWith(
            color: scheme.primary,
            fontFeatures: _tabularFigures,
          ),
        ),
        SizedBox(height: compact ? 12 : 16),
        Container(
          constraints: BoxConstraints(minHeight: height),
          width: double.infinity,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Text(
            '$place',
            style: switch ((first, compact)) {
              (true, false) => _text(88, 96, weight: FontWeight.w800, color: foreground),
              (false, false) => _text(72, 80, weight: FontWeight.w800, color: foreground),
              (true, true) => _text(72, 80, weight: FontWeight.w800, color: foreground),
              (false, true) => _text(56, 64, weight: FontWeight.w800, color: foreground),
            },
          ),
        ),
      ],
    );
  }
}

/// 表彰台に載らないチーム（同率のときは全チーム）を3列で並べる。
///
/// 列を縦に読むと順位が続くよう、各列に上から下へ並べる。
class _RankList extends StatelessWidget {
  const _RankList({required this.teams, required this.compact});

  final List<QuizTeam> teams;
  final bool compact;

  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    // 1列の件数。1列目に先頭のこの件数、2列目に次の件数…と入れる。
    final rows = (teams.length + _columns - 1) ~/ _columns;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var row = 0; row < rows; row++) ...[
          if (row > 0) SizedBox(height: compact ? 10 : 12),
          Row(
            children: [
              for (var column = 0; column < _columns; column++) ...[
                if (column > 0) const SizedBox(width: 24),
                Expanded(
                  child: switch (teams.elementAtOrNull(column * rows + row)) {
                    final team? => _RankRow(team: team, minHeight: compact ? 56 : 64),
                    null => const SizedBox.shrink(),
                  },
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.team, required this.minHeight});

  final QuizTeam team;

  /// 行の最小の高さ。文字を大きくしたときは内容に合わせて伸ばす。
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Card.filled(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  '${team.rank ?? '-'} 位',
                  style: _text(26, 34, weight: FontWeight.w800, color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  'チーム ${team.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(30, 38, weight: FontWeight.w700),
                ),
              ),
              Text(
                '${team.score} 点',
                style: _text(28, 36, weight: FontWeight.w700).copyWith(fontFeatures: _tabularFigures),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TieNote extends StatelessWidget {
  const _TieNote();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(Icons.info_outline, size: 28, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text('同点の場合の入賞チームの決め方は会場でご案内します', style: _text(26, 36, color: color)),
        ),
      ],
    );
  }
}

typedef _SponsorAward = ({String sponsor, List<QuizTeam> teams});

/// スポンサー賞の受賞チームをスポンサーごとにまとめる。
///
/// 並びは大会のスポンサー設定の順。名前を引けないスポンサーは、ID を会場に出さないよう省く。
List<_SponsorAward> _sponsorAwards(QuizEvent event, List<QuizTeam> ranked, List<Sponsor>? sponsors) {
  final ids = {for (final team in ranked) ...team.perfectSponsorIds};
  final ordered = [
    ...event.sponsorIds.where(ids.contains),
    ...ids.where((id) => !event.sponsorIds.contains(id)),
  ];
  return [
    for (final id in ordered)
      if (_sponsorName(sponsors, id) case final name?)
        (
          sponsor: name,
          teams: [
            for (final team in ranked)
              if (team.perfectSponsorIds.contains(id)) team,
          ],
        ),
  ];
}

class _SponsorAwards extends StatelessWidget {
  const _SponsorAwards({required this.awards});

  final List<_SponsorAward> awards;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(color: scheme.primary, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(20)),
                  child: Icon(Icons.redeem_outlined, size: 40, color: scheme.onPrimary),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text('スポンサー賞', style: _text(44, 56, weight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('同じスポンサーの問題にすべて正解したチーム', style: _text(22, 32, color: scheme.onSurfaceVariant)),
            for (final (index, award) in awards.indexed) ...[
              SizedBox(height: index == 0 ? 28 : 24),
              Text(award.sponsor, style: _text(30, 40, weight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final team in award.teams)
                    Chip(
                      label: Text('チーム ${team.name}'),
                      labelStyle: _text(26, 36, weight: FontWeight.w700, color: scheme.onPrimaryContainer),
                      backgroundColor: scheme.primaryContainer,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    ),
                ],
              ),
            ],
            const Spacer(),
            const SizedBox(height: 24),
            // 2社分を受賞したチームがいても、引換券の案内は1回だけ出す。
            Card.filled(
              margin: EdgeInsets.zero,
              color: scheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 36, color: scheme.onPrimaryContainer),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 語の途中で折り返さないよう、改行の位置を決めておく。
                          Text(
                            '景品の引換券は\n運営スタッフからお渡しします',
                            style: _text(26, 36, weight: FontWeight.w800, color: scheme.onPrimaryContainer),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '会場のスタッフの案内をお待ちください',
                            style: _text(20, 30, color: scheme.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// スポンサーの表示名。引けないときは、ID を会場に出さないよう `null` を返す。
String? _sponsorName(List<Sponsor>? sponsors, String sponsorId) {
  final sponsor = sponsors?.where((sponsor) => sponsor.id == sponsorId).firstOrNull;
  if (sponsor == null) return null;
  final name = sponsor.name.ja.isEmpty ? sponsor.name.en : sponsor.name.ja;
  return name.isEmpty ? null : name;
}
