import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/session/data/provider/bookmarked_sessions_provider.dart';
import 'package:app/feature/session/data/provider/session_repository.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/data/provider/session_timetable_repository.dart';
import 'package:app/feature/session/ui/page/bookmarked_sessions_page.dart';
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
  test('builds the typed bookmarked sessions route location', () {
    expect(
      const BookmarkedSessionsRoute().location,
      '/sessions/bookmarked',
    );
  });

  testWidgets('opens the bookmarked sessions screen from the timetable app bar', (tester) async {
    final router = _buildRouter(initialLocation: '/sessions');

    await _pumpWithProviders(
      tester,
      MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        locale: const Locale('en'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
      bookmarkedIds: const {'early-session'},
    );
    await _pumpProviderFrames(tester);

    await tester.tap(find.byTooltip('ブックマークしたセッション'));
    await tester.pumpAndSettle();

    expect(find.text('ブックマークしたセッション'), findsWidgets);
    expect(find.text('Early Session'), findsOneWidget);
  });

  testWidgets('shows only bookmarked sessions sorted by start time', (tester) async {
    await _pumpBookmarkedRoute(
      tester,
      bookmarkedIds: const {'late-session', 'early-session', 'missing-session'},
    );

    expect(find.text('Early Session'), findsOneWidget);
    expect(find.text('Late Session'), findsOneWidget);
    expect(find.text('Middle Session'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Early Session').first).dy,
      lessThan(tester.getTopLeft(find.text('Late Session').first).dy),
    );
  });

  testWidgets('opens session details with the bookmarked session ID', (tester) async {
    await _pumpBookmarkedRoute(tester, bookmarkedIds: const {'early-session'});

    await tester.tap(_cardForText('Early Session'));
    await tester.pumpAndSettle();

    expect(find.text('Early details'), findsOneWidget);
    expect(find.text('Room A'), findsWidgets);
  });

  testWidgets('removing a bookmark immediately removes it from the bookmarked screen', (tester) async {
    await _pumpBookmarkedRoute(tester, bookmarkedIds: const {'early-session'});

    await tester.tap(find.byTooltip('ブックマークから削除'));
    await tester.pumpAndSettle();

    expect(find.text('Early Session'), findsNothing);
    expect(find.text('ブックマークしたセッションはありません'), findsOneWidget);
  });

  testWidgets('bookmark state added from the timetable is visible on the bookmarked screen', (tester) async {
    final router = _buildRouter(initialLocation: '/sessions');

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

    await tester.tap(find.byTooltip('ブックマークに追加').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('ブックマークしたセッション'));
    await tester.pumpAndSettle();

    expect(find.text('Early Session'), findsOneWidget);
  });

  testWidgets('bookmark removal from details is reflected after returning to bookmarks', (tester) async {
    await _pumpBookmarkedRoute(tester, bookmarkedIds: const {'early-session'});

    await tester.tap(_cardForText('Early Session'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('ブックマークから削除'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('ブックマークしたセッションはありません'), findsOneWidget);
  });

  testWidgets('shows a loading state while bookmarked session data is loading', (tester) async {
    await _pumpBookmarkedPageWithState(tester, const AsyncLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error state when the session provider fails', (tester) async {
    await _pumpBookmarkedRoute(
      tester,
      bookmarkedIds: const {'early-session'},
      sessionListValue: AsyncError(Exception('sessions'), StackTrace.current),
    );

    expect(find.text('ブックマークしたセッションを取得できませんでした'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
  });

  testWidgets('shows an error state when the bookmark provider fails', (tester) async {
    await _pumpBookmarkedPageWithState(
      tester,
      AsyncError(Exception('bookmarks'), StackTrace.current),
    );

    expect(find.text('ブックマークしたセッションを取得できませんでした'), findsOneWidget);
  });

  testWidgets('retry action is available from the bookmarked screen error state', (tester) async {
    await _pumpBookmarkedPageWithState(
      tester,
      AsyncError(Exception('bookmarks'), StackTrace.current),
    );

    expect(find.text('ブックマークしたセッションを取得できませんでした'), findsOneWidget);
    await tester.tap(find.text('再試行'));
    await tester.pump();

    expect(find.text('再試行'), findsOneWidget);
  });

  testWidgets('shows an empty state when no sessions are bookmarked', (tester) async {
    await _pumpBookmarkedRoute(tester);

    expect(find.text('ブックマークしたセッションはありません'), findsOneWidget);
    expect(find.text('気になるセッションをブックマークすると、ここからすぐに見つけられます'), findsOneWidget);
    expect(find.text('タイムテーブルを開く'), findsOneWidget);
  });

  testWidgets('renders bookmarked sessions with missing optional related data safely', (tester) async {
    await _pumpBookmarkedRoute(tester, bookmarkedIds: const {'no-optionals-session'});

    expect(find.text('No Optional Fields'), findsOneWidget);
    expect(find.text('会場未定'), findsOneWidget);
    expect(find.text('登壇者未定'), findsOneWidget);
  });
}

Finder _cardForText(String text) {
  return find
      .ancestor(
        of: find.text(text).first,
        matching: find.byType(InkWell),
      )
      .first;
}

GoRouter _buildRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/sessions',
        builder: (context, state) => const SessionTimetablePage(),
        routes: [
          GoRoute(
            path: 'bookmarked',
            builder: (context, state) => const BookmarkedSessionsPage(),
          ),
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
}

Future<void> _pumpBookmarkedRoute(
  WidgetTester tester, {
  Set<String> bookmarkedIds = const {},
  SessionRepository? sessionRepository,
  AsyncValue<List<Session>>? sessionListValue,
}) async {
  final router = _buildRouter(initialLocation: '/sessions/bookmarked');

  await _pumpWithProviders(
    tester,
    MaterialApp.router(
      routerConfig: router,
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      locale: const Locale('en'),
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    ),
    bookmarkedIds: bookmarkedIds,
    sessionRepository: sessionRepository,
    sessionListValue: sessionListValue,
  );
  await _pumpProviderFrames(tester);
}

Future<void> _pumpBookmarkedPageWithState(
  WidgetTester tester,
  AsyncValue<BookmarkedSessionsData> state,
) async {
  final preferences = await _prepareTester(bookmarkedIds: const {});

  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          bookmarkedSessionsProvider.overrideWithValue(state),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          locale: const Locale('en'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const BookmarkedSessionsPage(),
        ),
      ),
    ),
  );
  await _pumpProviderFrames(tester);
}

Future<void> _pumpWithProviders(
  WidgetTester tester,
  Widget child, {
  Set<String> bookmarkedIds = const {},
  SessionRepository? sessionRepository,
  AsyncValue<List<Session>>? sessionListValue,
}) async {
  final preferences = await _prepareTester(bookmarkedIds: bookmarkedIds);

  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          sessionRepositoryProvider.overrideWithValue(
            sessionRepository ?? _FakeSessionRepository(_sessions),
          ),
          if (sessionListValue != null) sessionListProvider.overrideWithValue(sessionListValue),
          sessionTimetableTimelineEventRepositoryProvider.overrideWithValue(
            const _FakeTimelineEventRepository([]),
          ),
          sessionTimetableVenueRepositoryProvider.overrideWithValue(
            _FakeVenueRepository(_venues),
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

Future<SharedPreferences> _prepareTester({
  required Set<String> bookmarkedIds,
}) async {
  final values = <String, Object>{
    'bookmarked_session_ids': bookmarkedIds.toList(),
  };
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<void> _pumpProviderFrames(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 1));
}

final _sessions = [
  Session(
    id: 'middle-session',
    title: const LocaleMap(ja: 'Middle Session', en: 'Middle Session'),
    description: const LocaleMap(ja: 'Middle details', en: 'Middle details'),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 31, 2),
    endsAt: DateTime.utc(2026, 10, 31, 2, 45),
    venueId: 'room-b',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Session(
    id: 'late-session',
    title: const LocaleMap(ja: 'Late Session', en: 'Late Session'),
    description: const LocaleMap(ja: 'Late details', en: 'Late details'),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 31, 3),
    endsAt: DateTime.utc(2026, 10, 31, 3, 45),
    venueId: 'room-b',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Session(
    id: 'early-session',
    title: const LocaleMap(ja: 'Early Session', en: 'Early Session'),
    description: const LocaleMap(ja: 'Early details', en: 'Early details'),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 31, 1),
    endsAt: DateTime.utc(2026, 10, 31, 1, 45),
    venueId: 'room-a',
    speakerIds: const ['speaker-a'],
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Session(
    id: 'no-optionals-session',
    title: const LocaleMap(ja: 'No Optional Fields', en: 'No Optional Fields'),
    description: const LocaleMap(ja: '', en: ''),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 31, 4),
    endsAt: DateTime.utc(2026, 10, 31, 4, 45),
    venueId: 'missing-room',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

final _venues = [
  Venue(
    id: 'room-a',
    name: const LocaleMap(ja: 'Room A', en: 'Room A'),
    order: 1,
    createdAt: _createdAt,
    updatedAt: _createdAt,
  ),
  Venue(
    id: 'room-b',
    name: const LocaleMap(ja: 'Room B', en: 'Room B'),
    order: 2,
    createdAt: _createdAt,
    updatedAt: _createdAt,
  ),
];

final _speakers = [
  Speaker(
    id: 'speaker-a',
    name: 'Speaker A',
    createdAt: _createdAt,
    updatedAt: _createdAt,
  ),
];

final _createdAt = DateTime.utc(2026);

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
