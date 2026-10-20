import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/ui/component/quiz_progress_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 英語の文言は遅延読み込みなので、setLocaleSync の前に読み込んでおく。
  setUpAll(() async => AppLocale.en.build());
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  for (final locale in AppLocale.values) {
    testWidgets('steps stay on a narrow screen with doubled text: ${locale.languageCode}', (tester) async {
      LocaleSettings.setLocaleSync(locale);
      const width = 320.0;
      tester.view.physicalSize = const Size(width, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            locale: locale.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: QuizProgressSteps(current: QuizProgressStep.checkIn),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      // 段階の名前は折り返して画面内に収まる。
      for (final label in [t.quiz.progress.join, t.quiz.progress.checkIn, t.quiz.progress.selectTeam]) {
        final rect = tester.getRect(find.text(label));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
      }

      // 番号が縦に切れないよう、丸は拡大した番号より大きい。
      final number = find.text('3');
      // 番号にいちばん近い Container が丸。
      final circle = find.ancestor(of: number, matching: find.byType(Container)).first;
      expect(tester.getSize(circle).height, greaterThan(tester.getSize(number).height));
      expect(tester.getRect(circle).right, lessThanOrEqualTo(width));

      // 段をつなぐ線は残す（3 段の間に、丸の左右の半分ずつで 4 本）。
      expect(
        find.descendant(of: find.byType(QuizProgressSteps), matching: find.byType(ColoredBox)),
        findsNWidgets(4),
      );
    });
  }
}
