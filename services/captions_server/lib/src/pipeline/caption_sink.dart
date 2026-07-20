import '../models/caption_segment.dart';

/// Destination for generated captions. interim is an overwrite (latest wins),
/// segments are append-only. [markLive] / [markOffline] bracket one ingest
/// connection so viewers can tell whether the room is currently streaming.
abstract interface class CaptionSink {
  /// Called once after a valid hello, before any caption is produced.
  Future<void> markLive(String roomId, {required String sourceLang});

  Future<void> writeInterim(String roomId, InterimCaption interim);

  Future<void> appendSegment(String roomId, CaptionSegment segment);

  /// Called once when the ingest connection ends (cleanly or not).
  Future<void> markOffline(String roomId);
}
