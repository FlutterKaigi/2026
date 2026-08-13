import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:caption_protocol/caption_protocol.dart';
import 'package:caption_relay/caption_relay.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  const writeToken = 'test-write-token-0123456789abcdef';
  late CaptionHub hub;
  late Handler handler;

  setUp(() {
    hub = CaptionHub(clock: () => DateTime.utc(2026, 11, 7, 1));
    handler = createCaptionRelayHandler(hub: hub, writeToken: writeToken);
  });

  tearDown(() => hub.close());

  test('rejects a weak write token without echoing it', () {
    const weakToken = 'do-not-log-this';

    expect(
      () => createCaptionRelayHandler(hub: hub, writeToken: weakToken),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.toString(),
          'message',
          isNot(contains(weakToken)),
        ),
      ),
    );
  });

  test('health endpoint does not require producer credentials', () async {
    final response = await handler(Request('GET', Uri.parse('http://localhost/healthz')));

    expect(response.statusCode, HttpStatus.ok);
    final body = jsonDecode(await response.readAsString()) as Map<String, Object?>;
    expect(body, containsPair('status', 'ok'));
    expect(body['finalCaptionLatencyMs'], {'count': 0, 'p50': null, 'p95': null, 'max': null});
  });

  test('rejects caption ingest without bearer token', () async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/captions'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode({
          'roomId': 'main',
          'sessionId': 'opening',
          'utteranceId': 'opening-1',
          'utteranceSequence': 1,
          'revision': 0,
          'translatedText': 'Welcome',
          'sourceStartedAt': '2026-11-07T00:59:58.000Z',
        }),
      ),
    );

    expect(response.statusCode, HttpStatus.unauthorized);
  });

  test('accepts caption ingest and publishes protocol event', () async {
    final eventFuture = hub.subscribe(const CaptionStreamKey(roomId: 'main', sessionId: 'opening')).first;
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/captions'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $writeToken',
        },
        body: jsonEncode({
          'roomId': 'main',
          'sessionId': 'opening',
          'utteranceId': 'opening-1',
          'utteranceSequence': 1,
          'revision': 0,
          'translatedText': 'Welcome',
          'sourceStartedAt': '2026-11-07T00:59:58.000Z',
        }),
      ),
    );

    expect(response.statusCode, HttpStatus.accepted);
    final event = await eventFuture;
    expect(event.translatedText, 'Welcome');
    expect(event.sourceStartedAt, DateTime.utc(2026, 11, 7, 0, 59, 58));
    expect(event.sequence, 1);

    final health = await handler(Request('GET', Uri.parse('http://localhost/healthz')));
    final healthBody = jsonDecode(await health.readAsString()) as Map<String, Object?>;
    expect(healthBody['finalCaptionLatencyMs'], {'count': 1, 'p50': 2000, 'p95': 2000, 'max': 2000});
  });

  test('rejects malformed producer payload without terminating the handler', () async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/captions'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $writeToken',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: '{not json',
      ),
    );

    expect(response.statusCode, HttpStatus.badRequest);
  });

  test('rejects caption stream access from a different browser origin', () async {
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/ws?room=main&session=opening'),
        headers: {'origin': 'https://untrusted.example'},
      ),
    );

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test('rejects a different loopback browser origin by default', () async {
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://127.0.0.1:8088/ws?room=main&session=opening'),
        headers: {'origin': 'http://127.0.0.1:50000'},
      ),
    );

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test('can opt into a different loopback origin for local development', () async {
    final developmentHandler = createCaptionRelayHandler(
      hub: hub,
      writeToken: writeToken,
      allowLoopbackDevelopmentOrigins: true,
    );
    final response = await developmentHandler(
      Request(
        'GET',
        Uri.parse('http://127.0.0.1:8088/ws?room=main&session=opening'),
        headers: {'origin': 'http://127.0.0.1:50000'},
      ),
    );

    expect(response.statusCode, isNot(HttpStatus.forbidden));
  });

  test('rejects browser-originated producer writes even with a valid token', () async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/clear'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $writeToken',
          HttpHeaders.contentTypeHeader: 'application/json',
          'origin': 'https://untrusted.example',
        },
        body: jsonEncode({'roomId': 'main', 'sessionId': 'opening'}),
      ),
    );

    expect(response.statusCode, HttpStatus.forbidden);
  });

  test('requires application/json for producer writes', () async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/clear'),
        headers: {HttpHeaders.authorizationHeader: 'Bearer $writeToken'},
        body: jsonEncode({'roomId': 'main', 'sessionId': 'opening'}),
      ),
    );

    expect(response.statusCode, HttpStatus.unsupportedMediaType);
  });

  test('rejects an unknown producer field instead of applying a default', () async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/captions'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $writeToken',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode({
          'roomId': 'main',
          'sessionId': 'opening',
          'utteranceId': 'opening-1',
          'utteranceSequence': 1,
          'revision': 0,
          'translatedText': 'Welcome',
          'sourceStartedAt': '2026-11-07T00:59:58.000Z',
          'isFianl': true,
        }),
      ),
    );

    expect(response.statusCode, HttpStatus.badRequest);
  });

  test('returns bad request when an older utterance arrives after a newer one', () async {
    FutureOr<Response> post(int sequence, String id) => handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/captions'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $writeToken',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode({
          'roomId': 'main',
          'sessionId': 'opening',
          'utteranceId': id,
          'utteranceSequence': sequence,
          'revision': 0,
          'translatedText': id,
          'sourceStartedAt': '2026-11-07T00:59:58.000Z',
        }),
      ),
    );

    expect((await post(2, 'opening-2')).statusCode, HttpStatus.accepted);
    expect((await post(1, 'opening-1')).statusCode, HttpStatus.badRequest);
  });

  test('stops reading a streamed body above the byte limit', () async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/captions'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $writeToken',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: Stream.fromIterable([
          List<int>.filled(9000, 65),
          List<int>.filled(9000, 65),
        ]),
      ),
    );

    expect(response.statusCode, HttpStatus.badRequest);
  });

  test('access logging omits query parameters', () async {
    final messages = <String>[];
    final loggingHandler = createCaptionRelayHandler(
      hub: hub,
      writeToken: writeToken,
      requestLogger: messages.add,
    );
    final response = await loggingHandler(
      Request('GET', Uri.parse('http://localhost/healthz?token=must-not-appear')),
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(messages.single, isNot(contains('must-not-appear')));
    expect(messages.single, contains('GET /healthz 200'));
  });
}
