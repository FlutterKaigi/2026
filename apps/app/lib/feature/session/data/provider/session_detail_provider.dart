import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Selects and resolves one session from the Firestore-backed timetable data.
final sessionDetailProvider = Provider.family<AsyncValue<SessionDetailData?>, String>(
  (ref, sessionId) {
    final sessions = ref.watch(sessionListProvider);

    return switch (sessions) {
      AsyncError(:final error, :final stackTrace) => AsyncError(error, stackTrace),
      AsyncLoading() => const AsyncLoading(),
      AsyncData(:final value) => _buildSessionDetailValue(
        ref: ref,
        sessionId: sessionId,
        sessions: value,
      ),
    };
  },
);

AsyncValue<SessionDetailData?> _buildSessionDetailValue({
  required Ref ref,
  required String sessionId,
  required List<Session> sessions,
}) {
  final session = selectSessionById(sessions, sessionId);
  if (session == null) {
    return const AsyncData(null);
  }

  final venues = ref.watch(sessionVenueListProvider);
  final speakers = ref.watch(sessionSpeakerListProvider);

  return switch ((venues, speakers)) {
    (AsyncError(:final error, :final stackTrace), _) => AsyncError(error, stackTrace),
    (_, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
    (AsyncData(value: final venueList), AsyncData(value: final speakerList)) => AsyncData(
      buildSessionDetailData(
        session: session,
        venues: venueList,
        speakers: speakerList,
      ),
    ),
    _ => const AsyncLoading(),
  };
}

/// Returns the matching session, or `null` when the ID is unknown.
Session? selectSessionById(List<Session> sessions, String sessionId) {
  for (final session in sessions) {
    if (session.id == sessionId) {
      return session;
    }
  }
  return null;
}

/// Resolves related venue and speaker documents for a session.
SessionDetailData buildSessionDetailData({
  required Session session,
  required List<Venue> venues,
  required List<Speaker> speakers,
}) {
  final venueById = {for (final venue in venues) venue.id: venue};
  final speakerById = {for (final speaker in speakers) speaker.id: speaker};

  return SessionDetailData(
    session: session,
    venue: venueById[session.venueId],
    speakers: [
      for (final speakerId in session.speakerIds)
        if (speakerById[speakerId] != null) speakerById[speakerId]!,
    ],
  );
}

/// Session details data after resolving Firestore document references by ID.
final class SessionDetailData {
  const SessionDetailData({
    required this.session,
    required this.venue,
    required this.speakers,
  });

  final Session session;
  final Venue? venue;
  final List<Speaker> speakers;
}
