import 'dart:math' as math;
import 'dart:typed_data';

/// One utterance worth of PCM16 audio, cut at silence boundaries.
class AudioSegment {
  const AudioSegment({required this.pcm, required this.startMs, required this.endMs});

  /// PCM16LE / 16kHz / mono bytes (includes pre-roll and trailing silence).
  final Uint8List pcm;

  /// Start time relative to stream start, in milliseconds.
  final int startMs;

  /// End time relative to stream start, in milliseconds.
  final int endMs;
}

/// Splits a PCM16LE/16kHz/mono byte stream into utterance segments using a
/// simple RMS-based voice activity detector.
///
/// Time is derived from byte counts (32 bytes/ms), never from wall-clock, so
/// segmentation is deterministic for a given byte stream regardless of pacing.
/// Each delivered chunk is treated as one RMS window (the broadcaster and smoke
/// client send ~100ms chunks).
class AudioSegmenter {
  AudioSegmenter({
    this.silenceRms = 0.012,
    this.minSilence = const Duration(milliseconds: 600),
    this.maxSegment = const Duration(seconds: 8),
    this.minSpeech = const Duration(milliseconds: 400),
    this.preRoll = const Duration(milliseconds: 250),
  });

  /// RMS (0..1) at or below which a chunk counts as silence.
  final double silenceRms;

  /// Trailing silence that closes the current segment.
  final Duration minSilence;

  /// Hard cap on segment length; continuous speech is split at this size.
  final Duration maxSegment;

  /// Segments whose speech portion is shorter than this are dropped as noise.
  final Duration minSpeech;

  /// Audio kept from just before speech onset so word starts are not clipped.
  final Duration preRoll;

  static const _bytesPerMs = 32;

  int _streamMs = 0;
  final List<Uint8List> _preRollChunks = [];
  int _preRollBytes = 0;
  BytesBuilder? _speech;
  int _segmentStartMs = 0;
  int _trailingSilenceMs = 0;
  int _speechMs = 0;

  /// Consumes one chunk and returns any segments it completed (usually 0 or 1).
  List<AudioSegment> addChunk(Uint8List chunk) {
    final chunkMs = chunk.length ~/ _bytesPerMs;
    final chunkEndMs = _streamMs + chunkMs;
    final speaking = _rms(chunk) > silenceRms;
    final out = <AudioSegment>[];

    final speech = _speech;
    if (speech == null) {
      if (speaking) {
        final builder = BytesBuilder(copy: false);
        for (final c in _preRollChunks) {
          builder.add(c);
        }
        _segmentStartMs = _streamMs - _preRollBytes ~/ _bytesPerMs;
        _preRollChunks.clear();
        _preRollBytes = 0;
        builder.add(chunk);
        _speech = builder;
        _trailingSilenceMs = 0;
        _speechMs = chunkMs;
      } else {
        _preRollChunks.add(chunk);
        _preRollBytes += chunk.length;
        while (_preRollChunks.length > 1 &&
            (_preRollBytes - _preRollChunks.first.length) >= preRoll.inMilliseconds * _bytesPerMs) {
          _preRollBytes -= _preRollChunks.removeAt(0).length;
        }
      }
    } else {
      speech.add(chunk);
      _trailingSilenceMs = speaking ? 0 : _trailingSilenceMs + chunkMs;
      if (speaking) _speechMs += chunkMs;
      final segmentMs = chunkEndMs - _segmentStartMs;
      if (_trailingSilenceMs >= minSilence.inMilliseconds || segmentMs >= maxSegment.inMilliseconds) {
        final segment = _finalize(endMs: chunkEndMs);
        if (segment != null) out.add(segment);
      }
    }

    _streamMs = chunkEndMs;
    return out;
  }

  /// Flushes a trailing in-progress segment when the stream ends.
  AudioSegment? flush() => _speech == null ? null : _finalize(endMs: _streamMs);

  AudioSegment? _finalize({required int endMs}) {
    final pcm = _speech!.takeBytes();
    final startMs = _segmentStartMs;
    final speechMs = _speechMs;
    _speech = null;
    _trailingSilenceMs = 0;
    _speechMs = 0;
    // Only actual speaking time counts — pre-roll and trailing silence do not.
    if (speechMs < minSpeech.inMilliseconds) return null;
    return AudioSegment(pcm: pcm, startMs: startMs, endMs: endMs);
  }

  double _rms(Uint8List bytes) {
    final samples = bytes.length ~/ 2;
    if (samples == 0) return 0;
    final view = ByteData.view(bytes.buffer, bytes.offsetInBytes, samples * 2);
    var sumSquares = 0.0;
    for (var i = 0; i < samples; i++) {
      final sample = view.getInt16(i * 2, Endian.little) / 32768.0;
      sumSquares += sample * sample;
    }
    return math.sqrt(sumSquares / samples);
  }
}
