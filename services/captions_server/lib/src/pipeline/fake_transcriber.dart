import 'dart:typed_data';

import 'transcriber.dart';

/// Deterministic [Transcriber] for local development and tests.
///
/// Counts received audio bytes and, for every ~2.5s of 16kHz/mono/PCM16 audio
/// (80,000 bytes), emits two interim events (a growing prefix of the sentence)
/// followed by a final event carrying a fixed Japanese sentence drawn from a
/// rotating list. Output depends only on the *total* byte count, so it is
/// independent of how the audio is chunked.
class FakeTranscriber implements Transcriber {
  FakeTranscriber({List<String>? sentences}) : sentences = sentences ?? _defaultSentences;

  final List<String> sentences;

  /// Bytes per finalized segment (~2.5s @ 16kHz mono PCM16).
  static const bytesPerSegment = 80000;

  /// Bytes per millisecond (16,000 samples/s * 2 bytes / 1000).
  static const _bytesPerMs = 32;

  /// Fractions of a segment at which interim events are emitted.
  static const _interimAt = <double>[0.4, 0.8];

  static const _defaultSentences = <String>[
    'FlutterKaigi へようこそ。',
    'ホットリロードは開発体験を大きく変えます。',
    'ウィジェットツリーを意識すると UI 構築がはかどります。',
    '宣言的 UI はテストとの相性も良いです。',
    'マルチプラットフォーム対応が Flutter の強みです。',
    'それでは本日もよろしくお願いします。',
  ];

  @override
  Stream<TranscriptEvent> transcribe(Stream<Uint8List> audio, {required String sourceLang}) async* {
    final srcLang = sourceLang.split('-').first;
    var totalBytes = 0;
    var segmentIndex = 0;
    var emittedInterims = 0;

    await for (final chunk in audio) {
      totalBytes += chunk.length;

      // Drain every interim/final the accumulated bytes now allow. A single
      // large chunk can complete several segments at once.
      while (true) {
        final segmentStartBytes = segmentIndex * bytesPerSegment;
        final bytesIntoSegment = totalBytes - segmentStartBytes;
        final sentence = sentences[segmentIndex % sentences.length];

        if (emittedInterims < _interimAt.length &&
            bytesIntoSegment >= _interimAt[emittedInterims] * bytesPerSegment) {
          final fraction = _interimAt[emittedInterims];
          emittedInterims++;
          final interimEndBytes = segmentStartBytes + (fraction * bytesPerSegment).round();
          yield TranscriptEvent(
            text: _prefixByFraction(sentence, fraction),
            isFinal: false,
            startMs: segmentStartBytes ~/ _bytesPerMs,
            endMs: interimEndBytes ~/ _bytesPerMs,
            srcLang: srcLang,
          );
          continue;
        }

        if (bytesIntoSegment >= bytesPerSegment) {
          yield TranscriptEvent(
            text: sentence,
            isFinal: true,
            startMs: segmentStartBytes ~/ _bytesPerMs,
            endMs: (segmentStartBytes + bytesPerSegment) ~/ _bytesPerMs,
            srcLang: srcLang,
          );
          segmentIndex++;
          emittedInterims = 0;
          continue;
        }

        break;
      }
    }
  }

  /// Returns the first [fraction] of [sentence] (by character) plus an ellipsis.
  String _prefixByFraction(String sentence, double fraction) {
    final runes = sentence.runes.toList();
    final count = (runes.length * fraction).ceil().clamp(1, runes.length);
    return '${String.fromCharCodes(runes.take(count))}…';
  }
}
