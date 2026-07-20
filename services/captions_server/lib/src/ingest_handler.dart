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
import 'pipeline/session_context.dart';
import 'pipeline/transcriber.dart';
import 'pipeline/translator.dart';

/// Builds a [CaptionSink] for one connection, seeded with the connection start
/// epoch ms (used in Firestore segment document ids).
typedef SinkFactory = CaptionSink Function(int connectionStartMs);

/// Room ids equal venue ids (`venues/{venueId}` in Firestore): lowercase
/// slugs such as `hall-a`. Rejecting anything else keeps typos from creating
/// orphan caption rooms the app can never reach.
final _roomIdPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');

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
  SessionContextLoader? contextLoader,
}) {
  return (Request request, String roomId) {
    final auth = request.headers['authorization'];
    if (auth != 'Bearer ${config.ingestToken}') {
      logEvent('ingest_unauthorized', {'roomId': roomId}, 'warn');
      return Response(401, body: 'unauthorized\n');
    }
    if (!_roomIdPattern.hasMatch(roomId)) {
      logEvent('ingest_bad_room', {'roomId': roomId}, 'warn');
      return Response(400, body: 'invalid room id\n');
    }
    final ws = webSocketHandler((WebSocketChannel channel) {
      _runConnection(
        channel: channel,
        roomId: roomId,
        transcriber: transcriber,
        translator: translator,
        sinkFactory: sinkFactory,
        contextLoader: contextLoader,
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
  SessionContextLoader? contextLoader,
}) {
  final connectionStartMs = DateTime.now().millisecondsSinceEpoch;
  final audio = StreamController<Uint8List>();
  var started = false;
  var closed = false;

  void closeWith({
    required String code,
    required String message,
    int wsCode = 1008,
  }) {
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
        logEvent('ingest_ready', {
          'roomId': roomId,
          'sourceLang': hello.sourceLang,
        });

        // Audio frames arriving while markLive runs are buffered by the
        // single-subscription controller until the pipeline subscribes.
        unawaited(
          _runPipeline(
            channel: channel,
            roomId: roomId,
            hello: hello,
            transcriber: transcriber,
            translator: translator,
            sink: sinkFactory(connectionStartMs),
            contextLoader: contextLoader,
            audio: audio,
            isClosed: () => closed,
            markClosed: () => closed = true,
            closeWith: closeWith,
          ),
        );
        return;
      }

      // After hello: forward binary audio, ignore stray text frames.
      if (message is List<int> && !audio.isClosed) {
        audio.add(Uint8List.fromList(message));
      }
    },
    onError: (Object e, StackTrace st) {
      logEvent('ingest_socket_error', {
        'roomId': roomId,
        'error': '$e',
      }, 'error');
      if (!audio.isClosed) audio.close();
    },
    onDone: () {
      if (!audio.isClosed) audio.close();
    },
    cancelOnError: false,
  );
}

Future<void> _runPipeline({
  required WebSocketChannel channel,
  required String roomId,
  required HelloMessage hello,
  required Transcriber transcriber,
  required Translator translator,
  required CaptionSink sink,
  required StreamController<Uint8List> audio,
  required bool Function() isClosed,
  required void Function() markClosed,
  required void Function({required String code, required String message, int wsCode}) closeWith,
  SessionContextLoader? contextLoader,
}) async {
  // Mark the room live before consuming audio so viewers see the state flip
  // as soon as the broadcaster connects. A sink failure must not kill the
  // WebSocket path: captions still flow to the broadcaster for monitoring.
  try {
    await sink.markLive(roomId, sourceLang: hello.sourceLang);
  } catch (e) {
    logEvent('sink_mark_live_error', {'roomId': roomId, 'error': '$e'}, 'error');
  }

  // Proper-noun context for Gemini prompts (session/speakers/sponsors).
  // Loaded once per connection; audio buffers while this resolves.
  final domainContext = await loadSessionContext(contextLoader, roomId);

  final pipeline = CaptionPipeline(
    roomId: roomId,
    sourceLang: hello.sourceLang,
    transcriber: transcriber,
    translator: translator,
    sink: sink,
    domainContext: domainContext,
    sendFrame: (frame) {
      if (!isClosed()) channel.sink.add(frame);
    },
  );

  try {
    await pipeline.run(audio.stream);
    logEvent('ingest_done', {'roomId': roomId});
    if (!isClosed()) {
      markClosed();
      await channel.sink.close(1000);
    }
  } catch (e) {
    logEvent('pipeline_error', {'roomId': roomId, 'error': '$e'}, 'error');
    closeWith(code: 'internal', message: 'pipeline error', wsCode: 1011);
  } finally {
    try {
      await sink.markOffline(roomId);
    } catch (e) {
      logEvent('sink_mark_offline_error', {'roomId': roomId, 'error': '$e'}, 'error');
    }
  }
}
