import 'dart:typed_data';

import '../logging.dart';
import '../models/caption_segment.dart';
import '../models/ws_messages.dart';
import 'caption_sink.dart';
import 'interim_throttle.dart';
import 'transcriber.dart';
import 'translator.dart';

/// Per-connection orchestration: audio → transcribe → (interim throttle |
/// translate) → [CaptionSink] + outgoing WebSocket frames. See §5.2.
class CaptionPipeline {
  CaptionPipeline({
    required this.roomId,
    required this.sourceLang,
    required this.transcriber,
    required this.translator,
    required this.sink,
    required this.sendFrame,
    this.domainContext,
    this.interimInterval = const Duration(seconds: 1),
    this.recentContextSize = 5,
  });

  final String roomId;
  final String sourceLang;
  final Transcriber transcriber;
  final Translator translator;
  final CaptionSink sink;

  /// Conference proper-noun context injected into Gemini prompts (nullable).
  final String? domainContext;

  /// Sends a text frame to the connected client.
  final void Function(String frame) sendFrame;

  /// Minimum spacing between interim emissions (1Hz default).
  final Duration interimInterval;

  /// How many recent finalized segments are passed to the translator as context.
  final int recentContextSize;

  final List<CaptionSegment> _recent = [];

  /// Runs the pipeline until [audio] closes and all in-flight translations settle.
  Future<void> run(Stream<Uint8List> audio) async {
    final throttle = InterimThrottle<InterimCaption>(_emitInterim, interval: interimInterval);
    final pending = <Future<void>>[];
    var seq = 0;

    try {
      await for (final event in transcriber.transcribe(audio, sourceLang: sourceLang, domainContext: domainContext)) {
        if (!event.isFinal) {
          // interim → throttle to ≤1Hz, latest value wins. The seq is the
          // upcoming segment's number.
          throttle.update(InterimCaption(seq: seq + 1, srcLang: event.srcLang, text: event.text));
          continue;
        }
        seq++;
        pending.add(_handleFinal(seq, event, List<CaptionSegment>.of(_recent)));
      }
      await Future.wait(pending);
    } finally {
      throttle.dispose();
    }
  }

  void _emitInterim(InterimCaption interim) {
    sendFrame(encodeInterim(seq: interim.seq, srcLang: interim.srcLang, srcText: interim.text));
    // Fire-and-forget: a sink failure must not break the interim stream.
    () async {
      try {
        await sink.writeInterim(roomId, interim);
      } catch (e) {
        logEvent('sink_interim_error', {'roomId': roomId, 'error': '$e'}, 'error');
      }
    }();
  }

  Future<void> _handleFinal(int seq, TranscriptEvent event, List<CaptionSegment> context) async {
    final TranslationResult translation;
    try {
      translation = await translator.translate(event, context, domainContext: domainContext);
    } catch (e) {
      // Skip this segment but keep the pipeline alive (§5.2 step 4).
      logEvent('translate_error', {'roomId': roomId, 'seq': seq, 'error': '$e'}, 'error');
      return;
    }

    final segment = CaptionSegment(
      seq: seq,
      srcLang: event.srcLang,
      srcText: event.text,
      ja: translation.ja,
      en: translation.en,
      startMs: event.startMs,
      endMs: event.endMs,
    );
    _recent.add(segment);
    if (_recent.length > recentContextSize) {
      _recent.removeRange(0, _recent.length - recentContextSize);
    }

    sendFrame(encodeCaption(segment));
    try {
      await sink.appendSegment(roomId, segment);
    } catch (e) {
      logEvent('sink_segment_error', {'roomId': roomId, 'seq': seq, 'error': '$e'}, 'error');
    }
  }
}
