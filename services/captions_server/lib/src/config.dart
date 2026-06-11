import 'dart:convert';
import 'dart:io';

/// Runtime configuration (see TRANSLATION_BACKEND.md §5.4).
///
/// Resolution order: **process env > config JSON file > defaults**.
///
/// - Local dev: put secrets (`GEMINI_API_KEY`, `INGEST_TOKEN`) in
///   `config.local.json` (gitignored, keys are the env var names) or export
///   them; `CAPTIONS_CONFIG` points at an alternative file path.
/// - Cloud Run: plain settings arrive via `--set-env-vars`; secrets live in
///   Google Secret Manager and are injected as env vars via `--set-secrets`.
///   The app never calls the Secret Manager API itself. As a guard, startup
///   fails on Cloud Run (`K_SERVICE` present) if `INGEST_TOKEN` was not set
///   explicitly.
///
/// Loaded once at startup so the rest of the code never reads
/// [Platform.environment] directly.
class Config {
  const Config({
    required this.port,
    required this.ingestToken,
    required this.transcriber,
    required this.translator,
    required this.sink,
    required this.geminiApiKey,
    required this.geminiModel,
    required this.geminiTranscribeModel,
    required this.googleCloudProject,
    required this.firestoreEmulatorHost,
  });

  /// HTTP port. Defaults to 8080 (Cloud Run compatible); run locally on 8082 to
  /// avoid colliding with the Firestore emulator on 8080.
  final int port;

  /// Bearer token required on the ingest WebSocket. **Secret.**
  final String ingestToken;

  /// Transcriber implementation: `fake` | `gemini`.
  final String transcriber;

  /// Translator implementation: `echo` | `gemini`.
  final String translator;

  /// Caption sink implementation: `console` | `firestore`.
  final String sink;

  /// Gemini API key (required when [translator] or [transcriber] is `gemini`).
  /// **Secret.**
  final String? geminiApiKey;

  /// Gemini model name used for translation.
  final String geminiModel;

  /// Gemini model name used for transcription (audio understanding).
  final String geminiTranscribeModel;

  /// Target Google Cloud project for Firestore.
  final String googleCloudProject;

  /// When set (e.g. `localhost:8080`), the Firestore sink targets the emulator.
  final String? firestoreEmulatorHost;

  static const _devToken = 'dev-token';

  bool get usesFirestoreEmulator => firestoreEmulatorHost != null && firestoreEmulatorHost!.isNotEmpty;

  /// Loads configuration from [env] (defaults to the process environment),
  /// overlaid on an optional JSON config file.
  ///
  /// The file is `$CAPTIONS_CONFIG` if set (missing file = error), otherwise
  /// `config.local.json` in the working directory (missing file = fine). The
  /// implicit default file is only consulted when [env] is the real process
  /// environment, so tests passing an explicit map stay hermetic.
  factory Config.load([Map<String, String>? env]) {
    final e = env ?? Platform.environment;
    final file = _loadConfigFile(e, allowDefaultFile: env == null);
    String? get(String key) => e[key] ?? file[key];

    final ingestToken = get('INGEST_TOKEN');
    if (e['K_SERVICE'] != null && (ingestToken == null || ingestToken.isEmpty || ingestToken == _devToken)) {
      throw ConfigException(
        'INGEST_TOKEN must be set explicitly on Cloud Run — '
        'mount it from Secret Manager (gcloud run deploy --set-secrets=INGEST_TOKEN=ingest-token:latest)',
      );
    }

    return Config(
      port: int.tryParse(get('PORT') ?? '') ?? 8080,
      ingestToken: ingestToken ?? _devToken,
      transcriber: get('CAPTIONS_TRANSCRIBER') ?? 'fake',
      translator: get('CAPTIONS_TRANSLATOR') ?? 'echo',
      sink: get('CAPTIONS_SINK') ?? 'console',
      geminiApiKey: get('GEMINI_API_KEY'),
      geminiModel: get('GEMINI_MODEL') ?? 'gemini-2.5-flash-lite',
      geminiTranscribeModel: get('GEMINI_TRANSCRIBE_MODEL') ?? 'gemini-2.5-flash',
      googleCloudProject: get('GOOGLE_CLOUD_PROJECT') ?? 'dev-flutterkaigi-2026',
      firestoreEmulatorHost: get('FIRESTORE_EMULATOR_HOST'),
    );
  }

  /// Non-sensitive summary for startup logging: secrets are reported by
  /// presence only, never by value.
  Map<String, Object?> describe() => {
        'port': port,
        'transcriber': transcriber,
        'translator': translator,
        'sink': sink,
        'geminiModel': geminiModel,
        'geminiTranscribeModel': geminiTranscribeModel,
        'googleCloudProject': googleCloudProject,
        'firestoreEmulator': usesFirestoreEmulator,
        'geminiApiKey': geminiApiKey == null || geminiApiKey!.isEmpty ? 'unset' : 'set',
        'ingestToken': ingestToken == _devToken ? 'dev-default' : 'set',
      };

  /// Reads the JSON config file into env-style string pairs. Keys are env var
  /// names; values may be strings, numbers, or booleans.
  static Map<String, String> _loadConfigFile(Map<String, String> env, {required bool allowDefaultFile}) {
    final explicit = env['CAPTIONS_CONFIG'];
    final path = explicit ?? (allowDefaultFile ? 'config.local.json' : null);
    if (path == null) return const {};

    final configFile = File(path);
    if (!configFile.existsSync()) {
      if (explicit != null) {
        throw ConfigException('CAPTIONS_CONFIG points to a missing file: $path');
      }
      return const {};
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(configFile.readAsStringSync());
    } on FormatException catch (err) {
      throw ConfigException('config file $path is not valid JSON: ${err.message}');
    }
    if (decoded is! Map<String, Object?>) {
      throw ConfigException('config file $path must be a JSON object of env-style keys');
    }

    final result = <String, String>{};
    for (final MapEntry(:key, :value) in decoded.entries) {
      result[key] = switch (value) {
        String s => s,
        num n => '$n',
        bool b => '$b',
        _ => throw ConfigException('config file $path: value for "$key" must be a string, number, or boolean'),
      };
    }
    return result;
  }
}

/// Thrown when configuration selects an implementation that does not exist or is
/// missing a required value.
class ConfigException implements Exception {
  ConfigException(this.message);
  final String message;
  @override
  String toString() => 'ConfigException: $message';
}
