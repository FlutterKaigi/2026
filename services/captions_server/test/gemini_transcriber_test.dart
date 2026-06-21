import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:captions_server/captions_server.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// One utterance: 0.3s silence + 1.5s tone + 0.8s silence (100ms chunks).
List<Uint8List> _utterance() => [
      for (var i = 0; i < 3; i++) Uint8List(3200),
      for (var i = 0; i < 15; i++) _tone(),
      for (var i = 0; i < 8; i++) Uint8List(3200),
    ];

Uint8List _tone() {
  final bytes = Uint8List(3200);
  final view = ByteData.view(bytes.buffer);
  const step = 2 * math.pi * 440 / 16000;
  for (var i = 0; i < 1600; i++) {
    view.setInt16(i * 2, (math.sin(step * i) * 0.3 * 32767).round(), Endian.little);
  }
  return bytes;
}

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

GeminiTranscriber _transcriber(MockClient client) =>
    GeminiTranscriber(apiKey: 'test-key', model: 'test-model', client: client);

void main() {
  test('transcribes a VAD segment via Gemini and emits one final event', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return _jsonResponse({'text': 'FlutterKaigi へようこそ。', 'lang': 'ja'});
    });

    final events = await _transcriber(client)
        .transcribe(Stream.fromIterable(_utterance()), sourceLang: 'ja-JP')
        .toList();

    expect(events, hasLength(1));
    final e = events.single;
    expect(e.text, 'FlutterKaigi へようこそ。');
    expect(e.isFinal, isTrue);
    expect(e.srcLang, 'ja');
    expect(e.endMs, greaterThan(e.startMs));

    expect(requests, hasLength(1));
    final request = requests.single;
    expect(request.headers['x-goog-api-key'], 'test-key');
    expect(request.url.path, contains('test-model'));
    final body = jsonDecode(request.body) as Map<String, Object?>;
    final parts = (((body['contents'] as List).first as Map)['parts'] as List).cast<Map<String, Object?>>();
    final inline = parts.last['inlineData'] as Map<String, Object?>;
    expect(inline['mimeType'], 'audio/wav');
    final wav = base64Decode(inline['data'] as String);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF', reason: 'the segment must be wrapped as WAV');
  });

  test('detected language overrides the hello hint', () async {
    final client = MockClient(
      (_) async => _jsonResponse({'text': 'Welcome to FlutterKaigi.', 'lang': 'en'}),
    );
    final events = await _transcriber(client)
        .transcribe(Stream.fromIterable(_utterance()), sourceLang: 'ja-JP')
        .toList();
    expect(events.single.srcLang, 'en');
  });

  test('API errors and empty transcripts are skipped without breaking the stream', () async {
    var call = 0;
    final client = MockClient((_) async {
      call++;
      return switch (call) {
        1 => http.Response('rate limited', 429),
        2 => _jsonResponse({'text': '', 'lang': ''}),
        _ => _jsonResponse({'text': 'ホットリロード。', 'lang': 'ja'}),
      };
    });

    // Three utterances: error, silence, success — only the third yields an event.
    final audio = [..._utterance(), ..._utterance(), ..._utterance()];
    final events = await _transcriber(client)
        .transcribe(Stream.fromIterable(audio), sourceLang: 'ja-JP')
        .toList();

    expect(call, 3);
    expect(events, hasLength(1));
    expect(events.single.text, 'ホットリロード。');
  });
}
