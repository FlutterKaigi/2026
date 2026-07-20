/// Public API for the FlutterKaigi 2026 live captions server.
library;

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:dart_firebase_admin/firestore.dart';

import 'src/config.dart';
import 'src/ingest_handler.dart';
import 'src/logging.dart';
import 'src/pipeline/console_sink.dart';
import 'src/pipeline/echo_translator.dart';
import 'src/pipeline/fake_transcriber.dart';
import 'src/pipeline/firestore_sink.dart';
import 'src/pipeline/gemini_transcriber.dart';
import 'src/pipeline/gemini_translator.dart';
import 'src/pipeline/session_context.dart';
import 'src/pipeline/transcriber.dart';
import 'src/pipeline/translator.dart';
import 'src/router.dart';

export 'src/config.dart';
export 'src/ingest_handler.dart' show SinkFactory;
export 'src/models/caption_segment.dart';
export 'src/models/ws_messages.dart';
export 'src/pipeline/audio_segmenter.dart';
export 'src/pipeline/caption_sink.dart';
export 'src/pipeline/console_sink.dart';
export 'src/pipeline/echo_translator.dart';
export 'src/pipeline/fake_transcriber.dart';
export 'src/pipeline/firestore_sink.dart';
export 'src/pipeline/gemini_transcriber.dart';
export 'src/pipeline/gemini_translator.dart';
export 'src/pipeline/interim_throttle.dart';
export 'src/pipeline/pipeline.dart';
export 'src/pipeline/session_context.dart';
export 'src/pipeline/transcriber.dart';
export 'src/pipeline/translator.dart';
export 'src/pipeline/wav.dart';

/// Selects a [Transcriber] implementation from [config].
Transcriber buildTranscriber(Config config) => switch (config.transcriber) {
      'fake' => FakeTranscriber(),
      'gemini' => GeminiTranscriber(
          apiKey: config.geminiApiKey ??
              (throw ConfigException('GEMINI_API_KEY is required when CAPTIONS_TRANSCRIBER=gemini')),
          model: config.geminiTranscribeModel,
        ),
      _ => throw ConfigException('unknown CAPTIONS_TRANSCRIBER: ${config.transcriber}'),
    };

/// Selects a [Translator] implementation from [config].
Translator buildTranslator(Config config) => switch (config.translator) {
      'echo' => const EchoTranslator(),
      'gemini' => GeminiTranslator(
          apiKey: config.geminiApiKey ??
              (throw ConfigException('GEMINI_API_KEY is required when CAPTIONS_TRANSLATOR=gemini')),
          model: config.geminiModel,
        ),
      _ => throw ConfigException('unknown CAPTIONS_TRANSLATOR: ${config.translator}'),
    };

/// Selects a per-connection [SinkFactory] from [config]. Pass [firestore] to
/// reuse an existing client instead of creating one.
SinkFactory buildSinkFactory(Config config, {Firestore? firestore}) {
  switch (config.sink) {
    case 'console':
      return (_) => const ConsoleSink();
    case 'firestore':
      final client = firestore ??
          createFirestore(
            projectId: config.googleCloudProject,
            emulatorHost: config.firestoreEmulatorHost,
          );
      return (startMs) => FirestoreSink(client, connectionStartMs: startMs);
    default:
      throw ConfigException('unknown CAPTIONS_SINK: ${config.sink}');
  }
}

/// Builds the top-level request handler (router + structured request logging).
/// Components default to the [config] selection but can be overridden (tests).
///
/// With the Firestore sink, a [FirestoreSessionContextLoader] sharing the same
/// client is wired automatically so Gemini prompts receive the conference
/// proper nouns (session title, speakers, sponsors) of the ingesting room.
Handler createCaptionsHandler(
  Config config, {
  Transcriber? transcriber,
  Translator? translator,
  SinkFactory? sinkFactory,
  SessionContextLoader? contextLoader,
}) {
  Firestore? firestore;
  if (config.sink == 'firestore' && (sinkFactory == null || contextLoader == null)) {
    firestore = createFirestore(
      projectId: config.googleCloudProject,
      emulatorHost: config.firestoreEmulatorHost,
    );
  }
  final router = buildRouter(
    config: config,
    transcriber: transcriber ?? buildTranscriber(config),
    translator: translator ?? buildTranslator(config),
    sinkFactory: sinkFactory ?? buildSinkFactory(config, firestore: firestore),
    contextLoader: contextLoader ?? (firestore == null ? null : FirestoreSessionContextLoader(firestore)),
  );
  return const Pipeline().addMiddleware(_logMiddleware()).addHandler(router.call);
}

/// Starts the captions HTTP server on `config.port` (all interfaces).
Future<HttpServer> serveCaptions(
  Config config, {
  Transcriber? transcriber,
  Translator? translator,
  SinkFactory? sinkFactory,
  SessionContextLoader? contextLoader,
}) async {
  final handler = createCaptionsHandler(
    config,
    transcriber: transcriber,
    translator: translator,
    sinkFactory: sinkFactory,
    contextLoader: contextLoader,
  );
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, config.port);
  logEvent('server_listening', {'port': server.port});
  return server;
}

Middleware _logMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      final response = await inner(request);
      // Health checks are noisy; log everything else (incl. 401s and upgrades).
      if (request.url.path != 'healthz') {
        logEvent('http', {
          'method': request.method,
          'path': '/${request.url.path}',
          'status': response.statusCode,
        });
      }
      return response;
    };
  };
}
