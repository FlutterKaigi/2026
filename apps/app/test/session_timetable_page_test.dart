import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/session/data/provider/session_repository.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/data/provider/session_timetable_repository.dart';
import 'package:app/feature/session/ui/page/session_timetable_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('keeps Japanese AM/PM time labels on one line at compact width', (tester) async {
    await _pumpTimetableState(
      tester,
      AsyncData(_loadedTimetable),
      preferences: const {'session_time_format': 'amPm'},
    );

    const label = '午前10:15';
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: label.length),
    );

    expect(boxes.map((box) => box.top).toSet(), hasLength(1));
    expect(find.byType(RefreshIndicator), findsNothing);
  });

  testWidgets('does not add pull-to-refresh to the empty timetable', (tester) async {
    await _pumpTimetableState(
      tester,
      const AsyncData(_emptyTimetable),
    );

    expect(find.byType(RefreshIndicator), findsNothing);
    expect(find.text('タイムテーブルはまだ公開されていません'), findsOneWidget);
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
    expect(find.text('タイムテーブルを取得できませんでした'), findsOneWidget);
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
  venues: [],
  selectedVenueId: null,
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
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _entry = SessionTimetableEntry.session(
  session: _session,
  venue: _venue,
  speakers: const [],
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
  venues: [_venue],
  selectedVenueId: null,
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
