/// Validates and seeds Firestore Emulator documents from JSON fixtures.
///
/// Run via:
///
/// ```sh
/// fvm dart run melos firebase:schema:validate
/// fvm dart run melos firebase:seed
/// ```
library;

import 'dart:convert';
import 'dart:io';

const _defaultProjectId = 'dev-flutterkaigi-2026';
const _defaultSeedPath = 'packages/data/firebase/seed/firestore/default.json';
const _defaultFirestoreHost = 'localhost:8080';
const _schemaDir = 'packages/data/firebase/schemas/firestore';

Future<void> main(List<String> args) async {
  late final _Options options;
  try {
    options = _Options.parse(args);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln();
    stderr.write(_usage);
    exitCode = 64;
    return;
  }

  if (options.showHelp) {
    stdout.write(_usage);
    return;
  }

  late final _SeedFile seed;
  try {
    seed = _readSeed(options.seedPath);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exitCode = 1;
    return;
  }

  final errors = _validateSeed(seed);
  if (errors.isNotEmpty) {
    stderr.writeln('Firebase seed validation failed:');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }

  if (options.validateOnly) {
    stdout.writeln('Validated ${seed.documents.length} Firestore document(s).');
    return;
  }

  final projectId = options.projectId ?? Platform.environment['FIREBASE_PROJECT_ID'] ?? seed.projectId;
  final host = _normalizeHost(
    options.firestoreHost ?? Platform.environment['FIRESTORE_EMULATOR_HOST'] ?? _defaultFirestoreHost,
  );

  final client = HttpClient();
  try {
    for (final document in seed.documents) {
      await _upsertDocument(
        client: client,
        host: host,
        projectId: projectId,
        document: document,
      );
      stdout.writeln('Seeded ${document.path}');
    }
  } finally {
    client.close(force: true);
  }
}

const _usage = '''
Usage: fvm dart run tool/firebase_seed.dart [options] [seed-file]

Options:
  --validate-only       Validate seed data against JSON Schemas without writing to Firestore.
  --project <id>        Firebase project ID. Defaults to FIREBASE_PROJECT_ID or the seed file projectId.
  --host <host:port>    Firestore Emulator host. Defaults to FIRESTORE_EMULATOR_HOST or localhost:8080.
  -h, --help            Show this help.
''';

class _Options {
  const _Options({
    required this.seedPath,
    required this.validateOnly,
    required this.showHelp,
    this.projectId,
    this.firestoreHost,
  });

  final String seedPath;
  final bool validateOnly;
  final bool showHelp;
  final String? projectId;
  final String? firestoreHost;

  static _Options parse(List<String> args) {
    var seedPath = _defaultSeedPath;
    var validateOnly = false;
    var showHelp = false;
    String? projectId;
    String? firestoreHost;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '--validate-only':
          validateOnly = true;
        case '-h' || '--help':
          showHelp = true;
        case '--project':
          projectId = _readOptionValue(args, ++i, '--project');
        case '--host':
          firestoreHost = _readOptionValue(args, ++i, '--host');
        default:
          if (arg.startsWith('--project=')) {
            projectId = arg.substring('--project='.length);
          } else if (arg.startsWith('--host=')) {
            firestoreHost = arg.substring('--host='.length);
          } else if (arg.startsWith('-')) {
            throw FormatException('Unknown option: $arg');
          } else {
            seedPath = arg;
          }
      }
    }

    return _Options(
      seedPath: seedPath,
      validateOnly: validateOnly,
      showHelp: showHelp,
      projectId: projectId,
      firestoreHost: firestoreHost,
    );
  }
}

String _readOptionValue(List<String> args, int index, String optionName) {
  if (index >= args.length || args[index].startsWith('-')) {
    throw FormatException('$optionName requires a value.');
  }
  return args[index];
}

class _SeedFile {
  const _SeedFile({
    required this.projectId,
    required this.documents,
  });

  final String projectId;
  final List<_SeedDocument> documents;
}

class _SeedDocument {
  const _SeedDocument({
    required this.path,
    required this.schema,
    required this.data,
  });

  final String path;
  final String schema;
  final Map<String, Object?> data;
}

_SeedFile _readSeed(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw FormatException('Seed file not found: $path');
  }

  final decoded = jsonDecode(file.readAsStringSync());
  final root = _asStringMap(decoded);
  if (root == null) {
    throw FormatException('Seed file must contain a JSON object: $path');
  }

  final projectId = root['projectId'];
  final documents = root['documents'];
  if (projectId != null && projectId is! String) {
    throw FormatException('Seed field "projectId" must be a string.');
  }
  if (documents is! List) {
    throw FormatException('Seed field "documents" must be an array.');
  }

  return _SeedFile(
    projectId: projectId as String? ?? _defaultProjectId,
    documents: [
      for (var i = 0; i < documents.length; i++) _readSeedDocument(documents[i], i),
    ],
  );
}

_SeedDocument _readSeedDocument(Object? value, int index) {
  final root = _asStringMap(value);
  if (root == null) {
    throw FormatException('Seed documents[$index] must be an object.');
  }

  final path = root['path'];
  final schema = root['schema'];
  final data = _asStringMap(root['data']);
  if (path is! String || path.isEmpty) {
    throw FormatException('Seed documents[$index].path must be a non-empty string.');
  }
  if (schema is! String || schema.isEmpty) {
    throw FormatException('Seed documents[$index].schema must be a non-empty string.');
  }
  if (data == null) {
    throw FormatException('Seed documents[$index].data must be an object.');
  }

  return _SeedDocument(path: path, schema: schema, data: data);
}

List<String> _validateSeed(_SeedFile seed) {
  final errors = <String>[];
  final schemas = <String, Map<String, Object?>>{};

  for (var i = 0; i < seed.documents.length; i++) {
    final document = seed.documents[i];
    if (!_isFirestoreDocumentPath(document.path)) {
      errors.add('documents[$i].path must be a Firestore document path such as "news/example".');
    }

    final schema = schemas.putIfAbsent(document.schema, () => _readSchema(document.schema, errors));
    if (schema.isEmpty) continue;

    errors.addAll(
      _JsonSchemaValidator(schema).validate(
        document.data,
        r'$.documents['
        '$i'
        r'].data',
      ),
    );
  }

  return errors;
}

Map<String, Object?> _readSchema(String name, List<String> errors) {
  final file = File('$_schemaDir/$name.schema.json');
  if (!file.existsSync()) {
    errors.add('Schema not found for "$name": ${file.path}');
    return const {};
  }

  final decoded = jsonDecode(file.readAsStringSync());
  final root = _asStringMap(decoded);
  if (root == null) {
    errors.add('Schema "$name" must contain a JSON object.');
    return const {};
  }
  return root;
}

bool _isFirestoreDocumentPath(String path) {
  final segments = path.split('/');
  return segments.length.isEven && segments.every((segment) => segment.isNotEmpty);
}

class _JsonSchemaValidator {
  const _JsonSchemaValidator(this.rootSchema);

  final Map<String, Object?> rootSchema;

  List<String> validate(Object? value, String path) {
    final errors = <String>[];
    _validateValue(value, rootSchema, path, errors);
    return errors;
  }

  void _validateValue(
    Object? value,
    Map<String, Object?> schema,
    String path,
    List<String> errors,
  ) {
    final ref = schema[r'$ref'];
    if (ref is String) {
      _validateValue(value, _resolveRef(ref), path, errors);
      return;
    }

    final type = schema['type'];
    if (type != null && !_matchesType(value, type)) {
      errors.add('$path must be ${_typeDescription(type)}.');
      return;
    }

    final enumValues = schema['enum'];
    if (enumValues is List && !enumValues.any((candidate) => candidate == value)) {
      errors.add('$path must be one of ${jsonEncode(enumValues)}.');
    }

    final anyOf = schema['anyOf'];
    if (anyOf is List) {
      final matched = anyOf.map(_asStringMap).whereType<Map<String, Object?>>().any((sub) {
        final subErrors = <String>[];
        _validateValue(value, sub, path, subErrors);
        return subErrors.isEmpty;
      });
      if (!matched) {
        errors.add('$path must match at least one of the allowed schemas.');
      }
    }

    if (value is String) {
      _validateString(value, schema, path, errors);
    } else if (value is num) {
      _validateNumber(value, schema, path, errors);
    } else if (value is List) {
      _validateArray(value, schema, path, errors);
    } else {
      final object = _asStringMap(value);
      if (object != null) {
        _validateObject(object, schema, path, errors);
      }
    }
  }

  void _validateString(
    String value,
    Map<String, Object?> schema,
    String path,
    List<String> errors,
  ) {
    final minLength = schema['minLength'];
    if (minLength is int && value.length < minLength) {
      errors.add('$path must have at least $minLength character(s).');
    }

    final maxLength = schema['maxLength'];
    if (maxLength is int && value.length > maxLength) {
      errors.add('$path must have at most $maxLength character(s).');
    }

    final pattern = schema['pattern'];
    if (pattern is String && !RegExp(pattern).hasMatch(value)) {
      errors.add('$path must match pattern /$pattern/.');
    }

    final format = schema['format'];
    if (format == 'date-time' && DateTime.tryParse(value) == null) {
      errors.add('$path must be an ISO-8601 date-time string.');
    } else if (format == 'uri') {
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasScheme) {
        errors.add('$path must be an absolute URI.');
      }
    }
  }

  void _validateNumber(
    num value,
    Map<String, Object?> schema,
    String path,
    List<String> errors,
  ) {
    final minimum = schema['minimum'];
    if (minimum is num && value < minimum) {
      errors.add('$path must be greater than or equal to $minimum.');
    }

    final maximum = schema['maximum'];
    if (maximum is num && value > maximum) {
      errors.add('$path must be less than or equal to $maximum.');
    }
  }

  void _validateArray(
    List<Object?> value,
    Map<String, Object?> schema,
    String path,
    List<String> errors,
  ) {
    final minItems = schema['minItems'];
    if (minItems is int && value.length < minItems) {
      errors.add('$path must contain at least $minItems item(s).');
    }

    final maxItems = schema['maxItems'];
    if (maxItems is int && value.length > maxItems) {
      errors.add('$path must contain at most $maxItems item(s).');
    }

    if (schema['uniqueItems'] == true) {
      final seen = <String>{};
      for (final item in value) {
        final key = jsonEncode(item);
        if (!seen.add(key)) {
          errors.add('$path must contain unique items.');
          break;
        }
      }
    }

    final items = _asStringMap(schema['items']);
    if (items != null) {
      for (var i = 0; i < value.length; i++) {
        _validateValue(value[i], items, '$path[$i]', errors);
      }
    }
  }

  void _validateObject(
    Map<String, Object?> value,
    Map<String, Object?> schema,
    String path,
    List<String> errors,
  ) {
    final required = schema['required'];
    if (required is List) {
      for (final field in required.whereType<String>()) {
        if (!value.containsKey(field)) {
          errors.add('$path.$field is required.');
        }
      }
    }

    final properties = _asNestedSchemaMap(schema['properties']);
    if (properties != null) {
      for (final entry in properties.entries) {
        if (value.containsKey(entry.key)) {
          _validateValue(value[entry.key], entry.value, '$path.${entry.key}', errors);
        }
      }
    }

    final additionalProperties = schema['additionalProperties'];
    if (additionalProperties == false && properties != null) {
      final allowed = properties.keys.toSet();
      for (final field in value.keys.where((field) => !allowed.contains(field))) {
        errors.add('$path.$field is not allowed.');
      }
    } else {
      final additionalSchema = _asStringMap(additionalProperties);
      if (additionalSchema != null && properties != null) {
        final known = properties.keys.toSet();
        for (final entry in value.entries.where((entry) => !known.contains(entry.key))) {
          _validateValue(entry.value, additionalSchema, '$path.${entry.key}', errors);
        }
      }
    }
  }

  Map<String, Object?> _resolveRef(String ref) {
    if (!ref.startsWith('#/')) {
      throw UnsupportedError('Only local JSON Schema refs are supported: $ref');
    }

    Object? node = rootSchema;
    for (final segment in ref.substring(2).split('/').map(_decodeJsonPointerSegment)) {
      final map = _asStringMap(node);
      if (map == null || !map.containsKey(segment)) {
        throw FormatException('Unable to resolve JSON Schema ref: $ref');
      }
      node = map[segment];
    }

    final resolved = _asStringMap(node);
    if (resolved == null) {
      throw FormatException('JSON Schema ref does not point to an object: $ref');
    }
    return resolved;
  }
}

String _decodeJsonPointerSegment(String segment) {
  return segment.replaceAll('~1', '/').replaceAll('~0', '~');
}

bool _matchesType(Object? value, Object type) {
  if (type is List) {
    return type.any((candidate) => _matchesType(value, candidate));
  }

  return switch (type) {
    'array' => value is List,
    'boolean' => value is bool,
    'integer' => value is int,
    'null' => value == null,
    'number' => value is num,
    'object' => _asStringMap(value) != null,
    'string' => value is String,
    _ => false,
  };
}

String _typeDescription(Object type) {
  if (type is List) {
    return type.map((value) => value.toString()).join(' or ');
  }
  return type.toString();
}

Future<void> _upsertDocument({
  required HttpClient client,
  required String host,
  required String projectId,
  required _SeedDocument document,
}) async {
  final encodedPath = document.path.split('/').map(Uri.encodeComponent).join('/');
  final uri = Uri.parse(
    'http://$host/v1/projects/${Uri.encodeComponent(projectId)}/databases/(default)/documents/$encodedPath',
  );

  final request = await client.openUrl('PATCH', uri);
  request.headers.contentType = ContentType.json;
  request.headers.set('Authorization', 'Bearer owner');
  request.write(jsonEncode({'fields': _encodeFirestoreFields(document.data)}));

  final response = await request.close();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    final body = await utf8.decodeStream(response);
    throw HttpException(
      'Failed to seed ${document.path}: HTTP ${response.statusCode}\n$body',
      uri: uri,
    );
  }
}

Map<String, Object?> _encodeFirestoreFields(Map<String, Object?> data) {
  return {
    for (final entry in data.entries) entry.key: _encodeFirestoreValue(entry.value),
  };
}

Map<String, Object?> _encodeFirestoreValue(Object? value) {
  if (value == null) {
    return {'nullValue': null};
  }
  if (value is bool) {
    return {'booleanValue': value};
  }
  if (value is int) {
    return {'integerValue': value.toString()};
  }
  if (value is num) {
    return {'doubleValue': value};
  }
  if (value is String) {
    final timestamp = _tryParseTimestamp(value);
    if (timestamp != null) {
      return {'timestampValue': timestamp.toUtc().toIso8601String()};
    }
    return {'stringValue': value};
  }
  if (value is List) {
    final values = value.map(_encodeFirestoreValue).toList();
    return {
      'arrayValue': values.isEmpty ? <String, Object?>{} : {'values': values},
    };
  }

  final map = _asStringMap(value);
  if (map != null) {
    final fields = _encodeFirestoreFields(map);
    return {
      'mapValue': fields.isEmpty ? <String, Object?>{} : {'fields': fields},
    };
  }

  throw ArgumentError('Unsupported Firestore seed value: $value');
}

DateTime? _tryParseTimestamp(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(value)) {
    return null;
  }
  return DateTime.tryParse(value);
}

String _normalizeHost(String host) {
  var value = host.trim();
  value = value.replaceFirst(RegExp(r'^https?://'), '');
  while (value.endsWith('/')) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}

Map<String, Object?>? _asStringMap(Object? value) {
  if (value is! Map) return null;

  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) return null;
    result[key] = entry.value;
  }
  return result;
}

Map<String, Map<String, Object?>>? _asNestedSchemaMap(Object? value) {
  final map = _asStringMap(value);
  if (map == null) return null;

  final result = <String, Map<String, Object?>>{};
  for (final entry in map.entries) {
    final nested = _asStringMap(entry.value);
    if (nested == null) return null;
    result[entry.key] = nested;
  }
  return result;
}
