import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/profile/data/provider/user_profile_provider.dart';
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
            userProfileProvider.overrideWith((_) => Stream.value(null)),
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
      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, t.quiz.registration.join));
      await tester.pumpAndSettle();
      expect(repository.codes, ['123456']);
      final expectedMessage = switch (code) {
        'resource-exhausted' => t.quiz.registration.full(max: '80'),
        'permission-denied' => t.quiz.registration.codeMismatch,
        'already-exists' => t.quiz.registration.alreadyParticipated,
        'failed-precondition' => t.quiz.registration.closed,
        _ => t.quiz.registration.unavailable,
      };
      expect(find.text(expectedMessage), findsOneWidget);
      if (code != 'permission-denied') {
        expect(find.text(t.quiz.registration.codeMismatch), findsNothing);
      }
    });
  }

  testWidgets('entry code attempt limit asks the attendee to wait instead of reporting a full event', (tester) async {
    final repository = _Participants()
      ..failure = FirebaseFunctionsException(
        code: 'resource-exhausted',
        message: 'Too many attempts',
        details: const {'reason': 'rate-limited'},
      );
    await show(tester, repository);
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, t.quiz.registration.join));
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.registration.rateLimited), findsOneWidget);
    expect(find.text(t.quiz.registration.full(max: '80')), findsNothing);
  });

  testWidgets('disabled accounts are not told that the code is wrong', (tester) async {
    final repository = _Participants()
      ..failure = FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'Account disabled',
        details: const {'reason': 'disabled-account'},
      );
    await show(tester, repository);
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, t.quiz.registration.join));
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.registration.accountUnavailable), findsOneWidget);
    expect(find.text(t.quiz.registration.codeMismatch), findsNothing);
  });

  testWidgets('requires six numeric digits before sending and uses the entered name', (tester) async {
    final repository = _Participants();
    await show(tester, repository);
    await tester.enterText(find.byType(TextField).last, '12345');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.enterText(find.byType(TextField).first, 'Bob');
    await tester.enterText(find.byType(TextField).last, '12a3456');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, t.quiz.registration.join));
    await tester.pumpAndSettle();
    expect(repository.codes, ['123456']);
    expect(repository.names, ['Bob']);
  });
}

class _Participants extends Fake implements QuizParticipantRepository {
  Exception? failure;
  final codes = <String>[];
  final names = <String>[];

  @override
  Future<void> register(
    String eventId, {
    required String displayName,
    required String entryCode,
    String? uid,
    String? signInProvider,
    String? email,
    String? accountName,
    String? photoUrl,
  }) async {
    codes.add(entryCode);
    names.add(displayName);
    if (failure case final error?) {
      throw error;
    }
  }
}
