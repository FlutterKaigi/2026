import 'dart:typed_data';

/// Streaming transcription: audio bytes → [TranscriptEvent]s.
abstract interface class Transcriber {
  Stream<TranscriptEvent> transcribe(Stream<Uint8List> audio, {required String sourceLang});
}

/// One transcription event. [isFinal] `false` means an interim (in-progress)
/// result that may be revised; `true` means a settled segment.
class TranscriptEvent {
  const TranscriptEvent({
    required this.text,
    required this.isFinal,
    required this.startMs,
    required this.endMs,
    required this.srcLang,
  });

  final String text;
  final bool isFinal;

  /// Start time relative to connection start, in milliseconds.
  final int startMs;

  /// End time relative to connection start, in milliseconds.
  final int endMs;

  /// Source language short code, e.g. `ja`.
  final String srcLang;
}
