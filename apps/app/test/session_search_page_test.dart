import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/session/data/provider/session_search_provider.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/page/session_search_page.dart';
import 'package:app/feature/session/ui/page/session_timetable_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('builds the typed session search route location', () {
    expect(
      const SessionSearchRoute().location,
      '/sessions/search',
    );
  });

  test('searches both translations, descriptions, and speaker names', () {
    expect(
      _search(query: 'State').map((entry) => entry.id),
      ['state-session'],
    );
    expect(
      _search(query: '描画').map((entry) => entry.id),
      ['animation-session'],
    );
    expect(
      _search(query: 'Alice').map((entry) => entry.id),
      ['state-session'],
    );
  });

  test('filters sessions by event day and session type', () {
    expect(
      buildSessionSearchResults(
        data: _timetable,
        criteria: SessionSearchCriteria(
          date: _dayTwo.date,
        ),
      ).map((entry) => entry.id),
      ['workshop-session'],
    );
    expect(
      buildSessionSearchResults(
        data: _timetable,
        criteria: const SessionSearchCriteria(
          type: SessionSearchTypeFilter.handsOn,
        ),
      ).map((entry) => entry.id),
      ['workshop-session'],
    );
  });

  test('filters sessions by primary locale', () {
    expect(
      buildSessionSearchResults(
        data: _timetable,
        criteria: const SessionSearchCriteria(
          language: SessionSearchLanguageFilter.en,
        ),
      ).map((entry) => entry.id),
      ['animation-session'],
    );
    expect(
      buildSessionSearchResults(
        data: _timetable,
        criteria: const SessionSearchCriteria(
          language: SessionSearchLanguageFilter.ja,
        ),
      ).map((entry) => entry.id),
      ['state-session', 'workshop-session'],
    );
  });

  test('does not show every session before the user enters criteria', () {
    expect(
      buildSessionSearchResults(
        data: _timetable,
        criteria: const SessionSearchCriteria(),
      ),
      isEmpty,
    );
  });

  testWidgets('opens search with a reflected URL and navigates to a result', (tester) async {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    addTearDown(() => GoRouter.optionURLReflectsImperativeAPIs = false);
    final router = GoRouter(
      initialLocation: '/sessions',
      routes: [
        GoRoute(
          path: '/sessions',
          builder: (context, state) => const SessionTimetablePage(),
          routes: [
            GoRoute(
              path: 'search',
              builder: (context, state) => const SessionSearchPage(),
            ),
            GoRoute(
              path: ':sessionId',
              builder: (context, state) => Scaffold(
                body: Text('details:${state.pathParameters['sessionId']}'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await _pumpSearchApp(
      tester,
      router: router,
    );

    await tester.tap(find.byTooltip('セッションを検索'));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/sessions/search',
    );
    expect(find.text('セッションを探す'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'State');
    await tester.pumpAndSettle();

    expect(find.text('状態管理'), findsOneWidget);
    expect(find.text('アニメーション'), findsNothing);
    expect(find.text('1件のセッション'), findsOneWidget);

    await tester.tap(
      find.ancestor(
        of: find.text('状態管理'),
        matching: find.byType(InkWell),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/sessions/state-session',
    );
    expect(find.text('details:state-session'), findsOneWidget);
  });

  testWidgets('filters search results by session type', (tester) async {
    await _pumpSearchApp(
      tester,
      home: const SessionSearchPage(),
    );

    await tester.tap(find.byTooltip('種類で絞り込み'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ハンズオン').last);
    await tester.pumpAndSettle();

    expect(find.text('ハンズオンワークショップ'), findsOneWidget);
    expect(find.text('状態管理'), findsNothing);
    expect(find.text('1件のセッション'), findsOneWidget);
  });

  testWidgets('filters search results by language', (tester) async {
    await _pumpSearchApp(
      tester,
      home: const SessionSearchPage(),
    );

    await tester.tap(find.byTooltip('言語で絞り込み'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EN').last);
    await tester.pumpAndSettle();

    expect(find.text('アニメーション'), findsOneWidget);
    expect(find.text('状態管理'), findsNothing);
    expect(find.text('1件のセッション'), findsOneWidget);
  });

  testWidgets('groups matching search results by event day', (tester) async {
    await _pumpSearchApp(
      tester,
      home: const SessionSearchPage(),
    );

    await tester.enterText(find.byType(TextField), 'on');
    await tester.pumpAndSettle();

    expect(find.text('3件のセッション'), findsOneWidget);
    expect(find.text('1日目 (10/29)'), findsOneWidget);
    expect(find.text('2日目 (10/30)'), findsOneWidget);
  });
}

List<SessionTimetableEntry> _search({required String query}) {
  return buildSessionSearchResults(
    data: _timetable,
    criteria: SessionSearchCriteria(query: query),
  );
}

Future<void> _pumpSearchApp(
  WidgetTester tester, {
  GoRouter? router,
  Widget? home,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  final app = router == null
      ? MaterialApp(
          home: home,
          locale: const Locale('ja'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        )
      : MaterialApp.router(
          routerConfig: router,
          locale: const Locale('ja'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        );

  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          sessionTimetableProvider.overrideWithValue(
            AsyncData(_timetable),
          ),
        ],
        child: app,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _roomA = Venue(
  id: 'room-a',
  name: const LocaleMap(ja: 'ホール A', en: 'Hall A'),
  order: 1,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _alice = Speaker(
  id: 'alice',
  name: 'Alice',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _stateSession = Session(
  id: 'state-session',
  title: const LocaleMap(
    ja: '状態管理',
    en: 'State Management',
  ),
  description: const LocaleMap(
    ja: '大規模アプリの設計',
    en: 'Architecture for large applications',
  ),
  primaryLocale: 'ja',
  startsAt: DateTime.utc(2026, 10, 29, 1, 15),
  endsAt: DateTime.utc(2026, 10, 29, 2),
  venueId: _roomA.id,
  speakerIds: const ['alice'],
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _animationSession = Session(
  id: 'animation-session',
  title: const LocaleMap(
    ja: 'アニメーション',
    en: 'Animations',
  ),
  description: const LocaleMap(
    ja: '描画を滑らかにする方法',
    en: 'Smooth rendering',
  ),
  primaryLocale: 'en',
  startsAt: DateTime.utc(2026, 10, 29, 2, 15),
  endsAt: DateTime.utc(2026, 10, 29, 3),
  venueId: _roomA.id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _workshopSession = Session(
  id: 'workshop-session',
  title: const LocaleMap(
    ja: 'ハンズオンワークショップ',
    en: 'Hands-on Workshop',
  ),
  description: const LocaleMap(
    ja: '実際にコードを書きます',
    en: 'Write code together',
  ),
  primaryLocale: 'ja',
  startsAt: DateTime.utc(2026, 10, 30, 1, 15),
  endsAt: DateTime.utc(2026, 10, 30, 2, 15),
  venueId: _roomA.id,
  isHandsOn: true,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _stateEntry = SessionTimetableEntry.session(
  session: _stateSession,
  venue: _roomA,
  speakers: [_alice],
);

final _animationEntry = SessionTimetableEntry.session(
  session: _animationSession,
  venue: _roomA,
  speakers: const [],
);

final _workshopEntry = SessionTimetableEntry.session(
  session: _workshopSession,
  venue: _roomA,
  speakers: const [],
);

final _dayOne = SessionTimetableDay(
  date: DateTime(2026, 10, 29),
  entries: [_stateEntry, _animationEntry],
);

final _dayTwo = SessionTimetableDay(
  date: DateTime(2026, 10, 30),
  entries: [_workshopEntry],
);

final _timetable = SessionTimetableData(
  days: [_dayOne, _dayTwo],
  availableDates: [_dayOne.date, _dayTwo.date],
  selectedDate: _dayOne.date,
  selectedDay: _dayOne,
  hasAnyEntries: true,
);
