import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:caption_relay/caption_relay.dart';
import 'package:shelf/shelf_io.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('host', defaultsTo: '127.0.0.1', help: 'Address to bind. Loopback is the safe default.')
    ..addOption('port', defaultsTo: '8088', help: 'HTTP and WebSocket port.')
    ..addOption('web-root', help: 'Built Flutter Web directory to serve.')
    ..addFlag(
      'allow-loopback-development-origin',
      negatable: false,
      help: 'Allow a Flutter dev server on another loopback port to read WebSocket captions.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');
  final options = parser.parse(arguments);
  if (options.flag('help')) {
    stdout.writeln('FlutterKaigi venue caption relay\n\n${parser.usage}');
    return;
  }

  final host = options.option('host')!;
  final port = int.tryParse(options.option('port')!);
  if (port == null || port < 1 || port > 65535) {
    stderr.writeln('--port must be between 1 and 65535.');
    exitCode = 64;
    return;
  }
  if (!_isLoopback(host)) {
    stderr.writeln('The venue caption relay is local-only; --host must be a loopback address.');
    exitCode = 78;
    return;
  }
  final writeToken = Platform.environment['VENUE_CAPTION_WRITE_TOKEN'];
  if (writeToken == null || writeToken.length < 32) {
    stderr.writeln('VENUE_CAPTION_WRITE_TOKEN must contain at least 32 characters.');
    exitCode = 78;
    return;
  }

  final hub = CaptionHub();
  final handler = createCaptionRelayHandler(
    hub: hub,
    writeToken: writeToken,
    webRoot: options.option('web-root'),
    requestLogger: stdout.writeln,
    allowLoopbackDevelopmentOrigins: options.flag('allow-loopback-development-origin'),
  );
  final server = await serve(handler, host, port);
  server.autoCompress = true;

  final publicHost = server.address.type == InternetAddressType.IPv6
      ? '[${server.address.address}]'
      : server.address.address;
  stdout
    ..writeln('Caption relay listening on http://$publicHost:${server.port}')
    ..writeln(
      'Overlay: http://$publicHost:${server.port}/?room=main&session=rehearsal',
    )
    ..writeln(
      'Preview: http://$publicHost:${server.port}/?view=preview&room=main&session=rehearsal',
    )
    ..writeln('Caption writes require VENUE_CAPTION_WRITE_TOKEN; the token is never placed in a URL.');
  if (options.flag('allow-loopback-development-origin')) {
    stdout.writeln('WARNING: cross-origin loopback WebSocket reads are enabled for local development.');
  }

  final signal = await ProcessSignal.sigint.watch().first;
  stdout.writeln('Received $signal; shutting down.');
  await server.close(force: true);
  await hub.close();
}

bool _isLoopback(String host) => host == '127.0.0.1' || host == 'localhost' || host == '::1';
