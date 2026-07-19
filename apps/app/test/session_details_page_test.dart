import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/session/data/provider/session_detail_provider.dart';
import 'package:app/feature/session/data/provider/session_repository.dart';
import 'package:app/feature/session/data/provider/session_timetable_repository.dart';
import 'package:app/feature/session/ui/page/session_details_page.dart';
import 'package:app/feature/session/ui/page/session_timetable_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('builds the typed session details route location', () {
    expect(
      const SessionDetailsRoute(sessionId: 'session-a').location,
      '/sessions/session-a',
    );
  });

  testWidgets('renders current Firestore-backed session details', (tester) async {
    await _pumpSessionDetailsPage(tester, sessionId: 'session-a');
    await _pumpProviderFrames(tester);

    expect(find.text('Session A'), findsWidgets);
    expect(find.text('Description A'), findsOneWidget);
    expect(find.text('2026/10/29'), findsWidgets);
    expect(find.text('10:00-10:45'), findsWidgets);
    expect(find.text('Hall A'), findsWidgets);
    expect(find.text('Speaker A'), findsOneWidget);
    expect(find.text('Bio A'), findsOneWidget);
    expect(find.text('Sessionize'), findsOneWidget);
    expect(find.text('https://sessionize.com/flutterkaigi-2026/session-a'), findsOneWidget);
  });

  testWidgets('hides optional sections when session fields are absent', (tester) async {
    await _pumpSessionDetailsPage(tester, sessionId: 'session-without-optionals');
    await _pumpProviderFrames(tester);

    expect(find.text('No Optional Fields'), findsWidgets);
    expect(find.text('登壇者'), findsNothing);
    expect(find.text('概要'), findsNothing);
    expect(find.text('リンク'), findsNothing);
    expect(find.text('Sessionize'), findsNothing);
  });

  testWidgets('hides the Sessionize link when the URL is not a hosted HTTPS URL', (tester) async {
    for (final session in [
      _sessionWithSessionizeUrl(id: 'tel-url', sessionizeUrl: 'tel:+1234567890'),
      _sessionWithSessionizeUrl(id: 'custom-url', sessionizeUrl: 'myapp://sessions/session-a'),
      _sessionWithSessionizeUrl(id: 'hostless-https-url', sessionizeUrl: 'https:///sessions/session-a'),
    ]) {
      await _pumpSessionDetailsPage(
        tester,
        sessionId: session.id,
        sessionRepository: _FakeSessionRepository([session]),
      );
      await _pumpProviderFrames(tester);

      expect(find.text('Sessionize'), findsNothing);
    }
  });

  testWidgets('shows not found when the session ID is unknown', (tester) async {
    await _pumpSessionDetailsPage(tester, sessionId: 'missing');
    await _pumpProviderFrames(tester);

    expect(find.text('セッションが見つかりませんでした'), findsOneWidget);
  });

  testWidgets('shows an error state when the details provider fails', (tester) async {
    final preferences = await _prepareTester(tester);

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            sessionDetailProvider('session-a').overrideWithValue(
              AsyncError(Exception('boom'), StackTrace.current),
            ),
          ],
          child: const MaterialApp(home: SessionDetailsPage(sessionId: 'session-a')),
        ),
      ),
    );
    await _pumpProviderFrames(tester);

    expect(find.text('セッションを取得できませんでした'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
  });

  testWidgets('opens session details from a timetable session card', (tester) async {
    final router = GoRouter(
      initialLocation: '/sessions',
      routes: [
        GoRoute(
          path: '/sessions',
          builder: (context, state) => const SessionTimetablePage(),
          routes: [
            GoRoute(
              path: ':sessionId',
              builder: (context, state) => SessionDetailsPage(
                sessionId: state.pathParameters['sessionId']!,
              ),
            ),
          ],
        ),
      ],
    );

    await _pumpWithProviders(
      tester,
      MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        locale: const Locale('en'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
    await _pumpProviderFrames(tester);

    final sessionCard = find.ancestor(
      of: find.text('Session A').first,
      matching: find.byType(InkWell),
    );
    await tester.tap(sessionCard.first);
    await tester.pumpAndSettle();

    expect(find.text('Sessionize'), findsOneWidget);
  });
}

Future<void> _pumpProviderFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

Future<void> _pumpSessionDetailsPage(
  WidgetTester tester, {
  required String sessionId,
  SessionRepository? sessionRepository,
  VenueRepository? venueRepository,
}) async {
  await _pumpWithProviders(
    tester,
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: SessionDetailsPage(sessionId: sessionId),
    ),
    sessionRepository: sessionRepository,
    venueRepository: venueRepository,
  );
}

Future<void> _pumpWithProviders(
  WidgetTester tester,
  Widget child, {
  SessionRepository? sessionRepository,
  VenueRepository? venueRepository,
}) async {
  final preferences = await _prepareTester(tester);

  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          sessionRepositoryProvider.overrideWithValue(
            sessionRepository ?? _FakeSessionRepository(_sessions),
          ),
          sessionTimetableTimelineEventRepositoryProvider.overrideWithValue(
            const _FakeTimelineEventRepository([]),
          ),
          sessionTimetableVenueRepositoryProvider.overrideWithValue(
            venueRepository ?? _FakeVenueRepository(_venues),
          ),
          sessionTimetableSpeakerRepositoryProvider.overrideWithValue(
            _FakeSpeakerRepository(_speakers),
          ),
        ],
        child: child,
      ),
    ),
  );
}

Future<SharedPreferences> _prepareTester(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

final _sessions = [
  Session(
    id: 'session-a',
    title: const LocaleMap(ja: 'セッション A', en: 'Session A'),
    description: const LocaleMap(ja: '説明 A', en: 'Description A'),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 29, 1),
    endsAt: DateTime.utc(2026, 10, 29, 1, 45),
    venueId: 'hall-a',
    speakerIds: const ['speaker-a'],
    sessionizeUrl: 'https://sessionize.com/flutterkaigi-2026/session-a',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Session(
    id: 'session-without-optionals',
    title: const LocaleMap(
      ja: '任意項目なし',
      en: 'No Optional Fields',
    ),
    description: const LocaleMap(ja: '', en: ''),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 29, 2),
    endsAt: DateTime.utc(2026, 10, 29, 2, 45),
    venueId: 'hall-a',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

Session _sessionWithSessionizeUrl({
  required String id,
  required String sessionizeUrl,
}) => Session(
  id: id,
  title: LocaleMap(ja: id, en: id),
  description: LocaleMap(ja: id, en: id),
  primaryLocale: 'en',
  startsAt: DateTime.utc(2026, 10, 29, 1),
  endsAt: DateTime.utc(2026, 10, 29, 1, 45),
  venueId: 'hall-a',
  sessionizeUrl: sessionizeUrl,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _venues = [
  Venue(
    id: 'hall-a',
    name: const LocaleMap(ja: 'ホール A', en: 'Hall A'),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

final _speakers = [
  Speaker(
    id: 'speaker-a',
    name: 'Speaker A',
    bio: 'Bio A',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

final class _FakeSessionRepository implements SessionRepository {
  const _FakeSessionRepository(this._sessions);

  final List<Session> _sessions;

  @override
  Stream<List<Session>> watchAll() => Stream.value(_sessions);

  @override
  Future<void> save(Session session) async {}

  @override
  Future<void> delete(String id) async {}
}

final class _FakeVenueRepository implements VenueRepository {
  const _FakeVenueRepository(this._venues);

  final List<Venue> _venues;

  @override
  Stream<List<Venue>> watchAll() => Stream.value(_venues);

  @override
  Future<void> save(Venue venue) async {}

  @override
  Future<void> delete(String id) async {}
}

final class _FakeTimelineEventRepository implements TimelineEventRepository {
  const _FakeTimelineEventRepository(this._timelineEvents);

  final List<TimelineEvent> _timelineEvents;

  @override
  Stream<List<TimelineEvent>> watchAll() => Stream.value(_timelineEvents);

  @override
  Future<void> save(TimelineEvent timelineEvent) async {}

  @override
  Future<void> delete(String id) async {}
}

final class _FakeSpeakerRepository implements SpeakerRepository {
  const _FakeSpeakerRepository(this._speakers);

  final List<Speaker> _speakers;

  @override
  Stream<List<Speaker>> watchAll() => Stream.value(_speakers);

  @override
  Future<void> save(Speaker speaker) async {}

  @override
  Future<void> delete(String id) async {}
}
