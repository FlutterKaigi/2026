import '../models/caption_segment.dart';

/// Destination for generated captions. interim is an overwrite (latest wins),
/// segments are append-only.
abstract interface class CaptionSink {
  Future<void> writeInterim(String roomId, InterimCaption interim);
  Future<void> appendSegment(String roomId, CaptionSegment segment);
}
