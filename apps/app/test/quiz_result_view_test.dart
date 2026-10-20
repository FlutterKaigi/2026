import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/ui/component/quiz_result_view.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  Future<void> showResults(
    WidgetTester tester,
    List<QuizTeam> teams, {
    QuizTeam? myTeam,
    List<Sponsor> sponsors = const [],
    Size size = const Size(1200, 1600),
    TextScaler? textScaler,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            quizEventIdProvider.overrideWithValue('test-event'),
            quizTeamsProvider.overrideWith((ref) => Stream.value(teams)),
            quizSponsorsProvider.overrideWith((ref) => Stream.value(sponsors)),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true, textScaler: textScaler),
              child: child!,
            ),
            home: Scaffold(body: QuizResultView(myTeam: myTeam)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('control: shows all teams with distinct ranks', (tester) async {
    final t = AppLocale.ja.translations.quiz.result;
    await showResults(tester, const [
      QuizTeam(id: 'a', tableNumber: 1, name: 'RankOne', rank: 1, score: 80),
      QuizTeam(id: 'b', tableNumber: 2, name: 'RankTwo', rank: 2, score: 70),
      QuizTeam(id: 'c', tableNumber: 3, name: 'RankThree', rank: 3, score: 60),
      QuizTeam(id: 'd', tableNumber: 4, name: 'RankFour', rank: 4, score: 50),
    ]);
    for (final name in ['RankOne', 'RankTwo', 'RankThree', 'RankFour']) {
      expect(find.text(t.table(name: name)), findsOneWidget, reason: '$name should be listed');
      // 表彰台・一覧ともチーム名は「チーム X」の 1 行だけにする。
      expect(find.text(name), findsNothing, reason: '$name should not have a name-only row');
    }
    expect(find.byIcon(Icons.emoji_events), findsNWidgets(3), reason: 'top three should stand on the podium');
  });

  testWidgets('all teams tied for first remain visible for manual tie break', (tester) async {
    final t = AppLocale.ja.translations.quiz.result;
    await showResults(tester, const [
      QuizTeam(id: 'a', tableNumber: 1, name: 'TiedAlpha', rank: 1, score: 80),
      QuizTeam(id: 'b', tableNumber: 2, name: 'TiedBravo', rank: 1, score: 80),
      QuizTeam(id: 'c', tableNumber: 3, name: 'TiedCharlie', rank: 1, score: 80),
      QuizTeam(id: 'd', tableNumber: 4, name: 'RankFour', rank: 4, score: 70),
    ]);
    final renderedNames = [
      'TiedAlpha',
      'TiedBravo',
      'TiedCharlie',
      'RankFour',
    ].where((name) => find.text(t.table(name: name)).evaluate().isNotEmpty).toList();
    debugPrint('Rendered team names: $renderedNames');
    expect(renderedNames, containsAll(['TiedAlpha', 'TiedBravo', 'TiedCharlie', 'RankFour']));
    // 同率上位がいるときは表彰台で代表 1 チームを選ばない。
    expect(find.byIcon(Icons.emoji_events), findsNothing);
    expect(find.text(t.tieNote), findsOneWidget);
  });

  testWidgets('shows my team rank and sponsor awards with a single voucher note', (tester) async {
    final t = AppLocale.ja.translations.quiz.result;
    const mine = QuizTeam(
      id: 'c',
      tableNumber: 3,
      name: 'C',
      rank: 2,
      score: 60,
      perfectSponsorIds: ['s1', 's2'],
    );
    await showResults(
      tester,
      const [
        QuizTeam(id: 'h', tableNumber: 8, name: 'H', rank: 1, score: 80),
        mine,
        QuizTeam(id: 'm', tableNumber: 13, name: 'M', rank: 3, score: 50),
        QuizTeam(id: 'a', tableNumber: 1, name: 'A', rank: 4, score: 40),
      ],
      myTeam: mine,
      sponsors: [_sponsor('s1', 'Alpha Inc.'), _sponsor('s2', 'Bravo Inc.')],
    );

    expect(find.text(t.rank(rank: '2')), findsOneWidget);
    // ヒーローと表彰台の両方に自チームが出る。
    expect(find.text(t.table(name: 'C')), findsNWidgets(2));
    expect(find.text(t.points(score: '60')), findsNWidgets(2));
    expect(find.text(t.yourTeam), findsNWidgets(2));

    expect(find.text(t.award.title), findsOneWidget);
    expect(find.text(t.award.perfect(sponsor: 'Alpha Inc.')), findsOneWidget);
    expect(find.text(t.award.perfect(sponsor: 'Bravo Inc.')), findsOneWidget);
    expect(find.text(t.award.voucher), findsOneWidget);
    expect(find.text(t.award.voucherHint), findsOneWidget);
    // 景品はブースではなく運営スタッフから渡すため、ブースへ誘導しない。
    expect(find.textContaining('ブース'), findsNothing);
    // スポンサーのロゴは表示規約があるため出さない。
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('my team without a rank shows only its team and points', (tester) async {
    final t = AppLocale.ja.translations.quiz.result;
    const mine = QuizTeam(id: 'b', tableNumber: 2, name: 'B', score: 30);
    await showResults(
      tester,
      const [
        QuizTeam(id: 'a', tableNumber: 1, name: 'A', rank: 1, score: 80),
        mine,
      ],
      myTeam: mine,
    );

    expect(find.text(t.yourTeam), findsOneWidget);
    expect(find.text(t.table(name: 'B')), findsNWidgets(2));
    expect(find.text(t.points(score: '30')), findsNWidgets(2));
    expect(find.textContaining(RegExp(r'^\d+位$')), findsNothing);
    expect(find.text(t.award.title), findsNothing);
  });

  testWidgets('without my team, shows only the ranking', (tester) async {
    final t = AppLocale.ja.translations.quiz.result;
    await showResults(tester, const [
      QuizTeam(id: 'a', tableNumber: 1, name: 'A', rank: 1, score: 80, perfectSponsorIds: ['s1']),
      QuizTeam(id: 'b', tableNumber: 2, name: 'B', rank: 2, score: 70),
    ]);

    expect(find.text(t.yourTeam), findsNothing);
    expect(find.text(t.award.title), findsNothing);
    expect(find.text(t.award.voucher), findsNothing);
    expect(find.text(t.ranking), findsOneWidget);
    expect(find.text(t.table(name: 'A')), findsOneWidget);
    expect(find.text(t.tieNote), findsOneWidget);
  });

  testWidgets('section titles are announced as headings', (tester) async {
    final semantics = tester.ensureSemantics();
    final t = AppLocale.ja.translations.quiz.result;
    const mine = QuizTeam(id: 'b', tableNumber: 2, name: 'B', rank: 2, score: 70, perfectSponsorIds: ['s1']);
    await showResults(
      tester,
      const [
        QuizTeam(id: 'a', tableNumber: 1, name: 'A', rank: 1, score: 80),
        mine,
      ],
      myTeam: mine,
      sponsors: [_sponsor('s1', 'Alpha Inc.')],
    );

    // 見出しには本文を混ぜない（カード全体が見出しとして読まれないようにする）。
    for (final title in [t.title, t.ranking, t.award.title]) {
      expect(tester.getSemantics(find.text(title)), isSemantics(label: title, isHeader: true), reason: title);
    }
    semantics.dispose();
  });

  testWidgets('podium is read from first place with the place before each team', (tester) async {
    final semantics = tester.ensureSemantics();
    final t = AppLocale.ja.translations.quiz.result;
    await showResults(tester, const [
      QuizTeam(id: 'a', tableNumber: 1, name: 'RankOne', rank: 1, score: 80),
      QuizTeam(id: 'b', tableNumber: 2, name: 'RankTwo', rank: 2, score: 70),
      QuizTeam(id: 'c', tableNumber: 3, name: 'RankThree', rank: 3, score: 60),
      QuizTeam(id: 'd', tableNumber: 4, name: 'RankFour', rank: 4, score: 50),
    ]);

    final labels = tester.semantics.simulatedAccessibilityTraversal().map((node) => node.label).toList();
    // 並びは 2 位・1 位・3 位でも、読み上げは 1 位から順にする。
    final podium = [
      for (final (rank, name) in [('1', 'RankOne'), ('2', 'RankTwo'), ('3', 'RankThree')])
        labels.indexWhere((label) => label.startsWith(t.rank(rank: rank)) && label.contains(t.table(name: name))),
    ];
    expect(podium, everyElement(isNonNegative), reason: '$labels');
    expect(podium[1], greaterThan(podium[0]));
    expect(podium[2], greaterThan(podium[1]));
    // 台の数字だけを単独で読ませない（先頭の「1位」で伝える）。
    for (final (index, rank) in [(podium[0], '1'), (podium[1], '2'), (podium[2], '3')]) {
      expect(labels[index].split('\n'), isNot(contains(rank)), reason: labels[index]);
    }
    semantics.dispose();
  });

  testWidgets('enlarged text wraps podium names and keeps ranks whole on a phone', (tester) async {
    final t = AppLocale.ja.translations.quiz.result;
    const mine = QuizTeam(id: 'c', tableNumber: 3, name: 'C', rank: 3, score: 60);
    await showResults(
      tester,
      const [
        QuizTeam(id: 'a', tableNumber: 1, name: 'A', rank: 1, score: 80),
        QuizTeam(id: 'b', tableNumber: 2, name: 'B', rank: 2, score: 70),
        mine,
        // 一覧の 2 桁の順位。
        QuizTeam(id: 'd', tableNumber: 4, name: 'D', rank: 10, score: 10),
      ],
      myTeam: mine,
      // スマートフォンの幅で文字を 2 倍にする。縦は全員が描画される長さにする。
      size: const Size(360, 3000),
      textScaler: const TextScaler.linear(2),
    );

    // 表彰台のチーム名と「あなたのチーム」は省略せず折り返す。
    for (final text in [t.table(name: 'A'), t.table(name: 'B'), t.table(name: 'C'), t.yourTeam]) {
      for (final paragraph in tester.renderObjectList<RenderParagraph>(find.text(text))) {
        expect(paragraph.didExceedMaxLines, isFalse, reason: '$text should not be truncated');
      }
    }
    // 台の中の順位の数字は、台に収まって切れない。
    for (final rank in ['1', '2', '3']) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(rank));
      expect(
        paragraph.size.height,
        greaterThanOrEqualTo(paragraph.getMinIntrinsicHeight(paragraph.size.width)),
        reason: 'rank $rank should fit in its block',
      );
    }
    // 一覧の 2 桁の順位は折り返さない。
    final twoDigitRank = tester.renderObject<RenderParagraph>(find.text('10'));
    expect(twoDigitRank.size.width, greaterThanOrEqualTo(twoDigitRank.getMaxIntrinsicWidth(double.infinity)));
  });
}

Sponsor _sponsor(String id, String name) => Sponsor(
  id: id,
  name: LocaleMap(ja: name, en: name),
  description: const LocaleMap(ja: '', en: ''),
  tier: SponsorTier.gold,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
