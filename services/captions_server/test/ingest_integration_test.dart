import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:captions_server/captions_server.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  late HttpServer server;
  late int port;
  late _MemorySink sink;

  setUp(() async {
    // Port 0 = ephemeral; fake transcriber + echo translator + memory sink.
    final config = Config.load({'PORT': '0', 'INGEST_TOKEN': 'test-token'});
    sink = _MemorySink();
    server = await serveCaptions(config, sinkFactory: (_) => sink);
    port = server.port;
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('GET /healthz returns 200 ok', () async {
    final res = await http.get(Uri.parse('http://localhost:$port/healthz'));
    expect(res.statusCode, 200);
    expect(res.body, 'ok');
  });

  test(
    'rejects ingest with a wrong bearer token (401, before upgrade)',
    () async {
      final res = await http.get(
        Uri.parse('http://localhost:$port/v1/ingest/room-a'),
        headers: {'Authorization': 'Bearer wrong-token'},
      );
      expect(res.statusCode, 401);
    },
  );

  test('rejects a room id that is not a venue-style slug (400)', () async {
    final res = await http.get(
      Uri.parse('http://localhost:$port/v1/ingest/Hall_A'),
      headers: {'Authorization': 'Bearer test-token'},
    );
    expect(res.statusCode, 400);
  });

  test('hello -> audio -> >=2 caption frames -> clean close', () async {
    final channel = IOWebSocketChannel.connect(
      Uri.parse('ws://localhost:$port/v1/ingest/room-a'),
      headers: {'Authorization': 'Bearer test-token'},
    );
    await channel.ready;

    var gotReady = false;
    var captionCount = 0;
    final twoCaptions = Completer<void>();

    channel.stream.listen((message) {
      final data = jsonDecode(message as String) as Map<String, Object?>;
      switch (data['type']) {
        case 'ready':
          gotReady = true;
        case 'caption':
          captionCount++;
          if (captionCount >= 2 && !twoCaptions.isCompleted) {
            twoCaptions.complete();
          }
      }
    }, cancelOnError: false);

    channel.sink.add(
      jsonEncode({
        'type': 'hello',
        'sampleRate': 16000,
        'channels': 1,
        'format': 'pcm16le',
        'sourceLang': 'ja-JP',
      }),
    );

    // Pump synthetic audio quickly; the fake transcriber is content-agnostic.
    final pump = Timer.periodic(const Duration(milliseconds: 5), (t) {
      if (twoCaptions.isCompleted) {
        t.cancel();
        return;
      }
      channel.sink.add(Uint8List(3200));
    });

    await twoCaptions.future.timeout(const Duration(seconds: 10));
    pump.cancel();

    expect(gotReady, isTrue);
    expect(captionCount, greaterThanOrEqualTo(2));

    await channel.sink.close();

    // The room was marked live on hello and offline after the close.
    await sink.wentOffline.future.timeout(const Duration(seconds: 5));
    expect(sink.lifecycle.first, 'live:ja-JP');
    expect(sink.lifecycle.last, 'offline');
  });
}

/// In-memory [CaptionSink] recording lifecycle transitions for assertions.
class _MemorySink implements CaptionSink {
  final List<String> lifecycle = [];
  final Completer<void> wentOffline = Completer<void>();

  @override
  Future<void> markLive(String roomId, {required String sourceLang}) async {
    lifecycle.add('live:$sourceLang');
  }

  @override
  Future<void> markOffline(String roomId) async {
    lifecycle.add('offline');
    if (!wentOffline.isCompleted) wentOffline.complete();
  }

  @override
  Future<void> writeInterim(String roomId, InterimCaption interim) async {}

  @override
  Future<void> appendSegment(String roomId, CaptionSegment segment) async {}
}
