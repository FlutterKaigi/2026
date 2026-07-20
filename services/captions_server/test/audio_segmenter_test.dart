import 'dart:math' as math;
import 'dart:typed_data';

import 'package:captions_server/captions_server.dart';
import 'package:test/test.dart';

/// 100ms of silence (PCM16 / 16kHz / mono).
Uint8List _silence() => Uint8List(3200);

/// 100ms of a 440Hz tone at amplitude 0.3.
Uint8List _tone() {
  final bytes = Uint8List(3200);
  final view = ByteData.view(bytes.buffer);
  const step = 2 * math.pi * 440 / 16000;
  for (var i = 0; i < 1600; i++) {
    view.setInt16(i * 2, (math.sin(step * i) * 0.3 * 32767).round(), Endian.little);
  }
  return bytes;
}

/// Feeds [pattern] ('s' = 100ms silence, 'T' = 100ms tone) and collects segments.
List<AudioSegment> _run(AudioSegmenter segmenter, String pattern, {bool flush = true}) {
  final out = <AudioSegment>[];
  for (final c in pattern.split('')) {
    out.addAll(segmenter.addChunk(c == 'T' ? _tone() : _silence()));
  }
  if (flush) {
    final last = segmenter.flush();
    if (last != null) out.add(last);
  }
  return out;
}

void main() {
  test('silence only yields no segments', () {
    expect(_run(AudioSegmenter(), 'ssssssssss'), isEmpty);
  });

  test('one utterance is cut at trailing silence, with pre-roll', () {
    // 0.5s silence, 2s tone, 1s silence.
    final segments = _run(AudioSegmenter(), 'sssss' 'TTTTTTTTTTTTTTTTTTTT' 'ssssssssss', flush: false);

    expect(segments, hasLength(1));
    final s = segments.single;
    expect(s.startMs, 200, reason: 'speech onset at 500ms minus the buffered pre-roll (3 x 100ms chunks)');
    expect(s.endMs, 3100, reason: 'finalized once trailing silence reaches 600ms');
    expect(s.pcm.length, (s.endMs - s.startMs) * 32, reason: 'pcm length must match the ms range');
  });

  test('continuous speech is split at maxSegment and the tail is flushed', () {
    // 10s of tone: first segment closes at the 8s cap, the remaining 2s on flush.
    final segments = _run(AudioSegmenter(), 'T' * 100);

    expect(segments, hasLength(2));
    expect(segments[0].startMs, 0);
    expect(segments[0].endMs, 8000);
    expect(segments[1].startMs, 8000);
    expect(segments[1].endMs, 10000);
  });

  test('a blip shorter than minSpeech is dropped as noise', () {
    // 0.2s tone surrounded by silence.
    expect(_run(AudioSegmenter(), 'sss' 'TT' 'ssssssss'), isEmpty);
  });

  test('two utterances become two segments', () {
    final segments = _run(
      AudioSegmenter(),
      'ss' 'TTTTTTTT' 'ssssssss' 'TTTTTTTTTT' 'ssssssss',
      flush: false,
    );
    expect(segments, hasLength(2));
    expect(segments[0].endMs, lessThanOrEqualTo(segments[1].startMs), reason: 'segments must not overlap');
  });
}
