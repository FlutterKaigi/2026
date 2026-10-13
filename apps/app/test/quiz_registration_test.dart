import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/page/quiz_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  final event = QuizEvent(
    id: 'event',
    title: const LocaleMap(ja: 'Quiz', en: 'Quiz'),
    status: QuizEventStatus.registration,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  Future<void> show(WidgetTester tester, _Participants repository) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          retry: (_, _) => null,
          overrides: [
            quizUserProvider.overrideWithValue(AsyncData(FakeUser(displayName: 'Alice'))),
            quizEventProvider.overrideWith((_) => Stream.value(event)),
            myParticipantProvider.overrideWith((_) => Stream.value(null)),
            myTeamProvider.overrideWith((_) => Stream.value(null)),
            quizParticipantsProvider.overrideWith((_) => Stream.value(<QuizParticipant>[])),
            quizParticipantRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const QuizPage(eventId: 'event'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final code in [
    'resource-exhausted',
    'permission-denied',
    'already-exists',
    'failed-precondition',
    'unavailable',
  ]) {
    testWidgets('registration reports $code accurately', (tester) async {
      final repository = _Participants()..failure = FirebaseFunctionsException(code: code, message: code);
      await show(tester, repository);
      await tester.tap(find.widgetWithText(FilledButton, t.quiz.registration.join));
      await tester.pumpAndSettle();
      expect(repository.events, ['event']);
      final expectedMessage = switch (code) {
        'resource-exhausted' => t.quiz.registration.full(max: '80'),
        'permission-denied' => t.quiz.registration.accountUnavailable,
        'already-exists' => t.quiz.registration.alreadyParticipated,
        'failed-precondition' => t.quiz.registration.closed,
        _ => t.quiz.registration.unavailable,
      };
      expect(find.text(expectedMessage), findsOneWidget);
    });
  }

  testWidgets('joining needs no code or nickname and does not send the account name', (tester) async {
    final repository = _Participants();
    await show(tester, repository);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, t.quiz.registration.join));
    await tester.pumpAndSettle();
    expect(repository.events, ['event']);
  });
}

class _Participants extends Fake implements QuizParticipantRepository {
  Exception? failure;
  final events = <String>[];

  @override
  Future<void> register(String eventId) async {
    events.add(eventId);
    if (failure case final error?) {
      throw error;
    }
  }
}
