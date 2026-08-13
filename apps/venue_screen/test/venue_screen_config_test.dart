import 'package:flutter_test/flutter_test.dart';
import 'package:venue_screen/core/config/venue_screen_config.dart';

void main() {
  test('builds a same-origin WebSocket URL for the local relay', () {
    final config = VenueScreenConfig.fromUri(
      Uri.parse('http://127.0.0.1:8088/?room=hall-a&session=opening'),
    );

    expect(config.webSocketUri, Uri.parse('ws://127.0.0.1:8088/ws?room=hall-a&session=opening'));
    expect(config.view, VenueScreenView.overlay);
    expect(config.maxLines, 1);
  });

  test('allows bounded layout tuning through query parameters', () {
    final config = VenueScreenConfig.fromUri(
      Uri.parse('http://localhost/?view=preview&maxLines=9&fontSize=8&opacity=0.2&bottom=100'),
    );

    expect(config.view, VenueScreenView.preview);
    expect(config.maxLines, 2);
    expect(config.fontSize, 36);
    expect(config.backgroundOpacity, 0.65);
    expect(config.bottomMargin, 100);
  });

  test('marks explicitly unsafe room and session identifiers invalid', () {
    final config = VenueScreenConfig.fromUri(
      Uri.parse('http://localhost/?room=../../secret&session=bad%20session'),
    );

    expect(config.isValid, isFalse);
    expect(config.configurationError, contains('room'));
    expect(config.configurationError, contains('session'));
  });

  test('uses defaults only when room and session are omitted', () {
    final config = VenueScreenConfig.fromUri(Uri.parse('http://localhost/'));

    expect(config.roomId, 'main');
    expect(config.sessionId, 'rehearsal');
    expect(config.isValid, isTrue);
  });

  test('preserves explicit remote WebSocket parameters for development', () {
    final config = VenueScreenConfig.fromUri(
      Uri.parse('http://localhost:50000/?ws=ws%3A%2F%2F127.0.0.1%3A8088%2Fws&room=main&session=keynote'),
    );

    expect(config.webSocketUri, Uri.parse('ws://127.0.0.1:8088/ws?room=main&session=keynote'));
  });

  test('does not copy unrelated parameters to the WebSocket URL', () {
    final config = VenueScreenConfig.fromUri(
      Uri.parse('http://127.0.0.1:8088/?room=main&session=keynote&debug=true'),
    );

    expect(config.webSocketUri, Uri.parse('ws://127.0.0.1:8088/ws?room=main&session=keynote'));
  });

  test('marks an explicitly invalid WebSocket override invalid', () {
    final config = VenueScreenConfig.fromUri(
      Uri.parse('http://localhost/?ws=https%3A%2F%2Fexample.com%2Fws'),
    );

    expect(config.isValid, isFalse);
    expect(config.configurationError, contains('ws'));
  });

  test('rejects credentials embedded in a WebSocket override', () {
    final config = VenueScreenConfig.fromUri(
      Uri.parse('http://localhost/?ws=ws%3A%2F%2Fuser%3Asecret%40example.com%2Fws'),
    );

    expect(config.isValid, isFalse);
    expect(config.configurationError, contains('without credentials'));
  });

  test('rejects a legacy token query parameter instead of silently ignoring it', () {
    final config = VenueScreenConfig.fromUri(
      Uri.parse('http://localhost/?room=main&session=keynote&token=event-secret'),
    );

    expect(config.isValid, isFalse);
    expect(config.configurationError, contains('credentials must not be placed in URL'));
    expect(config.webSocketUri.queryParameters, isNot(contains('token')));
  });

  test('rejects a token nested in an explicit WebSocket URL', () {
    final config = VenueScreenConfig.fromUri(
      Uri.parse(
        'http://localhost/?ws=ws%3A%2F%2F127.0.0.1%3A8088%2Fws%3Ftoken%3Devent-secret',
      ),
    );

    expect(config.isValid, isFalse);
    expect(config.configurationError, contains('ws URL'));
    expect(config.webSocketUri.queryParameters, isNot(contains('token')));
  });

  test('rejects a non-loopback WebSocket host', () {
    final config = VenueScreenConfig.fromUri(
      Uri.parse('http://localhost/?ws=ws%3A%2F%2F192.0.2.10%3A8088%2Fws'),
    );

    expect(config.isValid, isFalse);
    expect(config.configurationError, contains('local-only'));
  });
}
