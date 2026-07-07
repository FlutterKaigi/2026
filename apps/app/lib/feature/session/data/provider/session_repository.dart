import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides the [SessionRepository] implementation backed by Firestore.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => FirestoreSessionRepository(),
);

/// Provides the [SpeakerRepository] implementation backed by Firestore.
final sessionSpeakerRepositoryProvider = Provider<SpeakerRepository>(
  (ref) => FirestoreSpeakerRepository(),
);

/// Provides the [TimelineEventRepository] implementation backed by Firestore.
final sessionTimelineEventRepositoryProvider = Provider<TimelineEventRepository>(
  (ref) => FirestoreTimelineEventRepository(),
);

/// Provides the [VenueRepository] implementation backed by Firestore.
final sessionVenueRepositoryProvider = Provider<VenueRepository>(
  (ref) => FirestoreVenueRepository(),
);
