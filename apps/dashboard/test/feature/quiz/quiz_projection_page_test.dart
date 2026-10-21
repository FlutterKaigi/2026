import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_list_state.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_countdown.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_projection_theme.dart';
import 'package:dashboard/feature/quiz/ui/page/quiz_projection_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show Override;
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  final event = QuizEvent(
    id: 'event',
    title: const LocaleMap(ja: 'クイズ大会 前半戦', en: 'Quiz'),
    status: QuizEventStatus.inProgress,
    currentQuestionId: 'question',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  const question = QuizQuestion(
    id: 'question',
    sponsorId: 'sponsor',
    order: 1,
    title: LocaleMap(ja: '公開の問題', en: 'Question'),
    options: [
      LocaleMap(ja: '○', en: 'True'),
      LocaleMap(ja: '×', en: 'False'),
    ],
    status: QuizQuestionStatus.reading,
    // Even an accidentally present public answer is hidden before reveal.
    correctOptionIndex: 1,
    explanation: LocaleMap(ja: 'まだ秘密の解説', en: 'Private explanation'),
  );
  Sponsor sponsor(String id, String name) => Sponsor(
    id: id,
    name: LocaleMap(ja: name, en: name),
    description: const LocaleMap(ja: '', en: ''),
    tier: SponsorTier.gold,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Future<void> showProjection(WidgetTester tester, List<Override> overrides) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: overrides,
        child: const MaterialApp(home: QuizProjectionPage(eventId: 'event')),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<Override> questionOverrides(QuizQuestion value, {QuizClockRepository? clock}) => [
    quizClockRepositoryProvider.overrideWithValue(clock ?? _Clock()),
    quizEventProvider('event').overrideWith((_) => Stream.value(event)),
    quizQuestionProvider((eventId: 'event', questionId: 'question')).overrideWith((_) => Stream.value(value)),
    quizSponsorListProvider.overrideWith((_) => Stream.value([sponsor('sponsor', 'テストスポンサー')])),
  ];

  testWidgets('reading projection shows numbered options without code, answer, countdown, or secrets', (tester) async {
    var readsSecret = false;
    var readsQuestionList = false;
    await showProjection(tester, [
      ...questionOverrides(question),
      quizQuestionSecretProvider((eventId: 'event', questionId: 'question')).overrideWith((_) {
        readsSecret = true;
        return const Stream.empty();
      }),
      quizQuestionListProvider('event').overrideWith((_) {
        readsQuestionList = true;
        return const Stream.empty();
      }),
      quizCheckInCodeProvider('event').overrideWith((_) => Stream.value('123456')),
    ]);
    expect(readsSecret, isFalse, reason: 'Projection must not read secrets');
    expect(readsQuestionList, isFalse, reason: 'Projection must not read drafts');
    expect(find.text('クイズ大会 前半戦'), findsOneWidget);
    expect(find.text('FlutterKaigi クイズ大会'), findsNothing);
    expect(find.text('第 1 問'), findsOneWidget);
    expect(find.text('テストスポンサー の問題'), findsOneWidget);
    expect(find.text('公開の問題'), findsOneWidget);
    expect(find.text('Question'), findsOneWidget);
    for (final (number, ja, en) in [('1', '○', 'True'), ('2', '×', 'False')]) {
      expect(find.text(number), findsOneWidget);
      expect(find.text(ja), findsOneWidget);
      expect(find.text(en), findsOneWidget);
    }
    // Options are numbered so they never mix with the A–T team tables.
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);
    expect(find.text('まだ秘密の解説'), findsNothing);
    expect(find.text('正解'), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.textContaining('残り'), findsNothing);
    expect(find.text('読み上げ中'), findsNWidgets(2), reason: 'The status pill and the side panel');
    expect(find.text('回答開始までお待ちください'), findsOneWidget);
    expect(find.text('123456'), findsNothing);
    expect(find.byType(QrImageView), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a question without a known sponsor never shows the sponsor ID', (tester) async {
    await showProjection(tester, questionOverrides(question.copyWith(sponsorId: 'sponsor-id-only')));
    expect(find.text('第 1 問'), findsOneWidget);
    expect(find.textContaining(' の問題'), findsNothing);
    expect(find.textContaining('sponsor-id-only'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('open question counts down with the server clock and warns in the last 10 seconds', (tester) async {
    QuizQuestion open(int seconds) => question.copyWith(
      status: QuizQuestionStatus.open,
      durationSeconds: 180,
      closesAt: DateTime(2026).add(Duration(seconds: seconds)),
    );
    await showProjection(tester, questionOverrides(open(90)));
    expect(find.text('回答受付中'), findsOneWidget);
    expect(find.text('残り'), findsOneWidget);
    expect(find.text('1:30'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.5);
    expect(tester.widget<Text>(find.text('1:30')).style?.color, quizProjectionColorScheme.primary);
    expect(find.text('まだ秘密の解説'), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await showProjection(tester, questionOverrides(open(8)));
    expect(tester.widget<Text>(find.text('0:08')).style?.color, quizProjectionColorScheme.error);
    await tester.pumpWidget(const SizedBox());
  });

  for (final failing in [false, true]) {
    testWidgets('projection explains a missing countdown in venue wording (failing: $failing)', (tester) async {
      final pending = Completer<QuizClock>();
      addTearDown(() => pending.complete(QuizClock(serverNow: DateTime(2026))));
      await showProjection(
        tester,
        questionOverrides(
          question.copyWith(
            status: QuizQuestionStatus.open,
            closesAt: DateTime(2026).add(const Duration(minutes: 1)),
          ),
          clock: _Clock(next: failing ? null : pending.future, fails: failing),
        ),
      );
      expect(find.text(failing ? '残り時間を表示できません' : '残り時間を確認中…'), findsOneWidget);
      expect(find.text('時刻を同期中…'), findsNothing);
      expect(find.text('時刻同期に失敗しました（再接続待ち）'), findsNothing);
      expect(find.text('回答受付中'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('revealed projection highlights only the correct option and shows the explanation', (tester) async {
    await showProjection(
      tester,
      questionOverrides(
        question.copyWith(
          status: QuizQuestionStatus.revealed,
          options: const [
            LocaleMap(ja: 'Row', en: 'Horizontal'),
            LocaleMap(ja: 'Column', en: 'Vertical'),
            LocaleMap(ja: 'Stack', en: ''),
            LocaleMap(ja: 'Wrap', en: 'Wrapping'),
          ],
          correctOptionIndex: 2,
        ),
      ),
    );
    expect(find.text('正解発表'), findsOneWidget);
    expect(find.text('正解'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Stack'), findsNWidgets(2), reason: 'The option card and the answer panel');
    expect(find.text('3'), findsNWidgets(2));
    expect(find.text('まだ秘密の解説'), findsOneWidget);
    expect(find.text('Private explanation'), findsOneWidget);
    // Wrong options recede without fading their text, so they stay readable on a projector.
    double contrast(Color a, Color b) {
      final (l1, l2) = (a.computeLuminance(), b.computeLuminance());
      final (light, dark) = l1 > l2 ? (l1, l2) : (l2, l1);
      return (light + 0.05) / (dark + 0.05);
    }

    Color colorOf(Finder text) => tester.renderObject<RenderParagraph>(text).text.style!.color!;
    Color cardOf(Finder text) => tester.widget<Card>(find.ancestor(of: text, matching: find.byType(Card)).first).color!;
    final correctCard = cardOf(find.text('Stack').first);
    for (final (number, ja, en) in [
      ('1', 'Row', 'Horizontal'),
      ('2', 'Column', 'Vertical'),
      ('4', 'Wrap', 'Wrapping'),
    ]) {
      for (final label in [ja, en]) {
        final text = find.text(label);
        final opacities = tester.widgetList<Opacity>(find.ancestor(of: text, matching: find.byType(Opacity)));
        expect(opacities.map((opacity) => opacity.opacity), everyElement(1), reason: label);
        expect(contrast(colorOf(text), cardOf(text)), greaterThanOrEqualTo(4.5), reason: label);
      }
      final badge = tester.widget<CircleAvatar>(
        find.ancestor(of: find.text(number), matching: find.byType(CircleAvatar)),
      );
      expect(contrast(colorOf(find.text(number)), badge.backgroundColor!), greaterThanOrEqualTo(4.5), reason: number);
      expect(cardOf(find.text(ja)), isNot(correctCard), reason: 'Only the correct option is highlighted');
    }
  });

  final registered = QuizParticipant(id: 'uid-registered', displayName: '登録だけの人', registeredAt: DateTime(2026));
  final arrived = registered.copyWith(id: 'uid-arrived', displayName: '到着した人', checkedInAt: DateTime(2026));
  final seated = registered.copyWith(
    id: 'uid-seated',
    displayName: '着席した人',
    checkedInAt: DateTime(2026),
    teamId: 'C',
  );
  final people = [registered, arrived, seated];

  List<Override> prestartOverrides(QuizEvent value, {Stream<String?> Function()? code}) => [
    quizEventProvider('event').overrideWith((_) => Stream.value(value)),
    quizParticipantListProvider('event').overrideWith((_) => Stream.value(people)),
    quizTeamListProvider('event').overrideWith((_) => Stream.value(quizTeamsFromParticipants(people))),
    quizCheckInCodeProvider('event').overrideWith((_) => code?.call() ?? Stream.value('123456')),
  ];

  for (final (selection, label, message) in [
    (QuizTeamSelectionStatus.notStarted, '参加受付終了', 'チェックインの開始をお待ちください。'),
    (QuizTeamSelectionStatus.open, 'チェックイン受付中', 'チェックインして、チームを選んでください'),
    (QuizTeamSelectionStatus.closed, 'まもなく出題', 'クイズのルール'),
  ]) {
    testWidgets('prestart guidance follows check-in status and shows the code only while open: $selection', (
      tester,
    ) async {
      await showProjection(
        tester,
        prestartOverrides(
          event.copyWith(status: QuizEventStatus.entryClosed, currentQuestionId: null, teamSelectionStatus: selection),
        ),
      );
      expect(find.text(label), findsOneWidget);
      expect(find.text(message), findsOneWidget);
      final open = selection == QuizTeamSelectionStatus.open;
      expect(find.text('123456'), open ? findsOneWidget : findsNothing);
      expect(find.byType(QrImageView), open ? findsOneWidget : findsNothing);
      expect(find.textContaining('まだ参加表明していない方'), findsNothing);
      // Only counts reach the venue screen, never participant names or UIDs.
      for (final person in people) {
        expect(find.textContaining(person.id), findsNothing);
        expect(find.textContaining(person.displayName), findsNothing);
      }
    });
  }

  testWidgets('check-in shows the steps, progress from participants, and A–T tiles', (tester) async {
    await showProjection(
      tester,
      prestartOverrides(
        event.copyWith(
          status: QuizEventStatus.registration,
          currentQuestionId: null,
          teamSelectionStatus: QuizTeamSelectionStatus.open,
        ),
      ),
    );
    for (final step in ['QR コードを読み取る', '案内されたテーブルに着席する', 'アプリでチームを選ぶ']) {
      expect(find.text(step), findsOneWidget);
    }
    expect(find.text('参加コード'), findsOneWidget);
    expect(find.text('チェックイン 2 / 登録 3 人'), findsOneWidget);
    expect(find.text('チーム選択 1 人'), findsOneWidget);
    for (final id in quizTeamIds) {
      expect(find.text(id), findsOneWidget);
    }
    expect(find.text('1人'), findsOneWidget);
    // Registration is open again, so late arrivals must register before checking in.
    expect(find.text('まだ参加表明していない方は、先にアプリで「参加する」を押してください'), findsOneWidget);
  });

  testWidgets('briefing shows the rules and the teams formed so far', (tester) async {
    await showProjection(
      tester,
      prestartOverrides(
        event.copyWith(
          status: QuizEventStatus.entryClosed,
          currentQuestionId: null,
          teamSelectionStatus: QuizTeamSelectionStatus.closed,
        ),
      ),
    );
    for (final rule in ['回答はチームで1つ', '1問10点', '選択肢は 1〜4 の番号', 'スポンサー賞']) {
      expect(find.text(rule), findsOneWidget);
    }
    expect(find.text('1 チーム · 1 人'), findsOneWidget);
    expect(find.text('1人'), findsOneWidget);
  });

  for (final failing in [false, true]) {
    testWidgets('projection check-in code hides moderator guidance and error details (failing: $failing)', (
      tester,
    ) async {
      await showProjection(
        tester,
        prestartOverrides(
          event.copyWith(
            status: QuizEventStatus.entryClosed,
            currentQuestionId: null,
            teamSelectionStatus: QuizTeamSelectionStatus.open,
          ),
          code: () => failing ? Stream.error(Exception('internal detail')) : Stream.value(null),
        ),
      );
      expect(find.text(failing ? '参加コードを読み込めませんでした。' : '参加コードの表示までお待ちください。'), findsOneWidget);
      expect(find.textContaining('internal detail'), findsNothing);
      expect(find.textContaining('コードを再発行'), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
    });
  }

  List<Override> resultOverrides(List<QuizTeam> teams, {List<Sponsor> sponsors = const []}) => [
    quizEventProvider('event').overrideWith(
      (_) => Stream.value(event.copyWith(status: QuizEventStatus.finished, currentQuestionId: null)),
    ),
    quizTeamListProvider('event').overrideWith((_) => Stream.value(teams)),
    quizSponsorListProvider.overrideWith((_) => Stream.value(sponsors)),
  ];
  QuizTeam team(String name, int tableNumber, int score, int rank, {List<String> perfect = const []}) => QuizTeam(
    id: name,
    tableNumber: tableNumber,
    name: name,
    memberUids: ['$name-member'],
    score: score,
    rank: rank,
    perfectSponsorIds: perfect,
  );

  for (final (description, teams, firstPlace) in [
    (
      'every team tied for first place',
      [team('Alpha', 1, 80, 1), team('Bravo', 2, 80, 1), team('Charlie', 3, 80, 1)],
      3,
    ),
    (
      'third place tied with fourth',
      [team('H', 8, 80, 1), team('C', 3, 60, 2), team('M', 13, 50, 3), team('A', 1, 50, 3)],
      1,
    ),
  ]) {
    testWidgets('final projection lists all teams without a podium when $description', (tester) async {
      const empty = QuizTeam(id: 'Empty', tableNumber: 20, name: 'Empty');
      await showProjection(tester, resultOverrides([...teams, empty]));
      expect(find.text('結果発表'), findsOneWidget);
      for (final listed in teams) {
        expect(find.text('チーム ${listed.name}'), findsOneWidget);
      }
      expect(find.text('1 位'), findsNWidgets(firstPlace));
      expect(find.byIcon(Icons.emoji_events), findsNothing);
      // Empty teams have no score or prize.
      expect(find.text('チーム Empty'), findsNothing);
      expect(find.text('同点の場合の入賞チームの決め方は会場でご案内します'), findsOneWidget);
      expect(find.text('スポンサー賞'), findsNothing);
    });
  }

  testWidgets('final projection shows the podium and sponsor awards by sponsor name only', (tester) async {
    await showProjection(
      tester,
      resultOverrides(
        [
          team('H', 8, 80, 1, perfect: ['sponsor', 'other']),
          team('C', 3, 60, 2, perfect: ['sponsor']),
          team('M', 13, 50, 3),
          team('A', 1, 40, 4, perfect: ['unknown-sponsor']),
        ],
        sponsors: [sponsor('sponsor', 'テストスポンサー'), sponsor('other', '別のスポンサー')],
      ),
    );
    expect(find.byIcon(Icons.emoji_events), findsNWidgets(3));
    for (final (name, score) in [('H', '80 点'), ('C', '60 点'), ('M', '50 点')]) {
      expect(find.text('チーム $name'), findsWidgets);
      expect(find.text(score), findsOneWidget);
    }
    // Trophies take the medal colors (gold, silver, bronze), not the theme colors.
    for (final (place, color) in [
      ('1', const Color(0xFFF9A825)),
      ('2', const Color(0xFFBDBDBD)),
      ('3', const Color(0xFFA1887F)),
    ]) {
      final step = find.ancestor(of: find.text(place), matching: find.byType(Column)).first;
      final trophy = tester.widget<Icon>(find.descendant(of: step, matching: find.byIcon(Icons.emoji_events)));
      expect(trophy.color, color, reason: 'Place $place');
    }
    expect(find.text('4 位'), findsOneWidget);
    expect(find.text('スポンサー賞'), findsOneWidget);
    expect(find.text('テストスポンサー'), findsOneWidget);
    expect(find.text('別のスポンサー'), findsOneWidget);
    expect(find.textContaining('unknown-sponsor'), findsNothing);
    Finder chip(String name) => find.descendant(of: find.byType(Chip), matching: find.text('チーム $name'));
    expect(chip('H'), findsNWidgets(2));
    expect(chip('C'), findsOneWidget);
    expect(chip('M'), findsNothing);
    expect(chip('A'), findsNothing, reason: 'An award for an unknown sponsor is left out');
    expect(find.text('景品の引換券は\n運営スタッフからお渡しします'), findsOneWidget);
    expect(find.text('会場のスタッフの案内をお待ちください'), findsOneWidget);
  });

  testWidgets('final projection hides the sponsor awards when no awarded sponsor has a name', (tester) async {
    await showProjection(
      tester,
      resultOverrides(
        [
          team('H', 8, 80, 1, perfect: ['unknown-sponsor']),
          team('C', 3, 60, 2),
          team('M', 13, 50, 3),
        ],
        sponsors: [sponsor('sponsor', 'テストスポンサー')],
      ),
    );
    expect(find.byIcon(Icons.emoji_events), findsNWidgets(3));
    // No empty award panel or prize guidance is left on the screen.
    expect(find.text('スポンサー賞'), findsNothing);
    expect(find.byType(Chip), findsNothing);
    expect(find.textContaining('引換券'), findsNothing);
    expect(find.textContaining('unknown-sponsor'), findsNothing);
  });

  testWidgets('final projection grows the podium and rank rows instead of clipping enlarged text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    // 14 teams leave 11 below the podium, so the compact podium and rank rows are used.
    final rest = [
      for (final (index, name) in 'DEFGIJKLNOP'.split('').indexed)
        team(name, name.codeUnitAt(0) - 'A'.codeUnitAt(0) + 1, 60 - index * 5, index + 4),
    ];
    await showProjection(
      tester,
      resultOverrides(
        [
          team('H', 8, 90, 1, perfect: ['sponsor']),
          team('C', 3, 80, 2),
          team('M', 13, 70, 3),
          ...rest,
        ],
        sponsors: [sponsor('sponsor', 'テストスポンサー')],
      ),
    );
    expect(find.text('スポンサー賞'), findsOneWidget);
    // Each line keeps its full scaled line height: twice the designed one.
    for (final listed in rest) {
      final height = tester.getSize(find.text('チーム ${listed.name}')).height;
      expect(height, closeTo(38 * 2, 0.5), reason: 'Team ${listed.name}');
    }
    for (final (place, lineHeight) in [('1', 80), ('2', 64), ('3', 64)]) {
      expect(tester.getSize(find.text(place)).height, closeTo(lineHeight * 2, 0.5), reason: 'Place $place');
    }
  });

  for (final (description, teams, listed) in [
    (
      'below the podium',
      [
        team('H', 8, 100, 1),
        team('C', 3, 90, 2),
        team('M', 13, 80, 3),
        team('D', 4, 70, 4),
        team('E', 5, 60, 5),
        team('F', 6, 50, 6),
        team('G', 7, 40, 7),
        team('I', 9, 30, 8),
      ],
      ['D', 'E', 'F', 'G', 'I'],
    ),
    (
      'without a podium',
      [team('H', 8, 80, 1), team('C', 3, 80, 1), team('M', 13, 70, 3), team('D', 4, 60, 4), team('E', 5, 50, 5)],
      // Tied teams are ordered by table number.
      ['C', 'H', 'M', 'D', 'E'],
    ),
  ]) {
    testWidgets('final projection lists teams down each column $description', (tester) async {
      await showProjection(tester, resultOverrides(teams));
      // Each column takes the next ceil(count / 3) teams, so reading down a column follows the ranking.
      final rows = (listed.length + 2) ~/ 3;
      final origins = [for (final name in listed) tester.getTopLeft(find.text('チーム $name'))];
      for (final (index, origin) in origins.indexed) {
        final (column, row) = (index ~/ rows, index % rows);
        expect(origin.dx, origins[column * rows].dx, reason: '${listed[index]} is in column ${column + 1}');
        expect(origin.dy, origins[row].dy, reason: '${listed[index]} is in row ${row + 1}');
      }
      for (var column = 1; column * rows < listed.length; column++) {
        expect(origins[column * rows].dx, greaterThan(origins[(column - 1) * rows].dx));
      }
      for (var row = 1; row < rows; row++) {
        expect(origins[row].dy, greaterThan(origins[row - 1].dy));
      }
    });
  }
}

class _Clock implements QuizClockRepository {
  _Clock({this.next, this.fails = false});

  final Future<QuizClock>? next;
  final bool fails;

  @override
  Future<QuizClock> synchronize() async {
    if (fails) throw FirebaseFunctionsException(code: 'unavailable', message: 'Clock request interrupted');
    return next ?? QuizClock(serverNow: DateTime(2026), elapsed: () => Duration.zero);
  }
}
