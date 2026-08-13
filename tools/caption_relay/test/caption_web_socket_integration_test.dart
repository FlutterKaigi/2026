import 'dart:convert';
import 'dart:io';

import 'package:caption_protocol/caption_protocol.dart';
import 'package:caption_relay/caption_relay.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  test('relays an HTTP caption to an authenticated WebSocket subscriber', () async {
    const writeToken = 'test-write-token-0123456789abcdef';
    final hub = CaptionHub();
    final server = await serve(
      createCaptionRelayHandler(
        hub: hub,
        writeToken: writeToken,
        heartbeatInterval: const Duration(minutes: 1),
      ),
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() async {
      await server.close(force: true);
      await hub.close();
    });
    final baseUri = Uri.parse('http://127.0.0.1:${server.port}');
    final webSocket = IOWebSocketChannel.connect(
      baseUri.replace(
        scheme: 'ws',
        path: '/ws',
        queryParameters: {'room': 'main', 'session': 'opening'},
      ),
    );
    addTearDown(() => webSocket.sink.close());
    await webSocket.ready;

    final eventFuture = webSocket.stream.cast<String>().map(CaptionEvent.fromJsonString).first;
    final response = await http.post(
      baseUri.resolve('/api/v1/captions'),
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
        'translatedText': 'End-to-end caption',
        'sourceStartedAt': DateTime.now().toUtc().subtract(const Duration(seconds: 1)).toIso8601String(),
      }),
    );

    expect(response.statusCode, HttpStatus.accepted);
    final event = await eventFuture.timeout(const Duration(seconds: 2));
    expect(event.type, CaptionEventType.caption);
    expect(event.translatedText, 'End-to-end caption');
  });
}
