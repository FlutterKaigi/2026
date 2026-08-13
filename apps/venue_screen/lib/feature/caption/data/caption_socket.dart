import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

abstract interface class CaptionSocket {
  Stream<Object?> get messages;

  Future<void> close();
}

abstract interface class CaptionSocketConnector {
  CaptionSocket connect(Uri uri);
}

final class WebSocketCaptionConnector implements CaptionSocketConnector {
  const WebSocketCaptionConnector();

  @override
  CaptionSocket connect(Uri uri) => _WebSocketCaptionSocket(WebSocketChannel.connect(uri));
}

final class _WebSocketCaptionSocket implements CaptionSocket {
  _WebSocketCaptionSocket(this._channel);

  final WebSocketChannel _channel;

  @override
  Stream<Object?> get messages => _channel.stream;

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}
