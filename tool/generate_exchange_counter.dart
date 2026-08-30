/// Generates `apps/website/lib/constants/generated_exchange_counter.dart`
/// from the `counters/profileExchanges` Firestore document (incremented by
/// the `onProfileExchangeCreated` Cloud Function — see
/// `functions/src/exchange/triggers.ts` and issue-594.md section 8), or `0`
/// as a fallback.
///
/// Reuses the Flutter-free Firestore REST fetch (`fetchFirestoreDocuments`)
/// from `package:data/counter_model.dart`, the same helper
/// `tool/generate_news.dart` and friends use — this script does not maintain
/// its own HTTP/decoding logic. It fetches the whole `counters` collection
/// (currently a single document) rather than a single-document GET, since
/// `fetchFirestoreDocuments` (mirroring `tool/firebase_seed.dart`'s
/// conventions) only exposes collection listing.
///
/// This is a *build-time* snapshot: the number on the deployed site is
/// whatever it was when this last ran (`website:build` / `website:serve`,
/// and CI before every deploy — see `tool/generate_news.dart`'s doc comment
/// for the equivalent CI behaviour), not a live count. Good enough for a
/// low-stakes "N people have exchanged profiles so far" stat; a live count
/// would need a client-side Firestore read instead (out of scope here — see
/// issue-594.md section 8, "website 側とミッション・クイズ側の実装はまだ無い").
///
/// Run via:
///
/// ```sh
/// # Local: reads the Firestore emulator (start it + seed first, e.g.
/// #   fvm dart run melos firebase:start  /  fvm dart run melos firebase:seed)
/// fvm dart run melos exchange-counter:generate
///
/// # STG / prod: point at the real project over HTTPS.
/// FIREBASE_PROJECT_ID=flutterkaigi-2026-stg \
///   FIRESTORE_HOST=firestore.googleapis.com \
///   FIRESTORE_ACCESS_TOKEN=$(gcloud auth print-access-token) \
///   fvm dart run tool/generate_exchange_counter.dart
/// ```
///
/// Data source (Firestore REST API, mirroring `tool/firebase_seed.dart`):
///   - `FIREBASE_PROJECT_ID`     — defaults to `dev-flutterkaigi-2026`.
///   - `FIRESTORE_EMULATOR_HOST` — when set (or the host is localhost), talk to
///     the emulator over HTTP with the `owner` bearer token.
///   - `FIRESTORE_HOST`          — explicit host for a real project (HTTPS).
///   - `FIRESTORE_ACCESS_TOKEN`  — OAuth bearer token for a real project.
///   - `FIRESTORE_API_KEY`       — optional `?key=` for a real project.
///   - If Firestore is unreachable: when a committed
///     `generated_exchange_counter.dart` already exists, it is left
///     untouched (an outage must not regress the live site's displayed count
///     down to 0). Only when no output file exists yet does it fall back to
///     `0` so the build still compiles.
///   - If Firestore is reachable but the `counters` collection is empty, or
///     has no `profileExchanges` document yet (nobody has exchanged profiles
///     — or, before PR1 ships, the collection doesn't exist at all), the
///     count is `0`. This is the "counter not present yet" fallback the
///     website display also handles (see `generated_exchange_counter.dart`'s
///     doc comment and `components/exchange_counter_section.dart`).
library;

import 'dart:io';

import 'package:data/counter_model.dart';

const _outFile = 'apps/website/lib/constants/generated_exchange_counter.dart';
const _counterDocId = 'profileExchanges';

// Firestore defaults — kept in sync with tool/firebase_seed.dart.
const _defaultProjectId = 'dev-flutterkaigi-2026';
const _defaultFirestoreHost = 'localhost:8080';

Future<void> main(List<String> args) async {
  final count = await _loadCount();
  if (count == null) {
    stdout.writeln(
      'Keeping existing $_outFile as-is (Firestore unreachable and a '
      'committed copy already exists).',
    );
    return;
  }

  _writeDart(count);
  _format(_outFile);

  stdout.writeln('Wrote $_outFile with count=$count.');
}

// ── Data loading ──────────────────────────────────────────────────────────

/// Returns `null` when Firestore is unreachable and `$_outFile` is already
/// committed — [main] then leaves it untouched instead of regressing a
/// possibly larger, previously-fetched count back down to 0.
Future<int?> _loadCount() async {
  try {
    final config = _resolveFirestoreConfig();
    final docs = await fetchFirestoreDocuments('counters', config);
    final doc = docs.where((d) => d['id'] == _counterDocId).firstOrNull;
    final count = (doc?['count'] as int?) ?? 0;
    stdout.writeln(
      doc == null ? "No '$_counterDocId' document in 'counters' yet; using 0." : 'Loaded count=$count from Firestore.',
    );
    return count;
  } catch (e) {
    stderr.writeln('warning: could not load the exchange counter from Firestore ($e).');
    if (File(_outFile).existsSync()) {
      stderr.writeln('Keeping the existing committed $_outFile as-is.');
      return null;
    }
    stderr.writeln('No existing $_outFile found; falling back to 0.');
    return 0;
  }
}

/// Resolves the [FirestoreRestConfig] from the `FIRESTORE_*` /
/// `FIREBASE_PROJECT_ID` env vars (see the library doc); defaults to the
/// local emulator.
FirestoreRestConfig _resolveFirestoreConfig() {
  final projectId = Platform.environment['FIREBASE_PROJECT_ID'] ?? _defaultProjectId;
  final emulatorHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  final host = _normalizeHost(
    Platform.environment['FIRESTORE_HOST'] ?? emulatorHost ?? _defaultFirestoreHost,
  );
  final isEmulator = emulatorHost != null || host.startsWith('localhost') || host.startsWith('127.0.0.1');

  stdout.writeln(
    'Fetching the profile-exchange counter from Firestore '
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

// ── Dart emission ───────────────────────────────────────────────────────────

void _writeDart(int count) {
  final out =
      '''
// GENERATED FILE — do not edit by hand.
// Source of truth: the `counters/$_counterDocId` Firestore document
// (incremented by functions/src/exchange/triggers.ts), or 0 when absent /
// unreachable with no prior committed copy.
// Regenerate via: fvm dart run melos exchange-counter:generate

/// Number of completed profile exchanges as of the last website build/deploy
/// — a build-time snapshot, not a live count (see this file's generator,
/// tool/generate_exchange_counter.dart, for why).
const int generatedProfileExchangeCount = $count;
''';
  File(_outFile).writeAsStringSync(out);
}

void _format(String path) {
  // Format with whatever is available; never fail the build over formatting.
  // Try `dart` first (present in CI), then `fvm dart` (local fvm setups).
  // `Process.runSync` throws (not just non-zero) when the executable is
  // missing, so each candidate is guarded.
  const candidates = [
    ['dart', 'format'],
    ['fvm', 'dart', 'format'],
  ];
  for (final cmd in candidates) {
    try {
      final r = Process.runSync(cmd.first, [...cmd.skip(1), path]);
      if (r.exitCode == 0) return;
    } on ProcessException {
      // Executable not found — try the next candidate.
    }
  }
  stderr.writeln('warning: could not run `dart format` on $path; left unformatted.');
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
