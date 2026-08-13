import 'dart:async';

import 'package:caption_protocol/caption_protocol.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:venue_screen/core/config/venue_screen_config.dart';
import 'package:venue_screen/feature/caption/data/caption_socket.dart';
import 'package:venue_screen/feature/caption/provider/caption_overlay_controller.dart';

void main() {
  final now = DateTime.utc(2026, 11, 7, 1);
  late _FakeCaptionSocket socket;
  late CaptionOverlayController controller;

  setUp(() {
    socket = _FakeCaptionSocket();
    controller = CaptionOverlayController(
      config: _config,
      connector: _FakeConnector(socket),
      clock: () => now,
    )..start();
  });

  tearDown(() => controller.dispose());

  test('shows a current caption and marks the stream connected', () {
    socket.add(
      CaptionEvent.caption(
        roomId: 'main',
        sessionId: 'opening',
        sequence: 1,
        utteranceId: 'test-utterance',
        utteranceSequence: 0,
        revision: 0,
        translatedText: 'Welcome',
        isFinal: false,
        sourceStartedAt: now.subtract(const Duration(seconds: 1)),
        producedAt: now,
        clearAt: now.add(const Duration(seconds: 8)),
      ),
    );

    expect(controller.caption?.translatedText, 'Welcome');
    expect(controller.status, CaptionConnectionStatus.connected);
  });

  test('ignores an event that arrives out of order', () {
    socket
      ..add(
        CaptionEvent.caption(
          roomId: 'main',
          sessionId: 'opening',
          sequence: 2,
          utteranceId: 'test-utterance',
          utteranceSequence: 0,
          revision: 1,
          translatedText: 'Current caption',
          isFinal: true,
          sourceStartedAt: now.subtract(const Duration(seconds: 1)),
          producedAt: now,
          clearAt: now.add(const Duration(seconds: 8)),
        ),
      )
      ..add(
        CaptionEvent.caption(
          roomId: 'main',
          sessionId: 'opening',
          sequence: 1,
          utteranceId: 'test-utterance',
          utteranceSequence: 0,
          revision: 0,
          translatedText: 'Late partial caption',
          isFinal: false,
          sourceStartedAt: now.subtract(const Duration(seconds: 1)),
          producedAt: now,
          clearAt: now.add(const Duration(seconds: 8)),
        ),
      );

    expect(controller.caption?.translatedText, 'Current caption');
    expect(controller.droppedMessageCount, 1);
  });

  test('ignores another room even if the producer is misconfigured', () {
    socket.add(
      CaptionEvent.caption(
        roomId: 'hall-b',
        sessionId: 'opening',
        sequence: 1,
        utteranceId: 'test-utterance',
        utteranceSequence: 0,
        revision: 0,
        translatedText: 'Wrong room',
        isFinal: true,
        sourceStartedAt: now.subtract(const Duration(seconds: 1)),
        producedAt: now,
        clearAt: now.add(const Duration(seconds: 8)),
      ),
    );

    expect(controller.caption, isNull);
    expect(controller.droppedMessageCount, 1);
  });

  test('drops an event produced too far in the future', () {
    socket.add(
      CaptionEvent.caption(
        roomId: 'main',
        sessionId: 'opening',
        sequence: 1,
        utteranceId: 'future-utterance',
        utteranceSequence: 1,
        revision: 0,
        translatedText: 'Future caption',
        isFinal: true,
        sourceStartedAt: now.subtract(const Duration(seconds: 1)),
        producedAt: now.add(const Duration(seconds: 6)),
        clearAt: now.add(const Duration(seconds: 14)),
      ),
    );

    expect(controller.caption, isNull);
    expect(controller.droppedMessageCount, 1);
  });

  test('clear event immediately removes the current caption', () {
    socket
      ..add(
        CaptionEvent.caption(
          roomId: 'main',
          sessionId: 'opening',
          sequence: 1,
          utteranceId: 'test-utterance',
          utteranceSequence: 0,
          revision: 0,
          translatedText: 'Visible',
          isFinal: true,
          sourceStartedAt: now.subtract(const Duration(seconds: 1)),
          producedAt: now,
          clearAt: now.add(const Duration(seconds: 8)),
        ),
      )
      ..add(
        CaptionEvent.clear(
          roomId: 'main',
          sessionId: 'opening',
          sequence: 2,
          producedAt: now,
        ),
      );

    expect(controller.caption, isNull);
  });

  test('malformed messages are dropped without disconnecting the audience surface', () {
    socket.addRaw('{not-json');

    expect(controller.caption, isNull);
    expect(controller.droppedMessageCount, 1);
    expect(controller.status, CaptionConnectionStatus.connecting);
  });

  test('does not connect when explicit stream configuration is invalid', () {
    final invalidSocket = _FakeCaptionSocket();
    final connector = _FakeConnector(invalidSocket);
    final invalidController = CaptionOverlayController(
      config: _configWithError,
      connector: connector,
      clock: () => now,
    )..start();

    expect(invalidController.status, CaptionConnectionStatus.configurationError);
    expect(connector.connectCount, 0);
    expect(invalidController.caption, isNull);
    invalidController.dispose();
  });

  test('starts the stale watchdog before the first relay message', () {
    fakeAsync((async) {
      final silentSocket = _FakeCaptionSocket();
      final silentController = CaptionOverlayController(
        config: _configWithShortStaleTimeout,
        connector: _FakeConnector(silentSocket),
        clock: () => now,
      )..start();

      async.elapse(const Duration(seconds: 6));

      expect(silentController.status, CaptionConnectionStatus.stale);
      expect(silentController.caption, isNull);
      expect(silentSocket.clientCloseCount, 1);
      expect(silentSocket.hasListener, isFalse);
      silentController.dispose();
    });
  });

  test('tears down a disconnected socket before scheduling reconnect', () {
    fakeAsync((async) {
      final disconnectedSocket = _FakeCaptionSocket();
      final disconnectedController = CaptionOverlayController(
        config: _config,
        connector: _FakeConnector(disconnectedSocket),
        clock: () => now,
      )..start();

      disconnectedSocket.finishFromRemote();
      async.flushMicrotasks();

      expect(disconnectedController.status, CaptionConnectionStatus.disconnected);
      expect(disconnectedSocket.clientCloseCount, 1);
      expect(disconnectedSocket.hasListener, isFalse);
      disconnectedController.dispose();
    });
  });

  test('automatically removes a caption at its clearAt deadline', () {
    fakeAsync((async) {
      final timedSocket = _FakeCaptionSocket();
      final timedController = CaptionOverlayController(
        config: _config,
        connector: _FakeConnector(timedSocket),
        clock: () => now,
      )..start();
      timedSocket.add(
        CaptionEvent.caption(
          roomId: 'main',
          sessionId: 'opening',
          sequence: 1,
          utteranceId: 'test-utterance',
          utteranceSequence: 0,
          revision: 0,
          translatedText: 'Short-lived caption',
          isFinal: true,
          sourceStartedAt: now.subtract(const Duration(seconds: 1)),
          producedAt: now,
          clearAt: now.add(const Duration(seconds: 2)),
        ),
      );

      expect(timedController.caption, isNotNull);
      async.elapse(const Duration(seconds: 2));
      expect(timedController.caption, isNull);
      timedController.dispose();
    });
  });

  test('hides the caption when relay heartbeats become stale', () {
    fakeAsync((async) {
      final staleSocket = _FakeCaptionSocket();
      final staleController = CaptionOverlayController(
        config: _configWithShortStaleTimeout,
        connector: _FakeConnector(staleSocket),
        clock: () => now,
      )..start();
      staleSocket.add(
        CaptionEvent.caption(
          roomId: 'main',
          sessionId: 'opening',
          sequence: 1,
          utteranceId: 'test-utterance',
          utteranceSequence: 0,
          revision: 0,
          translatedText: 'Do not leave this stuck on screen',
          isFinal: true,
          sourceStartedAt: now.subtract(const Duration(seconds: 1)),
          producedAt: now,
          clearAt: now.add(const Duration(seconds: 30)),
        ),
      );

      async.elapse(const Duration(seconds: 6));
      expect(staleController.caption, isNull);
      expect(staleController.status, CaptionConnectionStatus.stale);
      staleController.dispose();
    });
  });
}

final _config = VenueScreenConfig(
  webSocketUri: Uri.parse('ws://127.0.0.1:8088/ws?room=main&session=opening'),
  roomId: 'main',
  sessionId: 'opening',
  view: VenueScreenView.overlay,
  maxLines: 1,
  fontSize: 64,
  lineHeight: 1.25,
  horizontalMargin: 72,
  bottomMargin: 54,
  backgroundOpacity: 0.88,
  staleAfter: const Duration(minutes: 1),
);

final _configWithShortStaleTimeout = VenueScreenConfig(
  webSocketUri: Uri.parse('ws://127.0.0.1:8088/ws?room=main&session=opening'),
  roomId: 'main',
  sessionId: 'opening',
  view: VenueScreenView.overlay,
  maxLines: 1,
  fontSize: 64,
  lineHeight: 1.25,
  horizontalMargin: 72,
  bottomMargin: 54,
  backgroundOpacity: 0.88,
  staleAfter: const Duration(seconds: 6),
);

final _configWithError = VenueScreenConfig(
  webSocketUri: Uri.parse('ws://127.0.0.1:8088/ws?room=main&session=opening'),
  roomId: '../../invalid',
  sessionId: 'opening',
  view: VenueScreenView.overlay,
  maxLines: 1,
  fontSize: 64,
  lineHeight: 1.25,
  horizontalMargin: 72,
  bottomMargin: 54,
  backgroundOpacity: 0.88,
  staleAfter: const Duration(seconds: 12),
  configurationError: 'room must be a safe identifier',
);

final class _FakeConnector implements CaptionSocketConnector {
  _FakeConnector(this.socket);

  final CaptionSocket socket;
  int connectCount = 0;

  @override
  CaptionSocket connect(Uri uri) {
    connectCount++;
    return socket;
  }
}

final class _FakeCaptionSocket implements CaptionSocket {
  final StreamController<Object?> _controller = StreamController<Object?>.broadcast(sync: true);
  int clientCloseCount = 0;

  bool get hasListener => _controller.hasListener;

  @override
  Stream<Object?> get messages => _controller.stream;

  void add(CaptionEvent event) => _controller.add(event.toJsonString());

  void addRaw(String message) => _controller.add(message);

  void finishFromRemote() => unawaited(_controller.close());

  @override
  Future<void> close() async {
    clientCloseCount++;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
