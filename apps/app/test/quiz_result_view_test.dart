import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/ui/component/quiz_result_view.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  Future<void> showResults(WidgetTester tester, List<QuizTeam> teams) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            quizEventIdProvider.overrideWithValue('test-event'),
            quizTeamsProvider.overrideWith((ref) => Stream.value(teams)),
            quizSponsorsProvider.overrideWith((ref) => Stream.value(<Sponsor>[])),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const Scaffold(body: QuizResultView(myTeam: null)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('control: shows all teams with distinct ranks', (tester) async {
    await showResults(tester, const [
      QuizTeam(id: 'a', tableNumber: 1, name: 'RankOne', rank: 1, score: 80),
      QuizTeam(id: 'b', tableNumber: 2, name: 'RankTwo', rank: 2, score: 70),
      QuizTeam(id: 'c', tableNumber: 3, name: 'RankThree', rank: 3, score: 60),
      QuizTeam(id: 'd', tableNumber: 4, name: 'RankFour', rank: 4, score: 50),
    ]);
    for (final name in ['RankOne', 'RankTwo', 'RankThree', 'RankFour']) {
      expect(find.text(name), findsOneWidget, reason: '$name should be listed');
    }
  });

  testWidgets('all teams tied for first remain visible for manual tie break', (tester) async {
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
    ].where((name) => find.text(name).evaluate().isNotEmpty).toList();
    debugPrint('Rendered team names: $renderedNames');
    expect(renderedNames, containsAll(['TiedAlpha', 'TiedBravo', 'TiedCharlie', 'RankFour']));
  });
}
