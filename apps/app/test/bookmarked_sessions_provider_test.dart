import 'dart:async';

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

  test('serializes overlapping bookmark writes without losing additions', () async {
    final repository = _ControllableBookmarkedSessionIdsRepository();
    final container = ProviderContainer(
      overrides: [
        bookmarkedSessionIdsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(repository.completeAllWrites);

    expect(await container.read(bookmarkedSessionIdsProvider.future), isEmpty);

    final notifier = container.read(bookmarkedSessionIdsProvider.notifier);
    final firstAdd = notifier.add('same-time-a');
    await repository.waitForWriteCount(1);

    final secondAdd = notifier.add('same-time-b');
    await Future<void>.delayed(Duration.zero);

    expect(
      repository.writeAttempts,
      [
        const {'same-time-a'},
      ],
      reason: 'The second write must wait until the first write completes.',
    );

    repository.completeNextWrite();
    await firstAdd;
    await repository.waitForWriteCount(2);

    expect(repository.writeAttempts.last, {'same-time-a', 'same-time-b'});

    repository.completeNextWrite();
    await secondAdd;

    expect(container.read(bookmarkedSessionIdsProvider).requireValue, {
      'same-time-a',
      'same-time-b',
    });
    expect(repository.sessionIds, {'same-time-a', 'same-time-b'});
  });

  test('continues queued bookmark updates after a write failure', () async {
    final repository = _FailOnceBookmarkedSessionIdsRepository();
    final container = ProviderContainer(
      overrides: [
        bookmarkedSessionIdsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(bookmarkedSessionIdsProvider.future), isEmpty);

    final notifier = container.read(bookmarkedSessionIdsProvider.notifier);
    await expectLater(
      notifier.add('same-time-a'),
      throwsA(isA<BookmarkPersistenceException>()),
    );
    await notifier.add('same-time-b');

    expect(repository.writeAttempts, [
      {'same-time-a'},
      {'same-time-b'},
    ]);
    expect(container.read(bookmarkedSessionIdsProvider).requireValue, {
      'same-time-b',
    });
    expect(repository.sessionIds, {'same-time-b'});
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

final class _ControllableBookmarkedSessionIdsRepository implements BookmarkedSessionIdsRepository {
  Set<String> sessionIds = const {};
  final writeAttempts = <Set<String>>[];
  final _pendingWrites = <({Set<String> sessionIds, Completer<void> completer})>[];
  final _writeCountWaiters = <int, Completer<void>>{};

  @override
  Set<String> read() => sessionIds;

  @override
  Future<void> write(Set<String> sessionIds) async {
    final next = Set<String>.unmodifiable(sessionIds);
    final completer = Completer<void>();
    writeAttempts.add(next);
    _pendingWrites.add((sessionIds: next, completer: completer));
    _writeCountWaiters.remove(writeAttempts.length)?.complete();

    await completer.future;
    this.sessionIds = next;
  }

  Future<void> waitForWriteCount(int count) {
    if (writeAttempts.length >= count) {
      return Future.value();
    }
    return _writeCountWaiters.putIfAbsent(count, Completer<void>.new).future;
  }

  void completeNextWrite() {
    final pending = _pendingWrites.removeAt(0);
    pending.completer.complete();
  }

  void completeAllWrites() {
    for (final pending in _pendingWrites) {
      if (!pending.completer.isCompleted) {
        pending.completer.complete();
      }
    }
    _pendingWrites.clear();
  }
}

final class _FailOnceBookmarkedSessionIdsRepository implements BookmarkedSessionIdsRepository {
  Set<String> sessionIds = const {};
  final writeAttempts = <Set<String>>[];
  bool _shouldFail = true;

  @override
  Set<String> read() => sessionIds;

  @override
  Future<void> write(Set<String> sessionIds) async {
    final next = Set<String>.unmodifiable(sessionIds);
    writeAttempts.add(next);

    if (_shouldFail) {
      _shouldFail = false;
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
