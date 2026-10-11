import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/environment.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/quiz/data/provider/quiz_providers.dart';
import 'package:app/feature/quiz/data/provider/quiz_repositories.dart';
import 'package:app/feature/quiz/ui/page/quiz_check_in_scan_page.dart';
import 'package:app/feature/quiz/ui/page/quiz_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'fake_auth_repository.dart';
import 'fake_mobile_scanner_platform.dart';

void main() {
  final originalPlatform = MobileScannerPlatform.instance;
  setUpAll(() => MobileScannerPlatform.instance = FakeMobileScannerPlatform());
  tearDownAll(() => MobileScannerPlatform.instance = originalPlatform);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  final event = QuizEvent(
    id: 'event',
    title: const LocaleMap(ja: 'Quiz', en: 'Quiz'),
    status: QuizEventStatus.entryClosed,
    teamSelectionStatus: QuizTeamSelectionStatus.open,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final person = QuizParticipant(id: 'member', displayName: 'Member', registeredAt: DateTime.utc(2026));

  Future<void> show(
    WidgetTester tester,
    _Participants repository, {
    required Stream<QuizEvent?> events,
    required Stream<QuizParticipant?> participant,
    String? checkInCode,
    FakeUser? user,
    Stream<FakeUser?>? users,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          retry: (_, _) => null,
          overrides: [
            if (users == null)
              quizUserProvider.overrideWithValue(AsyncData(user))
            else
              quizUserProvider.overrideWith((ref) => AsyncData(ref.watch(_signedInUser(users)).value)),
            quizEventProvider.overrideWith((_) => events),
            myParticipantProvider.overrideWith((_) => participant),
            myTeamProvider.overrideWith((_) => Stream.value(null)),
            quizParticipantsProvider.overrideWith((_) => Stream.value([person])),
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
            home: QuizPage(eventId: 'event', checkInCode: checkInCode),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextFormField), code);
    await tester.ensureVisible(find.text(t.quiz.checkIn.submit));
    await tester.tap(find.text(t.quiz.checkIn.submit));
    await tester.pumpAndSettle();
  }

  testWidgets('team selection waits for the server to record check-in', (tester) async {
    final participant = StreamController<QuizParticipant?>()..add(person);
    addTearDown(participant.close);
    final repository = _Participants();
    await show(
      tester,
      repository,
      events: Stream.value(event),
      participant: participant.stream,
      user: FakeUser(),
    );
    expect(find.text(t.quiz.checkIn.title), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);

    await submit(tester, '123456');
    expect(repository.calls, ['123456']);
    expect(find.text(t.quiz.checkIn.title), findsOneWidget);

    participant.add(person.copyWith(checkedInAt: DateTime.utc(2026)));
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.checkIn.title), findsNothing);
    expect(find.byType(ChoiceChip), findsNWidgets(20));
  });

  for (final (reason, message) in [
    ('wrong-code', () => t.quiz.checkIn.wrongCode),
    ('rate-limited', () => t.quiz.checkIn.rateLimited),
  ]) {
    testWidgets('a rejected code explains $reason', (tester) async {
      final repository = _Participants()
        ..failure = FirebaseFunctionsException(
          code: reason == 'wrong-code' ? 'permission-denied' : 'resource-exhausted',
          message: reason,
          details: {'reason': reason},
        );
      await show(tester, repository, events: Stream.value(event), participant: Stream.value(person), user: FakeUser());
      await submit(tester, '123456');
      expect(find.text(message()), findsOneWidget);
    });
  }

  testWidgets('a malformed code is caught before sending', (tester) async {
    final repository = _Participants();
    await show(tester, repository, events: Stream.value(event), participant: Stream.value(person), user: FakeUser());
    await submit(tester, '12345');
    expect(find.text(t.quiz.checkIn.invalidFormat), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('a link code is submitted once, even when check-in closes and reopens', (tester) async {
    final events = StreamController<QuizEvent?>()..add(event);
    addTearDown(events.close);
    final repository = _Participants()
      ..failure = FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'wrong',
        details: const {'reason': 'wrong-code'},
      );
    await show(
      tester,
      repository,
      events: events.stream,
      participant: Stream.value(person),
      checkInCode: '654321',
      user: FakeUser(),
    );
    expect(repository.calls, ['654321']);
    expect(find.text(t.quiz.checkIn.wrongCode), findsOneWidget);

    events.add(event.copyWith(teamSelectionStatus: QuizTeamSelectionStatus.closed));
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.checkIn.closed), findsOneWidget);
    events.add(event);
    await tester.pumpAndSettle();
    expect(repository.calls, ['654321']);
  });

  testWidgets('an invalid link explains itself and sends nothing', (tester) async {
    final repository = _Participants();
    await show(
      tester,
      repository,
      events: Stream.value(event),
      participant: Stream.value(person),
      checkInCode: 'abc',
      user: FakeUser(),
    );
    expect(find.text(t.quiz.checkIn.linkInvalid), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('a link opened while signed out offers sign-in on the quiz page', (tester) async {
    final repository = _Participants();
    await show(
      tester,
      repository,
      events: Stream.value(event),
      participant: Stream.value(person),
      checkInCode: '654321',
    );
    expect(find.byType(SignInCard), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('a link opened while signed out is sent once after sign-in and the record loads', (tester) async {
    final users = StreamController<FakeUser?>()..add(null);
    final participant = StreamController<QuizParticipant?>();
    addTearDown(users.close);
    addTearDown(participant.close);
    final repository = _Participants();
    await show(
      tester,
      repository,
      events: Stream.value(event),
      participant: participant.stream,
      checkInCode: '654321',
      users: users.stream,
    );
    expect(find.byType(SignInCard), findsOneWidget);

    final member = FakeUser(uid: 'member');
    users.add(member);
    await tester.pump();
    await tester.pump();
    expect(find.byType(SignInCard), findsNothing);
    expect(repository.calls, isEmpty);

    participant.add(person);
    await tester.pumpAndSettle();
    expect(repository.calls, ['654321']);

    users.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(SignInCard), findsOneWidget);
    users.add(member);
    await tester.pumpAndSettle();
    expect(find.text(t.quiz.checkIn.title), findsOneWidget);
    expect(repository.calls, ['654321']);
  });

  testWidgets('registered attendees wait for check-in to open', (tester) async {
    await show(
      tester,
      _Participants(),
      events: Stream.value(event.copyWith(teamSelectionStatus: QuizTeamSelectionStatus.notStarted)),
      participant: Stream.value(person),
      user: FakeUser(),
    );
    expect(find.text(t.quiz.waiting.description), findsOneWidget);
    expect(find.text(t.quiz.checkIn.title), findsNothing);
  });

  group('QuizCheckInScanPage', () {
    Future<List<String?>> openScanPage(WidgetTester tester) async {
      final results = <String?>[];
      await tester.pumpWidget(
        TranslationProvider(
          child: ProviderScope(
            overrides: [
              environmentProvider.overrideWithValue(Environment.fromEnvironment().copyWith(flavor: Flavor.production)),
            ],
            child: MaterialApp(
              locale: const Locale('ja'),
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () async => results.add(
                        await Navigator.of(context).push<String>(
                          MaterialPageRoute(builder: (_) => const QuizCheckInScanPage(eventId: 'event')),
                        ),
                      ),
                      child: const Text('open scan'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open scan'));
      await tester.pumpAndSettle();
      return results;
    }

    void detect(WidgetTester tester, String rawValue) {
      tester.widget<MobileScanner>(find.byType(MobileScanner)).onDetect!(
        BarcodeCapture(barcodes: [Barcode(rawValue: rawValue)]),
      );
    }

    testWidgets("keeps scanning after another round or feature, and returns this round's code", (tester) async {
      final results = await openScanPage(tester);

      detect(tester, quizCheckInQrPayload('other', '123456', origin: productionAppOrigin));
      await tester.pumpAndSettle();
      expect(find.text(t.quiz.checkIn.scanOtherEvent), findsOneWidget);

      detect(tester, supportLtQrPayload('123456', origin: productionAppOrigin));
      await tester.pumpAndSettle();
      expect(find.text(t.quiz.checkIn.scanInvalid), findsOneWidget);

      detect(tester, quizCheckInQrPayload('event', '123456', origin: stagingAppOrigin));
      await tester.pumpAndSettle();
      expect(find.byType(QuizCheckInScanPage), findsOneWidget);
      expect(results, isEmpty);

      detect(tester, quizCheckInQrPayload('event', '123456', origin: productionAppOrigin));
      await tester.pumpAndSettle();
      expect(find.byType(QuizCheckInScanPage), findsNothing);
      expect(results, ['123456']);
    });

    testWidgets('accepts a bare code', (tester) async {
      final results = await openScanPage(tester);
      detect(tester, '654321');
      await tester.pumpAndSettle();
      expect(results, ['654321']);
    });
  });
}

/// Feeds the page a test-controlled sign-in state, like the auth stream does.
final _signedInUser = StreamProvider.family<FakeUser?, Stream<FakeUser?>>((ref, users) => users);

class _Participants extends Fake implements QuizParticipantRepository {
  final calls = <String>[];
  FirebaseFunctionsException? failure;

  @override
  Future<void> checkIn(String eventId, String code) async {
    calls.add(code);
    if (failure case final error?) {
      throw error;
    }
  }
}
