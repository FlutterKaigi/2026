import 'dart:async';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'config.dart';
import 'logging.dart';
import 'models/ws_messages.dart';
import 'pipeline/caption_sink.dart';
import 'pipeline/pipeline.dart';
import 'pipeline/transcriber.dart';
import 'pipeline/translator.dart';

/// Builds a [CaptionSink] for one connection, seeded with the connection start
/// epoch ms (used in Firestore segment document ids).
typedef SinkFactory = CaptionSink Function(int connectionStartMs);

/// Handler for `GET /v1/ingest/<roomId>`: validates the bearer token (returns
/// 401 *before* upgrading), then upgrades to WebSocket and runs the pipeline.
///
/// Returns a `Function` because shelf_router invokes it with the request plus
/// the `<roomId>` path parameter.
Function ingestHandler({
  required Config config,
  required Transcriber transcriber,
  required Translator translator,
  required SinkFactory sinkFactory,
}) {
  return (Request request, String roomId) {
    final auth = request.headers['authorization'];
    if (auth != 'Bearer ${config.ingestToken}') {
      logEvent('ingest_unauthorized', {'roomId': roomId}, 'warn');
      return Response(401, body: 'unauthorized\n');
    }
    final ws = webSocketHandler((WebSocketChannel channel) {
      _runConnection(
        channel: channel,
        roomId: roomId,
        transcriber: transcriber,
        translator: translator,
        sinkFactory: sinkFactory,
      );
    });
    return ws(request);
  };
}

void _runConnection({
  required WebSocketChannel channel,
  required String roomId,
  required Transcriber transcriber,
  required Translator translator,
  required SinkFactory sinkFactory,
}) {
  final connectionStartMs = DateTime.now().millisecondsSinceEpoch;
  final audio = StreamController<Uint8List>();
  var started = false;
  var closed = false;

  void closeWith({required String code, required String message, int wsCode = 1008}) {
    if (closed) return;
    closed = true;
    channel.sink.add(encodeError(code: code, message: message));
    channel.sink.close(wsCode);
    if (!audio.isClosed) audio.close();
  }

  channel.stream.listen(
    (message) {
      if (!started) {
        // The first frame must be a textual `hello`. Binary before hello is
        // discarded per §5.1.
        if (message is! String) return;

        final HelloMessage hello;
        try {
          hello = HelloMessage.parse(message);
        } catch (e) {
          logEvent('bad_hello', {'roomId': roomId, 'error': '$e'}, 'warn');
          closeWith(code: 'bad_hello', message: '$e');
          return;
        }

        started = true;
        channel.sink.add(encodeReady());
        logEvent('ingest_ready', {'roomId': roomId, 'sourceLang': hello.sourceLang});

        final pipeline = CaptionPipeline(
          roomId: roomId,
          sourceLang: hello.sourceLang,
          transcriber: transcriber,
          translator: translator,
          sink: sinkFactory(connectionStartMs),
          sendFrame: (frame) {
            if (!closed) channel.sink.add(frame);
          },
        );
        unawaited(pipeline.run(audio.stream).then((_) {
          logEvent('ingest_done', {'roomId': roomId});
          if (!closed) {
            closed = true;
            channel.sink.close(1000);
          }
        }).catchError((Object e) {
          logEvent('pipeline_error', {'roomId': roomId, 'error': '$e'}, 'error');
          closeWith(code: 'internal', message: 'pipeline error', wsCode: 1011);
        }));
        return;
      }

      // After hello: forward binary audio, ignore stray text frames.
      if (message is List<int> && !audio.isClosed) {
        audio.add(Uint8List.fromList(message));
      }
    },
    onError: (Object e, StackTrace st) {
      logEvent('ingest_socket_error', {'roomId': roomId, 'error': '$e'}, 'error');
      if (!audio.isClosed) audio.close();
    },
    onDone: () {
      if (!audio.isClosed) audio.close();
    },
    cancelOnError: false,
  );
}
