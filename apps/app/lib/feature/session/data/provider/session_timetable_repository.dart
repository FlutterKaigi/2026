import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides timeline events that are displayed alongside sessions.
final sessionTimetableTimelineEventRepositoryProvider = Provider<TimelineEventRepository>(
  (ref) => FirestoreTimelineEventRepository(),
);

/// Provides venues used to resolve each session's `venueId`.
final sessionTimetableVenueRepositoryProvider = Provider<VenueRepository>(
  (ref) => FirestoreVenueRepository(),
);

/// Provides speakers used to resolve each session's `speakerIds`.
final sessionTimetableSpeakerRepositoryProvider = Provider<SpeakerRepository>(
  (ref) => FirestoreSpeakerRepository(),
);
