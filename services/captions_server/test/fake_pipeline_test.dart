import 'dart:typed_data';

import 'package:captions_server/captions_server.dart';
import 'package:test/test.dart';

/// In-memory [CaptionSink] that records everything written to it.
class _MemorySink implements CaptionSink {
  final List<InterimCaption> interims = [];
  final List<CaptionSegment> segments = [];

  @override
  Future<void> writeInterim(String roomId, InterimCaption interim) async => interims.add(interim);

  @override
  Future<void> appendSegment(String roomId, CaptionSegment segment) async => segments.add(segment);
}

void main() {
  test('8s of synthetic PCM yields 3 echo-translated final segments', () async {
    final sink = _MemorySink();
    final sentFrames = <String>[];
    final pipeline = CaptionPipeline(
      roomId: 'room-a',
      sourceLang: 'ja-JP',
      transcriber: FakeTranscriber(),
      translator: const EchoTranslator(),
      sink: sink,
      sendFrame: sentFrames.add,
      interimInterval: const Duration(milliseconds: 50),
    );

    // 8s @ 16kHz mono PCM16 = 256,000 bytes, fed as 80 x 100ms chunks.
    final chunks = List<Uint8List>.generate(80, (_) => Uint8List(3200));
    await pipeline.run(Stream<Uint8List>.fromIterable(chunks));

    // 3 full 2.5s segments fit in 8s (the 4th is incomplete).
    expect(sink.segments.length, 3);
    expect(sink.segments.map((s) => s.seq).toList(), [1, 2, 3]);
    for (final s in sink.segments) {
      expect(s.srcLang, 'ja');
      expect(s.ja, s.srcText, reason: 'echo translator: ja == source text');
      expect(s.en, '(en) ${s.srcText}', reason: 'echo translator: en is prefixed');
      expect(s.endMs, greaterThan(s.startMs));
    }

    // The same 3 captions were emitted to the client as WS frames.
    final captionFrames = sentFrames.where((f) => f.contains('"type":"caption"')).toList();
    expect(captionFrames.length, 3);
  });
}
