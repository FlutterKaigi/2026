import '../logging.dart';
import '../models/caption_segment.dart';
import 'caption_sink.dart';

/// [CaptionSink] that writes structured JSON log lines to stdout. Default sink
/// for the fake/local configuration.
class ConsoleSink implements CaptionSink {
  const ConsoleSink();

  @override
  Future<void> writeInterim(String roomId, InterimCaption interim) async {
    logEvent('caption_interim', {
      'roomId': roomId,
      'seq': interim.seq,
      'srcLang': interim.srcLang,
      'text': interim.text,
    });
  }

  @override
  Future<void> appendSegment(String roomId, CaptionSegment s) async {
    logEvent('caption_segment', {
      'roomId': roomId,
      'seq': s.seq,
      'srcLang': s.srcLang,
      'srcText': s.srcText,
      'ja': s.ja,
      'en': s.en,
      'startMs': s.startMs,
      'endMs': s.endMs,
    });
  }
}
