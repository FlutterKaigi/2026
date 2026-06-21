import 'dart:io';

import 'package:captions_server/captions_server.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(
    () => tmp = Directory.systemTemp.createTempSync('captions_config_test'),
  );
  tearDown(() => tmp.deleteSync(recursive: true));

  String writeConfig(String json) {
    final file = File('${tmp.path}/config.json')..writeAsStringSync(json);
    return file.path;
  }

  String writeEnv(String content) {
    final file = File('${tmp.path}/env.dev')..writeAsStringSync(content);
    return file.path;
  }

  test('defaults apply when nothing is set', () {
    final config = Config.load({});
    expect(config.port, 8080);
    expect(config.ingestToken, 'dev-token');
    expect(config.transcriber, 'fake');
    expect(config.translator, 'echo');
    expect(config.sink, 'console');
    expect(config.geminiApiKey, isNull);
  });

  test(
    'values load from the CAPTIONS_CONFIG file, with number/boolean coercion',
    () {
      final path = writeConfig(
        '{"GEMINI_API_KEY": "file-key", "INGEST_TOKEN": "file-token", "PORT": 8085}',
      );
      final config = Config.load({'CAPTIONS_CONFIG': path});
      expect(config.geminiApiKey, 'file-key');
      expect(config.ingestToken, 'file-token');
      expect(config.port, 8085);
    },
  );

  test('values load from an env-style CAPTIONS_CONFIG file', () {
    final path = writeEnv('''
GEMINI_API_KEY=file-key
INGEST_TOKEN=file-token
PORT=8085
CAPTIONS_TRANSCRIBER=gemini
CAPTIONS_TRANSLATOR=gemini
CAPTIONS_SINK=firestore
''');
    final config = Config.load({'CAPTIONS_CONFIG': path});
    expect(config.geminiApiKey, 'file-key');
    expect(config.ingestToken, 'file-token');
    expect(config.port, 8085);
    expect(config.transcriber, 'gemini');
    expect(config.translator, 'gemini');
    expect(config.sink, 'firestore');
  });

  test(
    'dart defines can point at the config file and override file values',
    () {
      final path = writeEnv('''
INGEST_TOKEN=file-token
PORT=8085
CAPTIONS_SINK=console
''');
      final config = Config.load({}, {'CAPTIONS_CONFIG': path, 'PORT': '9090'});
      expect(config.ingestToken, 'file-token');
      expect(config.port, 9090);
      expect(config.sink, 'console');
    },
  );

  test('env wins over the config file', () {
    final path = writeConfig('{"INGEST_TOKEN": "file-token", "PORT": 8085}');
    final config = Config.load({
      'CAPTIONS_CONFIG': path,
      'INGEST_TOKEN': 'env-token',
    });
    expect(
      config.ingestToken,
      'env-token',
      reason: 'env must override the file',
    );
    expect(
      config.port,
      8085,
      reason: 'keys absent from env still come from the file',
    );
  });

  test('an explicit CAPTIONS_CONFIG pointing to a missing file fails fast', () {
    expect(
      () => Config.load({'CAPTIONS_CONFIG': '${tmp.path}/nope.json'}),
      throwsA(isA<ConfigException>()),
    );
  });

  test('invalid JSON, non-object JSON, and nested values fail fast', () {
    expect(
      () => Config.load({'CAPTIONS_CONFIG': writeConfig('not json')}),
      throwsA(isA<ConfigException>()),
    );
    expect(
      () => Config.load({'CAPTIONS_CONFIG': writeConfig('[1,2]')}),
      throwsA(isA<ConfigException>()),
    );
    expect(
      () => Config.load({
        'CAPTIONS_CONFIG': writeConfig('{"INGEST_TOKEN": {"nested": true}}'),
      }),
      throwsA(isA<ConfigException>()),
    );
  });

  test('on Cloud Run (K_SERVICE) the dev-default ingest token is refused', () {
    expect(
      () => Config.load({'K_SERVICE': 'captions'}),
      throwsA(isA<ConfigException>()),
    );
    expect(
      () => Config.load({'K_SERVICE': 'captions', 'INGEST_TOKEN': 'dev-token'}),
      throwsA(isA<ConfigException>()),
    );
    final config = Config.load({
      'K_SERVICE': 'captions',
      'INGEST_TOKEN': 'real-secret',
    });
    expect(config.ingestToken, 'real-secret');
  });

  test('describe() never contains secret values', () {
    final config = Config.load({
      'GEMINI_API_KEY': 'super-secret',
      'INGEST_TOKEN': 'another-secret',
    });
    final described = config.describe().toString();
    expect(described, isNot(contains('super-secret')));
    expect(described, isNot(contains('another-secret')));
    expect(config.describe()['geminiApiKey'], 'set');
    expect(config.describe()['ingestToken'], 'set');
  });
}
