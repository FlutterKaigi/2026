import 'dart:async';

import 'package:app/core/designsystem/theme/app_theme.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/session/data/provider/session_repository.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/data/provider/session_timetable_repository.dart';
import 'package:app/feature/session/ui/page/session_timetable_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('uses a compact DroidKaigi-style day switcher at mobile width', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_loadedTimetable),
    );

    expect(find.byType(SegmentedButton<int>), findsOneWidget);
    expect(find.text('1日目 (10/31)'), findsOneWidget);
    expect(find.text('会場'), findsNothing);
    expect(find.text('時刻表示'), findsNothing);
    expect(find.text('2026/10/31'), findsNothing);
    expect(find.text('JA'), findsOneWidget);
    expect(find.text('Description'), findsNothing);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final appBarTitle = appBar.title! as Text;
    expect(appBar.toolbarHeight, 52);
    expect(appBarTitle.style?.fontSize, 16);
    expect(appBarTitle.style?.fontWeight, FontWeight.w700);

    expect(find.byIcon(Icons.tune), findsNothing);
    expect(find.text('時刻表示'), findsNothing);
  });

  testWidgets('switches between list and room timeline views', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_loadedTimetable),
    );

    expect(find.byTooltip('会場別タイムラインに切り替え'), findsOneWidget);

    await tester.tap(find.byTooltip('会場別タイムラインに切り替え'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('リスト表示に切り替え'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('10:15-11:00'), findsOneWidget);
    expect(find.text('Room A'), findsOneWidget);
    expect(find.text('JA'), findsOneWidget);
  });

  testWidgets('orders room columns by venue order instead of the earliest session', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_venueOrderTimetable),
    );

    await tester.tap(find.byTooltip('会場別タイムラインに切り替え'));
    await tester.pumpAndSettle();

    final roomAHeader = tester.getCenter(find.text('Room A'));
    final roomBHeader = tester.getCenter(find.text('Room B'));
    final sharedHeader = tester.getCenter(find.text('共通'));

    expect(sharedHeader.dx, lessThan(roomAHeader.dx));
    expect(roomAHeader.dx, lessThan(roomBHeader.dx));
  });

  testWidgets('uses the venue id as a stable tie-breaker for room columns', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_equalVenueOrderTimetable),
    );

    await tester.tap(find.byTooltip('会場別タイムラインに切り替え'));
    await tester.pumpAndSettle();

    final roomAHeader = tester.getCenter(find.text('Room A'));
    final roomBHeader = tester.getCenter(find.text('Room B'));

    expect(roomAHeader.dx, lessThan(roomBHeader.dx));
  });

  testWidgets('places overlapping room entries in separate horizontal lanes', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_overlappingTimetable),
    );

    await tester.tap(find.byTooltip('会場別タイムラインに切り替え'));
    await tester.pumpAndSettle();

    final sessionRect = tester.getRect(find.text('Compact Session'));
    final eventRect = tester.getRect(find.text('Overlap Event'));

    expect(sessionRect.overlaps(eventRect), isFalse);
    expect(sessionRect.top, lessThan(eventRect.bottom));
    expect(eventRect.top, lessThan(sessionRect.bottom));
  });

  testWidgets('stacks simultaneous list entries vertically', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_parallelTimetable),
    );

    final firstRect = tester.getRect(find.text('Compact Session'));
    final secondRect = tester.getRect(find.text('Parallel Session'));

    expect(firstRect.left, secondRect.left);
    expect(firstRect.bottom, lessThan(secondRect.top));
    expect(find.byType(Scrollbar), findsNothing);
  });

  testWidgets('keeps day tabs fixed and changes days by swiping or tapping', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_twoDayTimetable),
    );

    expect(
      find.ancestor(
        of: find.byType(SegmentedButton<int>),
        matching: find.byType(PageView),
      ),
      findsNothing,
    );
    expect(find.text('Compact Session'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Day Two Session'), findsOneWidget);
    expect(
      tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>)).selected,
      {1},
    );

    await tester.tap(find.text('1日目 (10/31)'));
    await tester.pumpAndSettle();

    expect(find.text('Compact Session'), findsOneWidget);
  });

  testWidgets('keeps a valid day selected when the available day count shrinks', (tester) async {
    final sessionRepository = _MutableSessionRepository([
      _session,
      _dayTwoSession,
    ]);
    addTearDown(sessionRepository.dispose);
    await _pumpTimetableRepositories(
      tester,
      sessionRepository: sessionRepository,
      timelineEventRepository: _CountingTimelineEventRepository(),
      venueRepository: _CountingVenueRepository(),
      speakerRepository: _CountingSpeakerRepository(),
    );

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Day Two Session'), findsOneWidget);

    sessionRepository.emit([_session]);
    await _pumpProviderFrames(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Compact Session'), findsOneWidget);
    expect(
      tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>)).selected,
      {0},
    );
  });

  testWidgets('always uses 24-hour time labels at compact width', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_loadedTimetable),
      preferences: const {'session_time_format': 'amPm'},
    );

    expect(find.text('10:15'), findsOneWidget);
    expect(find.textContaining('午前'), findsNothing);
    expect(find.byType(RefreshIndicator), findsNothing);
  });

  testWidgets('does not add pull-to-refresh to the empty timetable', (tester) async {
    await _pumpTimetableState(
      tester,
      const AsyncData(_emptyTimetable),
    );

    expect(find.byType(RefreshIndicator), findsNothing);
    expect(find.text('タイムテーブルはまだ公開されていません'), findsOneWidget);
    expect(find.text('時刻表示'), findsNothing);
  });

  testWidgets('retry reloads every timetable repository after an error', (tester) async {
    final sessionRepository = _RetrySessionRepository();
    final timelineEventRepository = _CountingTimelineEventRepository();
    final venueRepository = _CountingVenueRepository();
    final speakerRepository = _CountingSpeakerRepository();
    addTearDown(sessionRepository.dispose);
    await _pumpTimetableRepositories(
      tester,
      sessionRepository: sessionRepository,
      timelineEventRepository: timelineEventRepository,
      venueRepository: venueRepository,
      speakerRepository: speakerRepository,
    );
    sessionRepository.failFirstWatch();
    await _pumpProviderFrames(tester);

    expect(sessionRepository.watchCount, 1);
    expect(timelineEventRepository.watchCount, 1);
    expect(venueRepository.watchCount, 1);
    expect(speakerRepository.watchCount, 1);
    expect(find.text('データを読み込めませんでした'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);

    await tester.tap(find.text('再試行'));
    await _pumpProviderFrames(tester);

    expect(sessionRepository.watchCount, 2);
    expect(timelineEventRepository.watchCount, 2);
    expect(venueRepository.watchCount, 2);
    expect(speakerRepository.watchCount, 2);
    expect(find.text('Compact Session'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsNothing);
  });
}

Future<void> _pumpTimetableState(
  WidgetTester tester,
  AsyncValue<SessionTimetableData> state, {
  Map<String, Object> preferences = const {},
}) async {
  final sharedPreferences = await _prepareTester(tester, preferences);

  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          sessionTimetableProvider.overrideWithValue(state),
        ],
        child: _testApp(),
      ),
    ),
  );
  await _pumpProviderFrames(tester);
}

Future<void> _pumpTimetableRepositories(
  WidgetTester tester, {
  required SessionRepository sessionRepository,
  required TimelineEventRepository timelineEventRepository,
  required VenueRepository venueRepository,
  required SpeakerRepository speakerRepository,
}) async {
  final sharedPreferences = await _prepareTester(tester, const {});

  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          sessionRepositoryProvider.overrideWithValue(sessionRepository),
          sessionTimetableTimelineEventRepositoryProvider.overrideWithValue(
            timelineEventRepository,
          ),
          sessionTimetableVenueRepositoryProvider.overrideWithValue(
            venueRepository,
          ),
          sessionTimetableSpeakerRepositoryProvider.overrideWithValue(
            speakerRepository,
          ),
        ],
        child: _testApp(),
      ),
    ),
  );
  await _pumpProviderFrames(tester);
}

Widget _testApp() {
  return MaterialApp(
    theme: lightTheme(),
    locale: const Locale('ja'),
    supportedLocales: AppLocaleUtils.supportedLocales,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const SessionTimetablePage(),
  );
}

Future<SharedPreferences> _prepareTester(
  WidgetTester tester,
  Map<String, Object> preferences,
) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues(preferences);
  return SharedPreferences.getInstance();
}

Future<void> _pumpProviderFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 1));
}

const _emptyTimetable = SessionTimetableData(
  days: [],
  availableDates: [],
  selectedDate: null,
  selectedDay: null,
  hasAnyEntries: false,
);

final _session = Session(
  id: 'compact-session',
  title: const LocaleMap(ja: 'Compact Session', en: 'Compact Session'),
  description: const LocaleMap(ja: 'Description', en: 'Description'),
  primaryLocale: 'ja',
  startsAt: DateTime.utc(2026, 10, 31, 1, 15),
  endsAt: DateTime.utc(2026, 10, 31, 2),
  venueId: 'room-a',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _venue = Venue(
  id: 'room-a',
  name: const LocaleMap(ja: 'Room A', en: 'Room A'),
  order: 1,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _venueB = Venue(
  id: 'room-b',
  name: const LocaleMap(ja: 'Room B', en: 'Room B'),
  order: 2,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _entry = SessionTimetableEntry.session(
  session: _session,
  venue: _venue,
  speakers: const [],
);

final _parallelSession = Session(
  id: 'parallel-session',
  title: const LocaleMap(ja: 'Parallel Session', en: 'Parallel Session'),
  description: const LocaleMap(ja: 'Description', en: 'Description'),
  primaryLocale: 'en',
  startsAt: _session.startsAt,
  endsAt: _session.endsAt,
  venueId: 'room-b',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _parallelEntry = SessionTimetableEntry.session(
  session: _parallelSession,
  venue: _venueB,
  speakers: const [],
);

final _earlyRoomBSession = Session(
  id: 'early-room-b-session',
  title: const LocaleMap(
    ja: 'Early Room B Session',
    en: 'Early Room B Session',
  ),
  description: const LocaleMap(ja: 'Description', en: 'Description'),
  primaryLocale: 'en',
  startsAt: DateTime.utc(2026, 10, 31),
  endsAt: DateTime.utc(2026, 10, 31, 0, 30),
  venueId: 'room-b',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _earlyRoomBEntry = SessionTimetableEntry.session(
  session: _earlyRoomBSession,
  venue: _venueB,
  speakers: const [],
);

final _sharedEvent = TimelineEvent(
  id: 'shared-event',
  title: const LocaleMap(ja: 'Shared Event', en: 'Shared Event'),
  startsAt: DateTime.utc(2026, 10, 31, 3),
  endsAt: DateTime.utc(2026, 10, 31, 3, 30),
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _sharedEntry = SessionTimetableEntry.timelineEvent(
  timelineEvent: _sharedEvent,
  venue: null,
);

final _equalOrderVenueA = Venue(
  id: 'room-a',
  name: const LocaleMap(ja: 'Room A', en: 'Room A'),
  order: 1,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _equalOrderVenueB = Venue(
  id: 'room-b',
  name: const LocaleMap(ja: 'Room B', en: 'Room B'),
  order: 1,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _dayTwoSession = Session(
  id: 'day-two-session',
  title: const LocaleMap(ja: 'Day Two Session', en: 'Day Two Session'),
  description: const LocaleMap(ja: 'Description', en: 'Description'),
  primaryLocale: 'en',
  startsAt: DateTime.utc(2026, 11, 1, 1, 15),
  endsAt: DateTime.utc(2026, 11, 1, 2),
  venueId: 'room-a',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _dayTwoEntry = SessionTimetableEntry.session(
  session: _dayTwoSession,
  venue: _venue,
  speakers: const [],
);

final _overlapEvent = TimelineEvent(
  id: 'overlap-event',
  title: const LocaleMap(ja: 'Overlap Event', en: 'Overlap Event'),
  startsAt: DateTime.utc(2026, 10, 31, 1, 30),
  endsAt: DateTime.utc(2026, 10, 31, 1, 50),
  venueId: 'room-a',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _overlapEntry = SessionTimetableEntry.timelineEvent(
  timelineEvent: _overlapEvent,
  venue: _venue,
);

final _day = SessionTimetableDay(
  date: DateTime(2026, 10, 31),
  entries: [_entry],
);

final _loadedTimetable = SessionTimetableData(
  days: [_day],
  availableDates: [_day.date],
  selectedDate: _day.date,
  selectedDay: _day,
  hasAnyEntries: true,
);

final _parallelDay = SessionTimetableDay(
  date: _day.date,
  entries: [_entry, _parallelEntry],
);

final _parallelTimetable = SessionTimetableData(
  days: [_parallelDay],
  availableDates: [_parallelDay.date],
  selectedDate: _parallelDay.date,
  selectedDay: _parallelDay,
  hasAnyEntries: true,
);

final _venueOrderDay = SessionTimetableDay(
  date: _day.date,
  entries: [_earlyRoomBEntry, _entry, _sharedEntry],
);

final _venueOrderTimetable = SessionTimetableData(
  days: [_venueOrderDay],
  availableDates: [_venueOrderDay.date],
  selectedDate: _venueOrderDay.date,
  selectedDay: _venueOrderDay,
  hasAnyEntries: true,
);

final _equalVenueOrderDay = SessionTimetableDay(
  date: _day.date,
  entries: [
    SessionTimetableEntry.session(
      session: _earlyRoomBSession,
      venue: _equalOrderVenueB,
      speakers: const [],
    ),
    SessionTimetableEntry.session(
      session: _session,
      venue: _equalOrderVenueA,
      speakers: const [],
    ),
  ],
);

final _equalVenueOrderTimetable = SessionTimetableData(
  days: [_equalVenueOrderDay],
  availableDates: [_equalVenueOrderDay.date],
  selectedDate: _equalVenueOrderDay.date,
  selectedDay: _equalVenueOrderDay,
  hasAnyEntries: true,
);

final _secondDay = SessionTimetableDay(
  date: DateTime(2026, 11),
  entries: [_dayTwoEntry],
);

final _twoDayTimetable = SessionTimetableData(
  days: [_day, _secondDay],
  availableDates: [_day.date, _secondDay.date],
  selectedDate: _day.date,
  selectedDay: _day,
  hasAnyEntries: true,
);

final _overlappingTimetable = SessionTimetableData(
  days: [
    SessionTimetableDay(
      date: _day.date,
      entries: [_entry, _overlapEntry],
    ),
  ],
  availableDates: [_day.date],
  selectedDate: _day.date,
  selectedDay: SessionTimetableDay(
    date: _day.date,
    entries: [_entry, _overlapEntry],
  ),
  hasAnyEntries: true,
);

final class _RetrySessionRepository implements SessionRepository {
  final _firstWatchController = StreamController<List<Session>>(sync: true);
  int watchCount = 0;

  @override
  Stream<List<Session>> watchAll() {
    watchCount++;
    return watchCount == 1 ? _firstWatchController.stream : Stream.value([_session]);
  }

  void failFirstWatch() {
    _firstWatchController.addError(Exception('failed to load sessions'));
  }

  Future<void> dispose() => _firstWatchController.close();

  @override
  Future<void> save(Session session) async {}

  @override
  Future<void> delete(String id) async {}
}

final class _MutableSessionRepository implements SessionRepository {
  _MutableSessionRepository(this._sessions);

  List<Session> _sessions;
  final _controller = StreamController<List<Session>>.broadcast(sync: true);

  @override
  Stream<List<Session>> watchAll() async* {
    yield _sessions;
    yield* _controller.stream;
  }

  void emit(List<Session> sessions) {
    _sessions = sessions;
    _controller.add(sessions);
  }

  Future<void> dispose() => _controller.close();

  @override
  Future<void> save(Session session) async {}

  @override
  Future<void> delete(String id) async {}
}

final class _CountingTimelineEventRepository implements TimelineEventRepository {
  int watchCount = 0;

  @override
  Stream<List<TimelineEvent>> watchAll() {
    watchCount++;
    return Stream.value(const []);
  }

  @override
  Future<void> save(TimelineEvent timelineEvent) async {}

  @override
  Future<void> delete(String id) async {}
}

final class _CountingVenueRepository implements VenueRepository {
  int watchCount = 0;

  @override
  Stream<List<Venue>> watchAll() {
    watchCount++;
    return Stream.value([_venue]);
  }

  @override
  Future<void> save(Venue venue) async {}

  @override
  Future<void> delete(String id) async {}
}

final class _CountingSpeakerRepository implements SpeakerRepository {
  int watchCount = 0;

  @override
  Stream<List<Speaker>> watchAll() {
    watchCount++;
    return Stream.value(const []);
  }

  @override
  Future<void> save(Speaker speaker) async {}

  @override
  Future<void> delete(String id) async {}
}
