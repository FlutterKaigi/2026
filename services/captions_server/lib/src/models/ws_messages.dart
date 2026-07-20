import 'dart:convert';

import 'caption_segment.dart';

/// Parsed `hello` frame (client → server, first text frame). See §5.1.
class HelloMessage {
  const HelloMessage({
    required this.sampleRate,
    required this.channels,
    required this.format,
    required this.sourceLang,
  });

  final int sampleRate;
  final int channels;
  final String format;
  final String sourceLang;

  static const expectedSampleRate = 16000;
  static const expectedChannels = 1;
  static const expectedFormat = 'pcm16le';

  /// Short source-language code derived from [sourceLang] (e.g. `ja` ← `ja-JP`).
  String get srcLang => sourceLang.split('-').first;

  /// Parses and validates a hello frame, throwing [HelloFormatException] on any
  /// problem (bad JSON, wrong type/fields, or unsupported audio format).
  factory HelloMessage.parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw HelloFormatException('hello is not valid JSON: ${e.message}');
    }
    if (decoded is! Map<String, Object?>) {
      throw const HelloFormatException('hello must be a JSON object');
    }
    if (decoded['type'] != 'hello') {
      throw const HelloFormatException('first frame must have type "hello"');
    }
    final sampleRate = decoded['sampleRate'];
    final channels = decoded['channels'];
    final format = decoded['format'];
    final sourceLang = decoded['sourceLang'];
    if (sampleRate is! int || channels is! int || format is! String || sourceLang is! String) {
      throw const HelloFormatException('hello is missing required fields');
    }
    if (sampleRate != expectedSampleRate) {
      throw HelloFormatException('unsupported sampleRate $sampleRate (expected $expectedSampleRate)');
    }
    if (channels != expectedChannels) {
      throw HelloFormatException('unsupported channels $channels (expected $expectedChannels)');
    }
    if (format != expectedFormat) {
      throw HelloFormatException('unsupported format "$format" (expected $expectedFormat)');
    }
    return HelloMessage(sampleRate: sampleRate, channels: channels, format: format, sourceLang: sourceLang);
  }
}

/// Thrown when a `hello` frame is malformed or specifies an unsupported format.
class HelloFormatException implements Exception {
  const HelloFormatException(this.message);
  final String message;
  @override
  String toString() => 'HelloFormatException: $message';
}

/// Encodes the `ready` acknowledgement frame.
String encodeReady() => jsonEncode({'type': 'ready'});

/// Encodes an `interim` (in-progress) frame.
String encodeInterim({required int seq, required String srcLang, required String srcText}) =>
    jsonEncode({'type': 'interim', 'seq': seq, 'srcLang': srcLang, 'srcText': srcText});

/// Encodes a finalized `caption` frame.
String encodeCaption(CaptionSegment s) => jsonEncode({
      'type': 'caption',
      'seq': s.seq,
      'srcLang': s.srcLang,
      'srcText': s.srcText,
      'ja': s.ja,
      'en': s.en,
      'startMs': s.startMs,
      'endMs': s.endMs,
    });

/// Encodes an `error` frame (`code` is `bad_hello` | `internal`).
String encodeError({required String code, required String message}) =>
    jsonEncode({'type': 'error', 'code': code, 'message': message});
