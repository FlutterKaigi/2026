import 'dart:async';

import 'package:app/core/designsystem/theme/app_theme.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/core/ui/widget/app_network_image.dart';
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
  for (final viewport in _responsiveRoomViewports.entries) {
    testWidgets('keeps the full room table stable at ${viewport.key}', (tester) async {
      await _pumpTimetableState(
        tester,
        AsyncData(_stressRoomTimetable),
        viewportSize: Size(viewport.value, 1000),
      );

      await tester.tap(find.byTooltip('会場別タイムラインに切り替え'));
      await tester.pumpAndSettle();

      final roomScroll = find.byKey(
        ValueKey(('room-schedule-scroll', _stressRoomDay.date)),
      );
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: roomScroll,
          matching: find.byType(Scrollable),
        ),
      );
      final lastTitle = tester.widget<Text>(
        find.byKey(const ValueKey('room-session-title-stress-session-29')),
      );

      expect(lastTitle.maxLines, isNull);
      expect(lastTitle.overflow, isNull);
      expect(
        find.byKey(const ValueKey('session-speaker-avatar-stress-speaker-29')),
        findsOneWidget,
      );
      expect(find.byType(ClipOval), findsNWidgets(30));
      expect(find.byType(AppNetworkImage), findsNWidgets(30));
      for (final image in tester.widgetList<AppNetworkImage>(
        find.byType(AppNetworkImage),
      )) {
        expect(
          image.webHtmlElementStrategy,
          WebHtmlElementStrategy.fallback,
        );
      }

      if (scrollable.position.maxScrollExtent > 0) {
        final scrollRect = tester.getRect(roomScroll);
        await tester.dragFrom(
          Offset(scrollRect.center.dx, scrollRect.top + 24),
          const Offset(-200, 0),
        );
        await tester.pumpAndSettle();
        expect(scrollable.position.pixels, greaterThan(0));
        scrollable.position.jumpTo(
          scrollable.position.maxScrollExtent,
        );
        await tester.pump();
        expect(scrollable.position.pixels, greaterThan(0));
        scrollable.position.jumpTo(0);
        await tester.pump();
        expect(scrollable.position.pixels, 0);
      }
      expect(tester.takeException(), isNull);
    });
  }

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
    expect(find.text('セッション'), findsOneWidget);
    expect(find.text('Speaker A'), findsOneWidget);
    expect(find.text('Speaker B'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('session-speaker-avatar-speaker-a')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('session-speaker-avatar-speaker-b')),
      findsOneWidget,
    );
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final appBarTitle = appBar.title! as Text;
    expect(appBar.toolbarHeight, 52);
    expect(appBarTitle.style?.fontSize, 16);
    expect(appBarTitle.style?.fontWeight, FontWeight.w700);

    expect(find.byIcon(Icons.tune), findsNothing);
    expect(find.text('時刻表示'), findsNothing);
  });

  testWidgets('uses an icon-only bookmarked action at every width', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_loadedTimetable),
    );

    expect(find.byTooltip('ブックマークしたセッション'), findsOneWidget);
    expect(find.byIcon(Icons.bookmarks_outlined), findsOneWidget);
    expect(find.text('ブックマークしたセッション'), findsNothing);

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pump();

    expect(find.byTooltip('ブックマークしたセッション'), findsOneWidget);
    expect(find.byIcon(Icons.bookmarks_outlined), findsOneWidget);
    expect(find.text('ブックマークしたセッション'), findsNothing);
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
    expect(find.text('10:15'), findsOneWidget);
    expect(find.text('10:15-11:00'), findsOneWidget);
    expect(find.text('Room A'), findsOneWidget);
    expect(find.text('JA'), findsOneWidget);
    expect(find.text('Speaker A'), findsOneWidget);
    expect(find.text('Speaker B'), findsOneWidget);
  });

  testWidgets('shows every speaker and full titles without overlapping consecutive LTs', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_shortLtTimetable),
    );

    final listTitle = tester.widget<Text>(
      find.byKey(const ValueKey('session-title-short-lt-a')),
    );
    expect(listTitle.maxLines, isNull);
    expect(listTitle.overflow, isNull);
    expect(find.text('LT'), findsOneWidget);
    expect(find.text('初心者向けLT'), findsOneWidget);

    await tester.tap(find.byTooltip('会場別タイムラインに切り替え'));
    await tester.pumpAndSettle();

    final firstTitle = tester.widget<Text>(
      find.byKey(const ValueKey('room-session-title-short-lt-a')),
    );
    final secondTitle = tester.widget<Text>(
      find.byKey(const ValueKey('room-session-title-short-lt-b')),
    );
    expect(firstTitle.maxLines, isNull);
    expect(firstTitle.overflow, isNull);
    expect(secondTitle.maxLines, isNull);
    expect(secondTitle.overflow, isNull);
    expect(find.text('Speaker A'), findsOneWidget);
    expect(find.text('Speaker B'), findsOneWidget);

    final firstCard = tester.getRect(
      find.byKey(const ValueKey('room-timeline-entry-short-lt-a')),
    );
    final secondCard = tester.getRect(
      find.byKey(const ValueKey('room-timeline-entry-short-lt-b')),
    );
    expect(firstCard.overlaps(secondCard), isFalse);
    expect(firstCard.bottom, lessThan(secondCard.top));
    expect(tester.takeException(), isNull);
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

  testWidgets('lists overlapping room entries in separate non-overlapping rows', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_overlappingTimetable),
    );

    await tester.tap(find.byTooltip('会場別タイムラインに切り替え'));
    await tester.pumpAndSettle();

    final sessionRect = tester.getRect(
      find.byKey(const ValueKey('room-timeline-entry-compact-session')),
    );
    final eventRect = tester.getRect(
      find.byKey(const ValueKey('room-timeline-entry-overlap-event')),
    );

    expect(sessionRect.overlaps(eventRect), isFalse);
    expect(sessionRect.bottom, lessThan(eventRect.top));
  });

  testWidgets('stacks entries with the same start time and room inside one cell', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_sameRoomAndTimeTimetable),
    );

    await tester.tap(find.byTooltip('会場別タイムラインに切り替え'));
    await tester.pumpAndSettle();

    final firstRect = tester.getRect(
      find.byKey(const ValueKey('room-timeline-entry-compact-session')),
    );
    final secondRect = tester.getRect(
      find.byKey(const ValueKey('room-timeline-entry-same-time-event')),
    );

    expect(firstRect.overlaps(secondRect), isFalse);
    expect(firstRect.bottom, lessThan(secondRect.top));
    expect(tester.takeException(), isNull);
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

  testWidgets('keeps room scrolling inside the table and changes days only from tabs', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_twoDayRoomTimetable),
    );

    await tester.tap(find.byTooltip('会場別タイムラインに切り替え'));
    await tester.pumpAndSettle();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.physics, isA<NeverScrollableScrollPhysics>());

    final roomScroll = find.byKey(
      ValueKey(('room-schedule-scroll', _parallelDay.date)),
    );
    expect(roomScroll, findsOneWidget);
    final horizontalScrollable = find.descendant(
      of: roomScroll,
      matching: find.byType(Scrollable),
    );
    final scrollable = tester.state<ScrollableState>(horizontalScrollable);
    expect(scrollable.position.physics, isA<ClampingScrollPhysics>());
    expect(scrollable.position.pixels, 0);

    await tester.drag(roomScroll, const Offset(-240, 0));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(0));
    expect(
      tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>)).selected,
      {0},
    );
    expect(find.text('Day Two Session'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(
      tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>)).selected,
      {0},
    );
    expect(find.text('Day Two Session'), findsNothing);

    await tester.tap(find.text('2日目 (11/1)'));
    await tester.pumpAndSettle();

    expect(find.text('Day Two Session'), findsOneWidget);
    expect(
      tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>)).selected,
      {1},
    );
    expect(tester.takeException(), isNull);
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

  testWidgets('centers the empty timetable message', (tester) async {
    await _pumpTimetableState(
      tester,
      const AsyncData(_emptyTimetable),
      viewportSize: const Size(390, 844),
    );

    final iconRect = tester.getRect(find.byIcon(Icons.event_busy_outlined));
    final messageRect = tester.getRect(
      find.text('タイムテーブルはまだ公開されていません'),
    );
    final viewportCenter = tester.view.physicalSize.width / 2;

    expect(iconRect.center.dx, closeTo(viewportCenter, 1));
    expect(messageRect.center.dx, closeTo(viewportCenter, 1));
    expect(iconRect.center.dy, greaterThan(250));
    expect(iconRect.center.dy, lessThan(650));
    expect(tester.takeException(), isNull);
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
  Size viewportSize = const Size(320, 900),
}) async {
  final sharedPreferences = await _prepareTester(
    tester,
    preferences,
    viewportSize: viewportSize,
  );

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
  Map<String, Object> preferences, {
  Size viewportSize = const Size(320, 900),
}) async {
  tester.view.physicalSize = viewportSize;
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
  speakers: [_speakerA, _speakerB],
);

final _speakerA = Speaker(
  id: 'speaker-a',
  name: 'Speaker A',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _speakerB = Speaker(
  id: 'speaker-b',
  name: 'Speaker B',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
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

final _sameTimeEvent = TimelineEvent(
  id: 'same-time-event',
  title: const LocaleMap(ja: 'Same Time Event', en: 'Same Time Event'),
  startsAt: _session.startsAt,
  endsAt: _session.endsAt,
  venueId: 'room-a',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _sameTimeEntry = SessionTimetableEntry.timelineEvent(
  timelineEvent: _sameTimeEvent,
  venue: _venue,
);

final _shortLtA = Session(
  id: 'short-lt-a',
  title: const LocaleMap(
    ja: 'とても短いLTでもセッション名を省略せず最後まで表示するための長いタイトル',
    en: 'A long lightning talk title that must remain fully visible',
  ),
  description: const LocaleMap(ja: '', en: ''),
  primaryLocale: 'ja',
  startsAt: DateTime.utc(2026, 10, 31, 8, 30),
  endsAt: DateTime.utc(2026, 10, 31, 8, 35),
  venueId: 'room-a',
  speakerIds: const ['speaker-a', 'speaker-b'],
  isLightningTalk: true,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _shortLtB = Session(
  id: 'short-lt-b',
  title: const LocaleMap(
    ja: '直後に続くLTの名前も前のカードと重ならず全文を表示する長いタイトル',
    en: 'The following lightning talk title must not overlap the previous card',
  ),
  description: const LocaleMap(ja: '', en: ''),
  primaryLocale: 'ja',
  startsAt: DateTime.utc(2026, 10, 31, 8, 35),
  endsAt: DateTime.utc(2026, 10, 31, 8, 40),
  venueId: 'room-a',
  isLightningTalk: true,
  isBeginnersLightningTalk: true,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _shortLtDay = SessionTimetableDay(
  date: DateTime(2026, 10, 31),
  entries: [
    SessionTimetableEntry.session(
      session: _shortLtA,
      venue: _venue,
      speakers: [_speakerA, _speakerB],
    ),
    SessionTimetableEntry.session(
      session: _shortLtB,
      venue: _venue,
      speakers: const [],
    ),
  ],
);

final _shortLtTimetable = SessionTimetableData(
  days: [_shortLtDay],
  availableDates: [_shortLtDay.date],
  selectedDate: _shortLtDay.date,
  selectedDay: _shortLtDay,
  hasAnyEntries: true,
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

final _sameRoomAndTimeDay = SessionTimetableDay(
  date: _day.date,
  entries: [_entry, _sameTimeEntry],
);

final _sameRoomAndTimeTimetable = SessionTimetableData(
  days: [_sameRoomAndTimeDay],
  availableDates: [_sameRoomAndTimeDay.date],
  selectedDate: _sameRoomAndTimeDay.date,
  selectedDay: _sameRoomAndTimeDay,
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

final _twoDayRoomTimetable = SessionTimetableData(
  days: [_parallelDay, _secondDay],
  availableDates: [_parallelDay.date, _secondDay.date],
  selectedDate: _parallelDay.date,
  selectedDay: _parallelDay,
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

const _responsiveRoomViewports = <String, double>{
  '320px phone': 320,
  '390px phone': 390,
  '600px medium layout (519px content)': 519,
  '840px expanded rail layout (583px content)': 583,
  '839px medium rail layout (758px content)': 758,
  '1024px desktop layout (767px content)': 767,
  '1440px desktop layout (1183px content)': 1183,
};

final _stressRoomVenues = List.generate(
  4,
  (index) => Venue(
    id: 'stress-room-$index',
    name: LocaleMap(
      ja: 'Stress Room $index',
      en: 'Stress Room $index',
    ),
    order: index,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
);

final _stressRoomSpeakers = List.generate(
  30,
  (index) => Speaker(
    id: 'stress-speaker-$index',
    name: 'Stress Speaker $index with a name that can wrap',
    avatarUrl: _transparentPngDataUri,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
);

final _stressRoomEntries = List.generate(30, (index) {
  final startsAt = DateTime.utc(2026, 10, 31, 1).add(
    Duration(minutes: index * 10),
  );
  final session = Session(
    id: 'stress-session-$index',
    title: LocaleMap(
      ja: 'Stress Session $index with a long title that remains fully visible',
      en: 'Stress Session $index with a long title that remains fully visible',
    ),
    description: const LocaleMap(ja: '', en: ''),
    primaryLocale: index.isEven ? 'ja' : 'en',
    startsAt: startsAt,
    endsAt: startsAt.add(const Duration(minutes: 10)),
    venueId: _stressRoomVenues[index % _stressRoomVenues.length].id,
    speakerIds: [_stressRoomSpeakers[index].id],
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  return SessionTimetableEntry.session(
    session: session,
    venue: _stressRoomVenues[index % _stressRoomVenues.length],
    speakers: [_stressRoomSpeakers[index]],
  );
});

final _stressRoomDay = SessionTimetableDay(
  date: DateTime(2026, 10, 31),
  entries: _stressRoomEntries,
);

final _stressRoomTimetable = SessionTimetableData(
  days: [_stressRoomDay],
  availableDates: [_stressRoomDay.date],
  selectedDate: _stressRoomDay.date,
  selectedDay: _stressRoomDay,
  hasAnyEntries: true,
);

const _transparentPngDataUri =
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';

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
