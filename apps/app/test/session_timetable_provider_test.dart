import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('combines timeline events, sessions, venues, and speakers by time', () {
    final data = buildSessionTimetableData(
      sessions: _sessions,
      timelineEvents: _timelineEvents,
      venues: _venues,
      speakers: _speakers,
      selectedVenueId: null,
    );

    expect(data.days, hasLength(1));
    expect(data.availableDates, [DateTime(2026, 10, 31)]);
    expect(data.selectedDate, DateTime(2026, 10, 31));
    expect(
      data.days.single.entries.map((entry) => entry.id),
      ['opening', 'room-b-session', 'room-a-session'],
    );
    expect(
      data.days.single.entryGroups.map((group) => group.map((entry) => entry.id).toList()),
      [
        ['opening'],
        ['room-b-session', 'room-a-session'],
      ],
    );
    expect(data.days.single.entries.last.speakers.single.name, 'Speaker A');
  });

  test('filters venue-specific entries while keeping shared timeline events', () {
    final data = buildSessionTimetableData(
      sessions: _sessions,
      timelineEvents: _timelineEvents,
      venues: _venues,
      speakers: _speakers,
      selectedVenueId: 'room-a',
    );

    expect(
      data.days.single.entries.map((entry) => entry.id),
      ['opening', 'room-a-session'],
    );
  });

  test('builds event dates dynamically and selects the first day by default', () {
    final data = buildSessionTimetableData(
      sessions: [..._sessions, _dayTwoSession],
      timelineEvents: _timelineEvents,
      venues: _venues,
      speakers: _speakers,
      selectedVenueId: null,
    );

    expect(
      data.availableDates,
      [DateTime(2026, 10, 31), DateTime(2026, 11)],
    );
    expect(data.selectedDate, DateTime(2026, 10, 31));
    expect(data.days, hasLength(1));
    expect(data.days.single.date, DateTime(2026, 10, 31));
    expect(
      data.selectedDay?.entries.map((entry) => entry.id),
      ['opening', 'room-b-session', 'room-a-session'],
    );
  });

  test('uses a separate session list for the selected event day', () {
    final data = buildSessionTimetableData(
      sessions: [..._sessions, _dayTwoSession],
      timelineEvents: _timelineEvents,
      venues: _venues,
      speakers: _speakers,
      selectedVenueId: null,
      selectedDate: DateTime(2026, 11),
    );

    expect(data.selectedDate, DateTime(2026, 11));
    expect(data.selectedDay?.date, DateTime(2026, 11));
    expect(data.days, hasLength(1));
    expect(data.days.single.date, DateTime(2026, 11));
    expect(
      data.days.single.entries.map((entry) => entry.id),
      ['day-two-session'],
    );
  });

  test('keeps event day buttons when venue filter has no entries on the selected day', () {
    final data = buildSessionTimetableData(
      sessions: [..._sessions, _dayTwoSession],
      timelineEvents: _timelineEvents,
      venues: _venues,
      speakers: _speakers,
      selectedVenueId: 'room-b',
      selectedDate: DateTime(2026, 11),
    );

    expect(
      data.availableDates,
      [DateTime(2026, 10, 31), DateTime(2026, 11)],
    );
    expect(data.selectedVenueId, 'room-b');
    expect(data.selectedDay?.entries, isEmpty);
    expect(data.days, hasLength(1));
    expect(data.days.single.date, DateTime(2026, 11));
    expect(data.days.single.entries, isEmpty);
    expect(data.isEmpty, isTrue);
  });
}

final _venues = [
  Venue(
    id: 'room-a',
    name: const LocaleMap(ja: 'Room A', en: 'Room A'),
    order: 2,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Venue(
    id: 'room-b',
    name: const LocaleMap(ja: 'Room B', en: 'Room B'),
    order: 1,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

final _speakers = [
  Speaker(
    id: 'speaker-a',
    name: 'Speaker A',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

final _sessions = [
  Session(
    id: 'room-a-session',
    title: const LocaleMap(ja: 'Room A Session', en: 'Room A Session'),
    description: const LocaleMap(ja: 'Description', en: 'Description'),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 31, 1),
    endsAt: DateTime.utc(2026, 10, 31, 2),
    venueId: 'room-a',
    speakerIds: const ['speaker-a'],
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Session(
    id: 'room-b-session',
    title: const LocaleMap(ja: 'Room B Session', en: 'Room B Session'),
    description: const LocaleMap(ja: 'Description', en: 'Description'),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 31, 1),
    endsAt: DateTime.utc(2026, 10, 31, 2),
    venueId: 'room-b',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];

final _dayTwoSession = Session(
  id: 'day-two-session',
  title: const LocaleMap(ja: 'Day Two Session', en: 'Day Two Session'),
  description: const LocaleMap(ja: 'Description', en: 'Description'),
  primaryLocale: 'en',
  startsAt: DateTime.utc(2026, 11, 1, 1),
  endsAt: DateTime.utc(2026, 11, 1, 2),
  venueId: 'room-a',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _timelineEvents = [
  TimelineEvent(
    id: 'opening',
    title: const LocaleMap(ja: 'Opening', en: 'Opening'),
    startsAt: DateTime.utc(2026, 10, 31),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];
