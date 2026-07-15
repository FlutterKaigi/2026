import 'package:app/feature/session/data/provider/bookmarked_sessions_provider.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters bookmarked sessions and ignores unknown bookmark IDs', () {
    final data = buildBookmarkedSessionsData(
      sessions: _sessions,
      venues: _venues,
      speakers: _speakers,
      bookmarkedSessionIds: const {'late-session', 'same-time-a', 'same-time-b', 'missing-session'},
    );

    expect(
      data.entries.map((entry) => entry.id),
      ['same-time-b', 'same-time-a', 'late-session'],
    );
    expect(data.staleSessionIds, {'missing-session'});
    expect(data.entries.any((entry) => entry.id == 'not-bookmarked'), isFalse);
  });

  test('resolves available speaker data and safely hides missing speaker IDs', () {
    final data = buildBookmarkedSessionsData(
      sessions: _sessions,
      venues: _venues,
      speakers: _speakers,
      bookmarkedSessionIds: const {'same-time-a'},
    );

    expect(data.entries.single.speakers.map((speaker) => speaker.id), ['speaker-a']);
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
    id: 'late-session',
    title: const LocaleMap(ja: 'Late', en: 'Late'),
    description: const LocaleMap(ja: 'Description', en: 'Description'),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 31, 3),
    endsAt: DateTime.utc(2026, 10, 31, 4),
    venueId: 'room-a',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Session(
    id: 'same-time-a',
    title: const LocaleMap(ja: 'Same A', en: 'Same A'),
    description: const LocaleMap(ja: 'Description', en: 'Description'),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 31, 1),
    endsAt: DateTime.utc(2026, 10, 31, 2),
    venueId: 'room-a',
    speakerIds: const ['speaker-a', 'missing-speaker'],
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Session(
    id: 'same-time-b',
    title: const LocaleMap(ja: 'Same B', en: 'Same B'),
    description: const LocaleMap(ja: 'Description', en: 'Description'),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 31, 1),
    endsAt: DateTime.utc(2026, 10, 31, 2),
    venueId: 'room-b',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  Session(
    id: 'not-bookmarked',
    title: const LocaleMap(ja: 'Not Bookmarked', en: 'Not Bookmarked'),
    description: const LocaleMap(ja: 'Description', en: 'Description'),
    primaryLocale: 'en',
    startsAt: DateTime.utc(2026, 10, 31),
    endsAt: DateTime.utc(2026, 10, 31, 1),
    venueId: 'room-a',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
];
