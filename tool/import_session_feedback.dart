/// Writes attendee feedback page URLs onto existing `sessions` documents.
///
/// Sessionize issues one feedback page per session but does not expose those
/// URLs through its API, so they are collected by hand from the organizer
/// feedback screen into a JSON file and applied with this script. Only
/// `feedbackUrl` (plus `updatedAt`) is written, via an explicit update mask,
/// so Sessionize-owned fields and other dashboard edits are left untouched.
///
/// Input file format — a JSON object keyed by the Sessionize session id
/// (which is also the Firestore document id, see `tool/import_sessions.dart`):
///
/// ```json
/// {
///   "1282478": "https://sessionize.com/app/feedback/...",
///   "1282479": null
/// }
/// ```
///
/// A `null` / empty value clears the URL for that session. Ids that do not
/// exist in Firestore are reported and skipped rather than creating documents.
///
/// Run via:
///
/// ```sh
/// # Local: writes to the Firestore emulator (start + import sessions first).
/// fvm dart run melos sessions:feedback:import
///
/// # Preview without writing anything.
/// fvm dart run tool/import_session_feedback.dart --dry-run
///
/// # STG / prod: point at the real project over HTTPS.
/// FIREBASE_PROJECT_ID=flutterkaigi-2026-stg \
///   FIRESTORE_HOST=firestore.googleapis.com \
///   FIRESTORE_ACCESS_TOKEN=$(gcloud auth print-access-token) \
///   fvm dart run tool/import_session_feedback.dart
/// ```
///
/// Environment (same contract as `tool/import_sessions.dart`):
///   - `SESSION_FEEDBACK_FILE` — input JSON path. Defaults to
///     `tool/session_feedback/feedback_urls.json`.
///   - `FIREBASE_PROJECT_ID` / `FIRESTORE_EMULATOR_HOST` / `FIRESTORE_HOST` /
///     `FIRESTORE_ACCESS_TOKEN` / `FIRESTORE_API_KEY`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:data/session_model.dart';

const _defaultProjectId = 'dev-flutterkaigi-2026';
const _defaultFirestoreHost = 'localhost:8080';
const _defaultInputPath = 'tool/session_feedback/feedback_urls.json';

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final inputPath = Platform.environment['SESSION_FEEDBACK_FILE'] ?? _defaultInputPath;

  final entries = _readFeedbackUrls(inputPath);
  final config = _resolveFirestoreConfig();
  final existing = {
    for (final doc in await fetchFirestoreDocuments('sessions', config))
      if ((doc['id'] ?? '').toString().isNotEmpty) doc['id'].toString(): doc,
  };

  var written = 0;
  var unchanged = 0;
  final missing = <String>[];
  final now = DateTime.now().toUtc();

  for (final entry in entries.entries) {
    final id = entry.key;
    final url = entry.value;
    final doc = existing[id];
    if (doc == null) {
      missing.add(id);
      continue;
    }
    final current = (doc['feedbackUrl'] as String?)?.trim();
    final normalizedCurrent = current == null || current.isEmpty ? null : current;
    if (normalizedCurrent == url) {
      unchanged++;
      continue;
    }

    stdout.writeln('${dryRun ? '[dry-run] ' : ''}sessions/$id: ${current ?? '(none)'} -> ${url ?? '(none)'}');
    if (!dryRun) {
      await upsertFirestoreDocument(
        'sessions/$id',
        {'feedbackUrl': url, 'updatedAt': now},
        config,
        updateMask: const ['feedbackUrl', 'updatedAt'],
      );
    }
    written++;
  }

  stdout.writeln(
    'Done: $written ${dryRun ? 'would be written' : 'written'}, '
    '$unchanged unchanged, ${missing.length} unknown session id(s).',
  );
  if (missing.isNotEmpty) {
    stderr.writeln('Unknown session ids (not in Firestore): ${missing.join(', ')}');
    exitCode = 1;
  }
}

/// Parses the input file into `sessionId -> url`, normalising blanks to `null`
/// and rejecting anything that is not an `https://` URL.
Map<String, String?> _readFeedbackUrls(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Input file not found: $path');
    exit(2);
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    stderr.writeln('$path must contain a JSON object keyed by session id.');
    exit(2);
  }

  final result = <String, String?>{};
  for (final entry in decoded.entries) {
    final raw = entry.value;
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      result[entry.key] = null;
      continue;
    }
    final value = raw.toString().trim();
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      stderr.writeln('Invalid feedback URL for session ${entry.key}: $value');
      exit(2);
    }
    result[entry.key] = value;
  }
  return result;
}

FirestoreRestConfig _resolveFirestoreConfig() {
  final projectId = Platform.environment['FIREBASE_PROJECT_ID'] ?? _defaultProjectId;
  final emulatorHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  final host = _normalizeHost(
    Platform.environment['FIRESTORE_HOST'] ?? emulatorHost ?? _defaultFirestoreHost,
  );
  final isEmulator = emulatorHost != null || host.startsWith('localhost') || host.startsWith('127.0.0.1');

  stdout.writeln(
    'Writing feedback URLs to Firestore '
    '(${isEmulator ? 'http' : 'https'}://$host, project $projectId${isEmulator ? ', emulator' : ''}).',
  );

  return FirestoreRestConfig(
    projectId: projectId,
    host: host,
    isEmulator: isEmulator,
    accessToken: Platform.environment['FIRESTORE_ACCESS_TOKEN'],
    apiKey: Platform.environment['FIRESTORE_API_KEY'],
  );
}

String _normalizeHost(String host) {
  var value = host.trim().replaceFirst(RegExp(r'^https?://'), '');
  while (value.endsWith('/')) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}
