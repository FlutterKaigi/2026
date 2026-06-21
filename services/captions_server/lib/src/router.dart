import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'ingest_handler.dart';
import 'pipeline/transcriber.dart';
import 'pipeline/translator.dart';

/// Builds the application router: `GET /healthz` and `GET /v1/ingest/<roomId>`.
Router buildRouter({
  required Config config,
  required Transcriber transcriber,
  required Translator translator,
  required SinkFactory sinkFactory,
}) {
  final router = Router();
  router.get('/healthz', (Request request) => Response.ok('ok'));
  router.get(
    '/v1/ingest/<roomId>',
    ingestHandler(
      config: config,
      transcriber: transcriber,
      translator: translator,
      sinkFactory: sinkFactory,
    ),
  );
  return router;
}
