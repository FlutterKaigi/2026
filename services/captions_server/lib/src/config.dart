import 'dart:convert';
import 'dart:io';

/// Runtime configuration (see TRANSLATION_BACKEND.md §5.4).
///
/// Resolution order: **process env > Dart define > config file > defaults**.
///
/// - Local dev: put secrets (`GEMINI_API_KEY`, `INGEST_TOKEN`) in
///   `environments/env.dev` or `config.local.json` (keys are the env var names)
///   or export them; `CAPTIONS_CONFIG` points at an alternative file path.
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
  static const _dartDefines = <String, String>{
    if (bool.hasEnvironment('CAPTIONS_CONFIG'))
      'CAPTIONS_CONFIG': String.fromEnvironment('CAPTIONS_CONFIG'),
    if (bool.hasEnvironment('PORT')) 'PORT': String.fromEnvironment('PORT'),
    if (bool.hasEnvironment('INGEST_TOKEN'))
      'INGEST_TOKEN': String.fromEnvironment('INGEST_TOKEN'),
    if (bool.hasEnvironment('CAPTIONS_TRANSCRIBER'))
      'CAPTIONS_TRANSCRIBER': String.fromEnvironment('CAPTIONS_TRANSCRIBER'),
    if (bool.hasEnvironment('CAPTIONS_TRANSLATOR'))
      'CAPTIONS_TRANSLATOR': String.fromEnvironment('CAPTIONS_TRANSLATOR'),
    if (bool.hasEnvironment('CAPTIONS_SINK'))
      'CAPTIONS_SINK': String.fromEnvironment('CAPTIONS_SINK'),
    if (bool.hasEnvironment('GEMINI_API_KEY'))
      'GEMINI_API_KEY': String.fromEnvironment('GEMINI_API_KEY'),
    if (bool.hasEnvironment('GEMINI_MODEL'))
      'GEMINI_MODEL': String.fromEnvironment('GEMINI_MODEL'),
    if (bool.hasEnvironment('GEMINI_TRANSCRIBE_MODEL'))
      'GEMINI_TRANSCRIBE_MODEL': String.fromEnvironment(
        'GEMINI_TRANSCRIBE_MODEL',
      ),
    if (bool.hasEnvironment('GOOGLE_CLOUD_PROJECT'))
      'GOOGLE_CLOUD_PROJECT': String.fromEnvironment('GOOGLE_CLOUD_PROJECT'),
    if (bool.hasEnvironment('FIRESTORE_EMULATOR_HOST'))
      'FIRESTORE_EMULATOR_HOST': String.fromEnvironment(
        'FIRESTORE_EMULATOR_HOST',
      ),
  };

  bool get usesFirestoreEmulator =>
      firestoreEmulatorHost != null && firestoreEmulatorHost!.isNotEmpty;

  /// Loads configuration from [env] (defaults to the process environment),
  /// overlaid on optional Dart defines and a config file.
  ///
  /// The file is `$CAPTIONS_CONFIG` if set (missing file = error), otherwise the
  /// first existing default of `config.local.json` or `environments/env.dev` in
  /// the working directory (missing file = fine). The implicit default file is
  /// only consulted when [env] is the real process environment, so tests passing
  /// an explicit map stay hermetic.
  factory Config.load([
    Map<String, String>? env,
    Map<String, String>? dartDefines,
  ]) {
    final e = env ?? Platform.environment;
    final defines = dartDefines ?? _dartDefines;
    final file = _loadConfigFile(e, defines, allowDefaultFile: env == null);
    String? get(String key) => e[key] ?? defines[key] ?? file[key];

    final ingestToken = get('INGEST_TOKEN');
    if (e['K_SERVICE'] != null &&
        (ingestToken == null ||
            ingestToken.isEmpty ||
            ingestToken == _devToken)) {
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
      geminiTranscribeModel:
          get('GEMINI_TRANSCRIBE_MODEL') ?? 'gemini-2.5-flash',
      googleCloudProject:
          get('GOOGLE_CLOUD_PROJECT') ?? 'dev-flutterkaigi-2026',
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
    'geminiApiKey': geminiApiKey == null || geminiApiKey!.isEmpty
        ? 'unset'
        : 'set',
    'ingestToken': ingestToken == _devToken ? 'dev-default' : 'set',
  };

  /// Reads the config file into env-style string pairs. JSON object files and
  /// `.env`-style `KEY=value` files are both accepted.
  static Map<String, String> _loadConfigFile(
    Map<String, String> env,
    Map<String, String> dartDefines, {
    required bool allowDefaultFile,
  }) {
    final explicit = env['CAPTIONS_CONFIG'] ?? dartDefines['CAPTIONS_CONFIG'];
    final path = explicit ?? (allowDefaultFile ? _defaultConfigPath() : null);
    if (path == null) return const {};

    final configFile = File(path);
    if (!configFile.existsSync()) {
      if (explicit != null) {
        throw ConfigException(
          'CAPTIONS_CONFIG points to a missing file: $path',
        );
      }
      return const {};
    }

    final content = configFile.readAsStringSync();
    if (!_looksLikeJson(content)) return _parseEnvFile(path, content);

    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException catch (err) {
      throw ConfigException(
        'config file $path is not valid JSON: ${err.message}',
      );
    }
    if (decoded is! Map<String, Object?>) {
      throw ConfigException(
        'config file $path must be a JSON object of env-style keys',
      );
    }

    final result = <String, String>{};
    for (final MapEntry(:key, :value) in decoded.entries) {
      result[key] = switch (value) {
        String s => s,
        num n => '$n',
        bool b => '$b',
        _ => throw ConfigException(
          'config file $path: value for "$key" must be a string, number, or boolean',
        ),
      };
    }
    return result;
  }

  static String? _defaultConfigPath() {
    for (final path in ['config.local.json', 'environments/env.dev']) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  static bool _looksLikeJson(String content) {
    final trimmed = content.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  static Map<String, String> _parseEnvFile(String path, String content) {
    final result = <String, String>{};
    final lines = const LineSplitter().convert(content);
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty || raw.startsWith('#')) continue;
      final line = raw.startsWith('export ')
          ? raw.substring(7).trimLeft()
          : raw;
      final separator = line.indexOf('=');
      if (separator <= 0) {
        throw ConfigException('config file $path:${i + 1} must be KEY=value');
      }
      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      if (key.isEmpty) {
        throw ConfigException('config file $path:${i + 1} has an empty key');
      }
      result[key] = _unquoteEnvValue(value);
    }
    return result;
  }

  static String _unquoteEnvValue(String value) {
    if (value.length < 2) return value;
    final first = value.codeUnitAt(0);
    final last = value.codeUnitAt(value.length - 1);
    if ((first == 0x22 && last == 0x22) || (first == 0x27 && last == 0x27)) {
      return value.substring(1, value.length - 1);
    }
    return value;
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
