/// A finalized caption segment: one transcribed sentence with ja/en translations.
class CaptionSegment {
  const CaptionSegment({
    required this.seq,
    required this.srcLang,
    required this.srcText,
    required this.ja,
    required this.en,
    required this.startMs,
    required this.endMs,
  });

  /// Monotonically increasing sequence number (1-based, per connection).
  final int seq;

  /// Source language short code, e.g. `ja`.
  final String srcLang;

  /// Original transcribed text.
  final String srcText;

  /// Japanese translation.
  final String ja;

  /// English translation.
  final String en;

  /// Start time relative to connection start, in milliseconds.
  final int startMs;

  /// End time relative to connection start, in milliseconds.
  final int endMs;
}

/// The latest in-progress (interim) caption for a room.
class InterimCaption {
  const InterimCaption({
    required this.seq,
    required this.srcLang,
    required this.text,
  });

  /// Sequence number of the segment this interim will eventually become.
  final int seq;
  final String srcLang;
  final String text;
}
