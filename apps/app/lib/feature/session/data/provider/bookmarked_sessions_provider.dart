import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Stores locally bookmarked Firestore session document IDs.
final bookmarkedSessionIdsProvider = AsyncNotifierProvider<BookmarkedSessionIdsNotifier, Set<String>>(
  BookmarkedSessionIdsNotifier.new,
);

class BookmarkedSessionIdsNotifier extends AsyncNotifier<Set<String>> {
  static const _prefsKey = 'bookmarked_session_ids';

  @override
  Set<String> build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    return _sortedSessionIds(preferences.getStringList(_prefsKey) ?? const []);
  }

  Future<void> add(String sessionId) async {
    final current = await future;
    await _save({...current, sessionId});
  }

  Future<void> remove(String sessionId) async {
    final current = await future;
    await _save({...current}..remove(sessionId));
  }

  Future<void> toggle(String sessionId) async {
    final current = await future;
    if (current.contains(sessionId)) {
      await _save({...current}..remove(sessionId));
    } else {
      await _save({...current, sessionId});
    }
  }

  Future<void> _save(Set<String> sessionIds) async {
    final next = _sortedSessionIds(sessionIds);
    state = AsyncData(next);

    try {
      final saved = await ref.read(sharedPreferencesProvider).setStringList(_prefsKey, next.toList());
      if (!saved) {
        throw const BookmarkPersistenceException();
      }
    } on Exception catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final class BookmarkPersistenceException implements Exception {
  const BookmarkPersistenceException();

  @override
  String toString() => 'Failed to persist bookmarked session IDs.';
}

Set<String> _sortedSessionIds(Iterable<String> sessionIds) {
  final sorted = sessionIds.toSet().toList()..sort();
  return Set.unmodifiable(sorted);
}

/// Combines Firestore-backed session data and the local bookmark ID set.
final bookmarkedSessionsProvider = Provider<AsyncValue<BookmarkedSessionsData>>(
  (ref) {
    final sessions = ref.watch(sessionListProvider);
    final venues = ref.watch(sessionVenueListProvider);
    final speakers = ref.watch(sessionSpeakerListProvider);
    final bookmarkedSessionIds = ref.watch(bookmarkedSessionIdsProvider);

    return switch ((sessions, venues, speakers, bookmarkedSessionIds)) {
      (AsyncError(:final error, :final stackTrace), _, _, _) => AsyncError(error, stackTrace),
      (_, AsyncError(:final error, :final stackTrace), _, _) => AsyncError(error, stackTrace),
      (_, _, AsyncError(:final error, :final stackTrace), _) => AsyncError(error, stackTrace),
      (_, _, _, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
      (
        AsyncData(value: final sessionList),
        AsyncData(value: final venueList),
        AsyncData(value: final speakerList),
        AsyncData(value: final bookmarkIds),
      ) =>
        AsyncData(
          buildBookmarkedSessionsData(
            sessions: sessionList,
            venues: venueList,
            speakers: speakerList,
            bookmarkedSessionIds: bookmarkIds,
          ),
        ),
      _ => const AsyncLoading(),
    };
  },
);

BookmarkedSessionsData buildBookmarkedSessionsData({
  required List<Session> sessions,
  required List<Venue> venues,
  required List<Speaker> speakers,
  required Set<String> bookmarkedSessionIds,
}) {
  final sessionIds = {for (final session in sessions) session.id};
  final venueById = {for (final venue in venues) venue.id: venue};
  final speakerById = {for (final speaker in speakers) speaker.id: speaker};
  final entries = [
    for (final session in sessions)
      if (bookmarkedSessionIds.contains(session.id))
        SessionTimetableEntry.session(
          session: session,
          venue: venueById[session.venueId],
          speakers: [
            for (final speakerId in session.speakerIds)
              if (speakerById[speakerId] != null) speakerById[speakerId]!,
          ],
        ),
  ]..sort((a, b) => compareSessionTimetableEntries(a, b, venueById));

  return BookmarkedSessionsData(
    entries: List.unmodifiable(entries),
    staleSessionIds: Set.unmodifiable(bookmarkedSessionIds.difference(sessionIds)),
  );
}

final class BookmarkedSessionsData {
  const BookmarkedSessionsData({
    required this.entries,
    required this.staleSessionIds,
  });

  final List<SessionTimetableEntry> entries;
  final Set<String> staleSessionIds;

  bool get isEmpty => entries.isEmpty;
}
