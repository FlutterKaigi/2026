import 'dart:io';

import 'package:captions_server/captions_server.dart';
import 'package:captions_server/src/logging.dart';

Future<void> main(List<String> args) async {
  final config = Config.load();
  logEvent('config', config.describe());
  final server = await serveCaptions(config);

  // Best-effort graceful shutdown (Cloud Run sends SIGTERM, Ctrl-C SIGINT).
  for (final signal in [ProcessSignal.sigterm, ProcessSignal.sigint]) {
    signal.watch().listen((_) async {
      await server.close(force: true);
      exit(0);
    });
  }
}
