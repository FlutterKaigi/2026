import 'package:app/feature/session/data/provider/bookmarked_sessions_provider.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('keeps the previous bookmark state when writing bookmarks fails', () async {
    final repository = _FakeBookmarkedSessionIdsRepository(
      initialSessionIds: const {'late-session'},
      failWrites: true,
    );
    final container = ProviderContainer(
      overrides: [
        bookmarkedSessionIdsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(bookmarkedSessionIdsProvider.future), {'late-session'});

    await expectLater(
      container.read(bookmarkedSessionIdsProvider.notifier).add('same-time-a'),
      throwsA(isA<BookmarkPersistenceException>()),
    );

    final state = container.read(bookmarkedSessionIdsProvider);
    expect(state, isA<AsyncData<Set<String>>>());
    expect(state.requireValue, {'late-session'});
    expect(repository.sessionIds, {'late-session'});
    expect(repository.writeAttempts.single, {'late-session', 'same-time-a'});
  });

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

final class _FakeBookmarkedSessionIdsRepository implements BookmarkedSessionIdsRepository {
  _FakeBookmarkedSessionIdsRepository({
    required Set<String> initialSessionIds,
    this.failWrites = false,
  }) : sessionIds = Set.unmodifiable(initialSessionIds);

  final bool failWrites;
  Set<String> sessionIds;
  final writeAttempts = <Set<String>>[];

  @override
  Set<String> read() => sessionIds;

  @override
  Future<void> write(Set<String> sessionIds) async {
    final next = Set.unmodifiable(sessionIds);
    writeAttempts.add(next);

    if (failWrites) {
      throw const BookmarkPersistenceException();
    }

    this.sessionIds = next;
  }
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
