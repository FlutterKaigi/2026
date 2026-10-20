import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/ui/component/quiz_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  Future<void> show(WidgetTester tester, List<Widget> cards) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(body: Column(children: cards)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("the answer reveal announces the correct option and the team's wrong choice", (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester, const [
      QuizOptionCard(index: 0, label: 'Option A', state: QuizOptionState.correct, enabled: false),
      QuizOptionCard(index: 1, label: 'Option B', state: QuizOptionState.wrongChoice, enabled: false),
      QuizOptionCard(index: 2, label: 'Option C', state: QuizOptionState.dimmed, enabled: false),
    ]);
    expect(tester.getSemantics(find.text('Option A')), isSemantics(value: t.quiz.revealed.correctLabel));
    expect(tester.getSemantics(find.text('Option B')), isSemantics(value: t.quiz.revealed.wrongLabel));
    expect(tester.getSemantics(find.text('Option C')), isSemantics(value: ''));
    semantics.dispose();
  });

  testWidgets('answer buttons are announced by their selection, not as revealed', (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester, [
      QuizOptionCard(index: 0, label: 'Option A', state: QuizOptionState.selected, onTap: () {}),
    ]);
    expect(
      tester.getSemantics(find.text('Option A')),
      isSemantics(value: '', isButton: true, hasSelectedState: true, isSelected: true),
    );
    semantics.dispose();
  });

  testWidgets('dimmed options stay opaque so their text keeps its contrast', (tester) async {
    await show(tester, const [
      QuizOptionCard(index: 2, label: 'Option C', state: QuizOptionState.dimmed, enabled: false),
    ]);
    final scheme = Theme.of(tester.element(find.text('Option C'))).colorScheme;
    expect(
      find.descendant(
        of: find.byType(QuizOptionCard),
        matching: find.byWidgetPredicate((widget) => widget is Opacity || widget is AnimatedOpacity),
      ),
      findsNothing,
    );
    final card = tester.widget<AnimatedContainer>(
      find.descendant(of: find.byType(QuizOptionCard), matching: find.byType(AnimatedContainer)),
    );
    expect((card.decoration! as BoxDecoration).color, scheme.surface);
    expect(tester.widget<Text>(find.text('Option C')).style?.color, scheme.onSurfaceVariant);
  });
}
