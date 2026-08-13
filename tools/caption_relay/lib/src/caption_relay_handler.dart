import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:caption_protocol/caption_protocol.dart';
import 'package:caption_relay/src/caption_hub.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Handler createCaptionRelayHandler({
  required CaptionHub hub,
  required String writeToken,
  String? webRoot,
  Duration heartbeatInterval = const Duration(seconds: 3),
  void Function(String message)? requestLogger,
  bool allowLoopbackDevelopmentOrigins = false,
}) {
  if (writeToken.length < 32 || writeToken.length > 256 || writeToken.trim() != writeToken) {
    throw ArgumentError('writeToken must contain 32 to 256 non-whitespace-bounded characters.');
  }
  final router = Router();

  router.get('/healthz', (Request request) {
    return _jsonResponse({
      'status': 'ok',
      'subscribers': hub.subscriberCount,
      'activeStreams': hub.activeStreamCount,
      'finalCaptionLatencyMs': hub.finalCaptionLatency.toJson(),
      'time': DateTime.now().toUtc().toIso8601String(),
    });
  });

  router.post('/api/v1/captions', (Request request) async {
    final rejected = _validateProducerRequest(request, writeToken);
    if (rejected != null) {
      return rejected;
    }
    try {
      final body = await _readJsonObject(request);
      final event = hub.publishCaption(CaptionIngestRequest.fromJson(body));
      return _jsonResponse(event.toJson(), statusCode: HttpStatus.accepted);
    } on FormatException catch (error) {
      return _jsonError(HttpStatus.badRequest, error.message);
    }
  });

  router.post('/api/v1/clear', (Request request) async {
    final rejected = _validateProducerRequest(request, writeToken);
    if (rejected != null) {
      return rejected;
    }
    try {
      final body = await _readJsonObject(request);
      final event = hub.publishClear(CaptionClearRequest.fromJson(body));
      return _jsonResponse(event.toJson(), statusCode: HttpStatus.accepted);
    } on FormatException catch (error) {
      return _jsonError(HttpStatus.badRequest, error.message);
    }
  });

  router.get('/ws', (Request request) {
    final rejectedOrigin = _validateWebSocketOrigin(
      request,
      allowLoopbackDevelopmentOrigins: allowLoopbackDevelopmentOrigins,
    );
    if (rejectedOrigin != null) {
      return rejectedOrigin;
    }
    final roomId = request.url.queryParameters['room'] ?? '';
    final sessionId = request.url.queryParameters['session'] ?? '';
    if (!_isSafeIdentifier(roomId) || !_isSafeIdentifier(sessionId)) {
      return _jsonError(HttpStatus.badRequest, 'room and session query parameters are required.');
    }
    final key = CaptionStreamKey(roomId: roomId, sessionId: sessionId);
    final handler = webSocketHandler(
      (WebSocketChannel channel, String? protocol) {
        var isClosed = false;
        StreamSubscription<CaptionEvent>? subscription;
        StreamSubscription<Object?>? inboundSubscription;
        Timer? heartbeatTimer;

        Future<void> closeConnection() async {
          if (isClosed) {
            return;
          }
          isClosed = true;
          heartbeatTimer?.cancel();
          await subscription?.cancel();
          await inboundSubscription?.cancel();
          await channel.sink.close();
        }

        void send(CaptionEvent event) {
          if (isClosed) {
            return;
          }
          try {
            channel.sink.add(event.toJsonString());
          } on Object {
            unawaited(closeConnection());
          }
        }

        heartbeatTimer = Timer.periodic(
          heartbeatInterval,
          (_) => send(hub.heartbeat(key)),
        );
        subscription = hub
            .subscribe(key)
            .listen(
              send,
              onError: (_) => closeConnection(),
              onDone: closeConnection,
            );
        if (isClosed) {
          heartbeatTimer.cancel();
          heartbeatTimer = null;
          return;
        }
        inboundSubscription = channel.stream.listen(
          (_) {},
          onError: (_) => closeConnection(),
          onDone: closeConnection,
          cancelOnError: true,
        );
      },
      pingInterval: const Duration(seconds: 10),
    );
    return handler(request);
  });

  Handler appHandler = router.call;
  if (webRoot != null) {
    final directory = Directory(webRoot);
    if (!directory.existsSync()) {
      throw ArgumentError.value(webRoot, 'webRoot', 'Directory does not exist. Build apps/venue_screen first.');
    }
    appHandler = Cascade()
        .add(router.call)
        .add(createStaticHandler(directory.path, defaultDocument: 'index.html'))
        .handler;
  }

  final handler = const Pipeline().addMiddleware(_securityHeaders).addHandler(appHandler);
  return requestLogger == null ? handler : _safeAccessLog(handler, requestLogger);
}

Response? _validateProducerRequest(Request request, String writeToken) {
  final origin = request.headers['origin'];
  if (origin != null) {
    return _jsonError(HttpStatus.forbidden, 'Browser-originated caption writes are not allowed.');
  }

  final authorization = request.headers[HttpHeaders.authorizationHeader];
  final candidate = authorization?.startsWith('Bearer ') == true ? authorization!.substring(7) : '';
  if (!_secureEquals(candidate, writeToken)) {
    return _jsonError(HttpStatus.unauthorized, 'A valid bearer token is required.');
  }

  final contentTypeValue = request.headers[HttpHeaders.contentTypeHeader];
  try {
    if (contentTypeValue == null || ContentType.parse(contentTypeValue).mimeType != ContentType.json.mimeType) {
      return _jsonError(HttpStatus.unsupportedMediaType, 'Content-Type must be application/json.');
    }
  } on FormatException {
    return _jsonError(HttpStatus.unsupportedMediaType, 'Content-Type must be application/json.');
  }

  return null;
}

Future<Map<String, Object?>> _readJsonObject(Request request) async {
  final contentLength = request.contentLength;
  if (contentLength != null && contentLength > 16 * 1024) {
    throw const FormatException('Request body is too large.');
  }
  final bytes = BytesBuilder(copy: false);
  var byteCount = 0;
  await for (final chunk in request.read()) {
    byteCount += chunk.length;
    if (byteCount > 16 * 1024) {
      throw const FormatException('Request body is too large.');
    }
    bytes.add(chunk);
  }
  final source = utf8.decode(bytes.takeBytes(), allowMalformed: false);
  Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    throw const FormatException('Request body must be valid JSON.');
  }
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Request body must be a JSON object.');
  }
  return decoded;
}

Response? _validateWebSocketOrigin(
  Request request, {
  required bool allowLoopbackDevelopmentOrigins,
}) {
  final value = request.headers['origin'];
  // Native health/rehearsal clients do not send Origin. Browser clients do,
  // and may only read a stream from the exact relay origin that served them.
  if (value == null) {
    return null;
  }
  final origin = Uri.tryParse(value);
  final requested = request.requestedUri;
  final sameRelayOrigin =
      origin != null &&
      origin.scheme == requested.scheme &&
      origin.host.toLowerCase() == requested.host.toLowerCase() &&
      _effectivePort(origin) == _effectivePort(requested);
  final loopbackDevelopmentOrigin =
      allowLoopbackDevelopmentOrigins &&
      origin != null &&
      _isLoopbackHost(origin.host) &&
      _isLoopbackHost(requested.host);
  if (origin == null ||
      origin.userInfo.isNotEmpty ||
      (origin.scheme != 'http' && origin.scheme != 'https') ||
      (!sameRelayOrigin && !loopbackDevelopmentOrigin)) {
    return _jsonError(HttpStatus.forbidden, 'WebSocket origin is not allowed.');
  }
  return null;
}

bool _isLoopbackHost(String host) {
  if (host.toLowerCase() == 'localhost') {
    return true;
  }
  return InternetAddress.tryParse(host)?.isLoopback ?? false;
}

int _effectivePort(Uri uri) {
  if (uri.hasPort) {
    return uri.port;
  }
  return uri.scheme == 'https' ? 443 : 80;
}

bool _secureEquals(String left, String right) {
  final leftBytes = utf8.encode(left);
  final rightBytes = utf8.encode(right);
  var difference = leftBytes.length ^ rightBytes.length;
  final length = leftBytes.length > rightBytes.length ? leftBytes.length : rightBytes.length;
  for (var index = 0; index < length; index++) {
    final leftByte = index < leftBytes.length ? leftBytes[index] : 0;
    final rightByte = index < rightBytes.length ? rightBytes[index] : 0;
    difference |= leftByte ^ rightByte;
  }
  return difference == 0;
}

bool _isSafeIdentifier(String value) =>
    value.isNotEmpty && value.length <= 128 && RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(value);

Response _jsonResponse(Object body, {int statusCode = HttpStatus.ok}) => Response(
  statusCode,
  body: jsonEncode(body),
  headers: const {HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8'},
);

Response _jsonError(int statusCode, String message) => _jsonResponse(
  {'error': message},
  statusCode: statusCode,
);

Handler _securityHeaders(Handler innerHandler) => (Request request) async {
  final response = await innerHandler(request);
  return response.change(
    headers: {
      ...response.headers,
      'cache-control': 'no-store',
      'x-content-type-options': 'nosniff',
      'referrer-policy': 'no-referrer',
    },
  );
};

Handler _safeAccessLog(Handler innerHandler, void Function(String message) logger) => (Request request) async {
  final stopwatch = Stopwatch()..start();
  final response = await innerHandler(request);
  stopwatch.stop();
  final path = request.url.path.isEmpty ? '/' : '/${request.url.path}';
  logger('${request.method} $path ${response.statusCode} ${stopwatch.elapsedMilliseconds}ms');
  return response;
};
