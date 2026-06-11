import 'dart:convert';

import 'package:captions_server/captions_server.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _segment = TranscriptEvent(
  text: 'ホットリロードは開発体験を大きく変えます。',
  isFinal: true,
  startMs: 2500,
  endMs: 5000,
  srcLang: 'ja',
);

GeminiTranslator _translator(MockClient client) =>
    GeminiTranslator(apiKey: 'test-key', model: 'test-model', client: client);

/// A 200 generateContent response whose single text part is [inner] as JSON.
/// The charset must be explicit: without it, `http.Response` encodes the body
/// as latin1 and Japanese text breaks.
http.Response _jsonResponse(Object inner) => http.Response(
      jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': inner is String ? inner : jsonEncode(inner)},
              ],
            },
          },
        ],
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('parses ja/en from a generateContent response and sends the key as a header', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return _jsonResponse(
        {'ja': 'ホットリロードは開発体験を大きく変えます。', 'en': 'Hot reload transforms the developer experience.'},
      );
    });

    final result = await _translator(client).translate(_segment, const []);

    expect(result.ja, 'ホットリロードは開発体験を大きく変えます。');
    expect(result.en, 'Hot reload transforms the developer experience.');
    expect(captured.headers['x-goog-api-key'], 'test-key');
    expect(captured.url.queryParameters, isNot(contains('key')), reason: 'the API key must not leak into the URL');
    expect(captured.url.path, contains('test-model'));
  });

  test('throws TranslationException on a non-200 response', () async {
    final client = MockClient((_) async => http.Response('quota exceeded', 429));
    expect(
      () => _translator(client).translate(_segment, const []),
      throwsA(isA<TranslationException>()),
    );
  });

  test('throws TranslationException when the response has no ja/en', () async {
    final client = MockClient((_) async => _jsonResponse({'ja': 'のみ'}));
    expect(
      () => _translator(client).translate(_segment, const []),
      throwsA(isA<TranslationException>()),
    );
  });
}
