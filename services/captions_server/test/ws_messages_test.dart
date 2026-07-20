import 'dart:convert';

import 'package:captions_server/captions_server.dart';
import 'package:test/test.dart';

void main() {
  group('HelloMessage.parse', () {
    test('parses a valid hello frame', () {
      final hello = HelloMessage.parse(
        '{"type":"hello","sampleRate":16000,"channels":1,"format":"pcm16le","sourceLang":"ja-JP"}',
      );
      expect(hello.sampleRate, 16000);
      expect(hello.channels, 1);
      expect(hello.format, 'pcm16le');
      expect(hello.sourceLang, 'ja-JP');
      expect(hello.srcLang, 'ja');
    });

    test('rejects non-JSON input', () {
      expect(() => HelloMessage.parse('not json'), throwsA(isA<HelloFormatException>()));
    });

    test('rejects a non-object payload', () {
      expect(() => HelloMessage.parse('[1,2,3]'), throwsA(isA<HelloFormatException>()));
    });

    test('rejects the wrong message type', () {
      expect(
        () => HelloMessage.parse(
          '{"type":"bye","sampleRate":16000,"channels":1,"format":"pcm16le","sourceLang":"ja-JP"}',
        ),
        throwsA(isA<HelloFormatException>()),
      );
    });

    test('rejects an unsupported sample rate', () {
      expect(
        () => HelloMessage.parse(
          '{"type":"hello","sampleRate":44100,"channels":1,"format":"pcm16le","sourceLang":"ja-JP"}',
        ),
        throwsA(isA<HelloFormatException>()),
      );
    });

    test('rejects an unsupported format', () {
      expect(
        () => HelloMessage.parse(
          '{"type":"hello","sampleRate":16000,"channels":1,"format":"opus","sourceLang":"ja-JP"}',
        ),
        throwsA(isA<HelloFormatException>()),
      );
    });

    test('rejects missing required fields', () {
      expect(
        () => HelloMessage.parse('{"type":"hello","sampleRate":16000}'),
        throwsA(isA<HelloFormatException>()),
      );
    });
  });

  group('frame encoders', () {
    test('encodeReady', () {
      expect(jsonDecode(encodeReady()), {'type': 'ready'});
    });

    test('encodeInterim', () {
      expect(
        jsonDecode(encodeInterim(seq: 12, srcLang: 'ja', srcText: 'こんにちは、今日は…')),
        {'type': 'interim', 'seq': 12, 'srcLang': 'ja', 'srcText': 'こんにちは、今日は…'},
      );
    });

    test('encodeCaption serializes every field', () {
      const segment = CaptionSegment(
        seq: 12,
        srcLang: 'ja',
        srcText: 'こんにちは',
        ja: 'こんにちは',
        en: '(en) こんにちは',
        startMs: 123400,
        endMs: 126800,
      );
      expect(jsonDecode(encodeCaption(segment)), {
        'type': 'caption',
        'seq': 12,
        'srcLang': 'ja',
        'srcText': 'こんにちは',
        'ja': 'こんにちは',
        'en': '(en) こんにちは',
        'startMs': 123400,
        'endMs': 126800,
      });
    });

    test('encodeError', () {
      expect(
        jsonDecode(encodeError(code: 'bad_hello', message: 'unsupported format')),
        {'type': 'error', 'code': 'bad_hello', 'message': 'unsupported format'},
      );
    });
  });
}
