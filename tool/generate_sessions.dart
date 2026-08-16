/// Generates `apps/website/lib/constants/generated_sessions.dart` from the
/// `sessions` / `speakers` / `venues` / `timelineEvents` Firestore collections
/// managed by `packages/data` — the same data the admin dashboard writes and
/// `tool/import_sessions.dart` fills in from Sessionize.
///
/// The fetch (Firestore REST call + document decode) and the domain models
/// (`Session`/`Speaker`/`Venue`/`TimelineEvent`) are reused from
/// `packages/data` via the Flutter-free `package:data/session_model.dart`. It
/// does *not* use `FirestoreSessionRepository` (`package:data/session.dart`),
/// which needs `cloud_firestore`'s platform channels and a running Firebase
/// app — both unavailable, and uncompilable, in a bare `dart run` script.
///
/// Like `tool/generate_sponsors.dart` (and unlike `tool/generate_news.dart`),
/// the output is **git-ignored** and regenerated on every build: the session
/// list is speaker-facing data that must not land in this public repo's git
/// history before the programme is announced.
///
/// Run via:
///
/// ```sh
/// # Local: reads the Firestore emulator (start it + seed first, e.g.
/// #   fvm dart run melos firebase:start  /  fvm dart run melos firebase:seed)
/// fvm dart run melos sessions:generate
///
/// # STG / prod: point at the real project over HTTPS.
/// FIREBASE_PROJECT_ID=flutterkaigi-2026-stg \
///   FIRESTORE_HOST=firestore.googleapis.com \
///   FIRESTORE_ACCESS_TOKEN=$(gcloud auth print-access-token) \
///   fvm dart run tool/generate_sessions.dart
/// ```
///
/// Data source (Firestore REST API, mirroring `tool/firebase_seed.dart`):
///   - `FIREBASE_PROJECT_ID`     — defaults to `dev-flutterkaigi-2026`.
///   - `FIRESTORE_EMULATOR_HOST` — when set (or the host is localhost), talk to
///     the emulator over HTTP with the `owner` bearer token.
///   - `FIRESTORE_HOST`          — explicit host for a real project (HTTPS).
///   - `FIRESTORE_ACCESS_TOKEN`  — OAuth bearer token for a real project.
///   - `FIRESTORE_API_KEY`       — optional `?key=` for a real project.
///   - If Firestore is unreachable: an already-generated output file is left
///     untouched (a transient outage must not blank out a preview build). With
///     no output file at all, an *empty* timetable is written so the site still
///     compiles — there is deliberately no sample fixture to fall back on, as
///     placeholder sessions on the live site would be worse than none.
///
/// Shaping notes:
///   - Times are rendered in JST from the stored UTC instants using a fixed
///     offset, never the machine's local timezone — CI runs in UTC.
///   - Rooms come from `venues` (ordered by `order`, then id) paired with the
///     fixed colour palette below, mirroring the hand-written `timetableRooms`
///     in `apps/website/lib/constants/timetable.dart`.
///   - Days come from the `TimetableDay` enum: a session whose JST date
///     matches no enum entry is dropped with a warning, as there is no tab to
///     show it under. Every enum day is emitted, empty if it has no sessions,
///     so the website's `timetableByDay[day]!` lookup never misses.
///   - Each day becomes a `TimetableProgramme`: every start/end time in it is
///     collected into `ticks` (the grid's row boundaries) and each session /
///     timeline event is emitted as a `TimetableEntry` spanning the boundaries
///     it covers. Sessions therefore keep a shared time axis without having to
///     share a row, so a 10-minute LT no longer stretches the 30-minute talk
///     running next to it.
library;

import 'dart:io';

import 'package:data/session_model.dart';

const _outFile = 'apps/website/lib/constants/generated_sessions.dart';

// Firestore defaults — kept in sync with tool/firebase_seed.dart.
const _defaultProjectId = 'dev-flutterkaigi-2026';
const _defaultFirestoreHost = 'localhost:8080';

/// The event's timezone. Stored instants are UTC; the timetable shows JST.
const _kJst = Duration(hours: 9);

/// `TimetableDay` enum entries, keyed by the `MM.dd` JST date each represents.
/// Kept in sync with `apps/website/lib/constants/timetable.dart` — the
/// generated file references these enum values by name.
const _kDayRefByDate = {'10.29': 'TimetableDay.day1', '10.30': 'TimetableDay.day2'};

/// Room identity colours, in venue order. Identifiers from
/// `apps/website/lib/constants/generated_tokens.dart` — the same four the
/// hand-written `timetableRooms` uses. Cycled if there are more venues.
const _kRoomColorRefs = [
  'colorDeeppurpleSysLightPrimaryHex',
  'colorDeeppurpleSysLightSecondaryHex',
  'colorDeeppurpleSysLightTertiaryHex',
  'colorKeycolorsDeepnavyHex',
];

/// Session chips, keyed by the private const name the generated file declares.
/// Labels match the hand-written samples in `timetable.dart`.
const _kTags = {
  '_tagLt': (ja: 'LT', en: 'LT'),
  '_tagBeginnersLt': (ja: 'ビギナーズ LT', en: 'Beginners LT'),
  '_tagHandsOn': (ja: 'ハンズオン', en: 'Hands-on'),
  '_tagJa': (ja: '日本語', en: 'JA'),
  '_tagEn': (ja: '英語', en: 'EN'),
};

Future<void> main(List<String> args) async {
  final data = await _load();
  if (data == null) {
    stdout.writeln(
      'Keeping existing $_outFile as-is (Firestore unreachable and a '
      'generated copy already exists).',
    );
    return;
  }

  final rooms = _buildRooms(data.venues);
  final days = _buildDays(data, rooms);

  _writeDart(rooms: rooms, days: days);
  _format(_outFile);

  final entryCount = days.values.fold<int>(0, (sum, day) => sum + day.entries.length);
  stdout.writeln(
    'Wrote $_outFile with ${rooms.length} room(s) and $entryCount entr(ies) '
    'across ${days.length} day(s).',
  );
}

// ── Data loading ────────────────────────────────────────────────────────────

/// Everything the timetable needs, already decoded.
typedef _Data = ({
  List<Venue> venues,
  List<Session> sessions,
  Map<String, Speaker> speakersById,
  List<TimelineEvent> events,
});

/// Returns `null` when Firestore is unreachable and [_outFile] already exists —
/// [main] then leaves it untouched rather than regressing a working preview
/// build to an empty timetable.
Future<_Data?> _load() async {
  try {
    final config = _resolveFirestoreConfig();
    final venues = _decodeAll(await fetchFirestoreDocuments('venues', config), Venue.fromJson, 'venue');
    final sessions = _decodeAll(await fetchFirestoreDocuments('sessions', config), Session.fromJson, 'session');
    final speakers = _decodeAll(await fetchFirestoreDocuments('speakers', config), Speaker.fromJson, 'speaker');
    final events = _decodeAll(
      await fetchFirestoreDocuments('timelineEvents', config),
      TimelineEvent.fromJson,
      'timeline event',
    );

    stdout.writeln(
      'Loaded ${sessions.length} session(s), ${speakers.length} speaker(s), '
      '${venues.length} venue(s), ${events.length} timeline event(s) from Firestore.',
    );
    if (sessions.isEmpty && events.isEmpty) {
      // A reachable but empty programme is a valid state before the timetable
      // is fixed — emit an empty timetable rather than fake placeholders.
      stderr.writeln('warning: no sessions or timeline events found in the data source.');
    }
    return (
      venues: venues,
      sessions: sessions,
      speakersById: {for (final s in speakers) s.id: s},
      events: events,
    );
  } catch (e) {
    stderr.writeln('warning: could not load the programme from Firestore ($e).');
    if (File(_outFile).existsSync()) {
      stderr.writeln('Keeping the existing $_outFile as-is.');
      return null;
    }
    stderr.writeln('No existing $_outFile found; writing an empty timetable so the build still compiles.');
    return (
      venues: const <Venue>[],
      sessions: const <Session>[],
      speakersById: const <String, Speaker>{},
      events: const <TimelineEvent>[],
    );
  }
}

/// Decodes every document, skipping malformed ones with a warning — one bad
/// document should not blank out the whole timetable.
List<T> _decodeAll<T>(
  List<Map<String, dynamic>> docs,
  T Function(Map<String, dynamic>) fromJson,
  String label,
) {
  final out = <T>[];
  for (final doc in docs) {
    try {
      out.add(fromJson(doc));
    } catch (e) {
      stderr.writeln("warning: skipping malformed $label document ${doc['id']}: $e");
    }
  }
  return out;
}

FirestoreRestConfig _resolveFirestoreConfig() {
  final projectId = Platform.environment['FIREBASE_PROJECT_ID'] ?? _defaultProjectId;
  final emulatorHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  final host = _normalizeHost(
    Platform.environment['FIRESTORE_HOST'] ?? emulatorHost ?? _defaultFirestoreHost,
  );
  final isEmulator = emulatorHost != null || host.startsWith('localhost') || host.startsWith('127.0.0.1');

  stdout.writeln(
    'Fetching the programme from Firestore '
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

// ── Shaping ─────────────────────────────────────────────────────────────────

/// Bilingual text, matching the website's `LocalizedText` fields.
typedef _Text = ({String ja, String en});

/// One column of the timetable grid.
typedef _Room = ({String venueId, _Text name, String colorRef});

/// One session cell.
typedef _Cell = ({
  _Text title,
  _Text? speakerName,
  String? avatarUrl,
  _Text? description,
  List<String> tagRefs,
});

/// One placed item of the timetable grid: a session in a room column
/// ([column] / [cell]), a full-width timeline event ([eventLabel] only), or a
/// room-bound timeline event ([eventLabel] + [column] — e.g. the lunch stage).
class _Entry {
  _Entry.session(this.start, this.end, int this.column, _Cell this.cell) : eventLabel = null;

  _Entry.event(this.start, this.end, this.eventLabel, {this.column}) : cell = null;

  final DateTime start;
  final DateTime end;
  final int? column;
  final _Cell? cell;
  final _Text? eventLabel;
}

/// Venues as timetable columns, ordered by `order` (unset last) then id so the
/// column layout stays stable across regenerations.
List<_Room> _buildRooms(List<Venue> venues) {
  const unordered = 1 << 30;
  final sorted = [...venues]
    ..sort((a, b) {
      final byOrder = (a.order ?? unordered).compareTo(b.order ?? unordered);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
  return [
    for (final (i, v) in sorted.indexed)
      (
        venueId: v.id,
        name: _text(v.name),
        colorRef: _kRoomColorRefs[i % _kRoomColorRefs.length],
      ),
  ];
}

/// One day of the timetable: the grid's row boundaries and everything placed
/// on it.
typedef _Day = ({List<DateTime> ticks, List<_Entry> entries});

/// Groups sessions and timeline events per day, keyed by the `TimetableDay`
/// enum reference the generated file emits.
Map<String, _Day> _buildDays(_Data data, List<_Room> rooms) {
  final roomIndex = {for (final (i, r) in rooms.indexed) r.venueId: i};
  // Every enum day is present, even when empty — the website indexes this map
  // with `!` and would throw on a missing key.
  final byDay = {for (final ref in _kDayRefByDate.values) ref: <_Entry>[]};

  for (final s in [...data.sessions]..sort((a, b) => a.id.compareTo(b.id))) {
    // A session without a description means its content is not decided yet
    // (未定 is the placeholder organizers put in undecided sponsor slots).
    // The importer refuses those too; this also covers documents that were
    // written before that rule or by hand.
    final description = _text(s.description);
    final isUndecided = ['', '未定'].contains(description.ja) && ['', '未定'].contains(description.en);
    if (isUndecided) {
      stderr.writeln(
        'warning: session ${s.id} has no description (content not decided yet); skipping.',
      );
      continue;
    }
    final dayRef = _dayRefFor(s.startsAt);
    if (dayRef == null) {
      stderr.writeln(
        'warning: session ${s.id} starts on ${_mmdd(s.startsAt)} JST, which is '
        'not a TimetableDay; skipping.',
      );
      continue;
    }
    final column = roomIndex[s.venueId];
    if (column == null) {
      stderr.writeln("warning: session ${s.id} refers to unknown venue '${s.venueId}'; skipping.");
      continue;
    }

    // Two sessions overlapping in one room would be placed on top of each
    // other in the same grid cell.
    final clash = byDay[dayRef]!.any(
      (e) => e.column == column && e.start.isBefore(s.endsAt) && s.startsAt.isBefore(e.end),
    );
    if (clash) {
      stderr.writeln(
        'warning: session ${s.id} overlaps another session in venue '
        "'${s.venueId}' at ${_hhmm(s.startsAt)}; keeping the first and skipping this one.",
      );
      continue;
    }
    byDay[dayRef]!.add(_Entry.session(s.startsAt, s.endsAt, column, _buildCell(s, data.speakersById)));
  }

  for (final e in [...data.events]..sort((a, b) => a.id.compareTo(b.id))) {
    final dayRef = _dayRefFor(e.startsAt);
    if (dayRef == null) {
      stderr.writeln(
        'warning: timeline event ${e.id} starts on ${_mmdd(e.startsAt)} JST, '
        'which is not a TimetableDay; skipping.',
      );
      continue;
    }
    if (e.endsAt == null) {
      // A zero-length event still needs a row to sit on; without an end there
      // is nothing better to show than the start time again.
      stderr.writeln('warning: timeline event ${e.id} has no endsAt; showing its start time as the end.');
    }
    final end = e.endsAt ?? e.startsAt;

    // A venue-bound event (the lunch stage, a satellite opening, …) sits in
    // that venue's column like a session; without a venue it spans the grid.
    int? column;
    if (e.venueId case final venueId?) {
      column = roomIndex[venueId];
      if (column == null) {
        stderr.writeln(
          "warning: timeline event ${e.id} refers to unknown venue '$venueId'; showing it full-width.",
        );
      }
    }
    if (column != null) {
      final clash = byDay[dayRef]!.any(
        (x) => x.column == column && x.start.isBefore(end) && e.startsAt.isBefore(x.end),
      );
      if (clash) {
        stderr.writeln(
          'warning: timeline event ${e.id} overlaps another entry in venue '
          "'${e.venueId}' at ${_hhmm(e.startsAt)}; keeping the first and skipping this one.",
        );
        continue;
      }
    }
    byDay[dayRef]!.add(_Entry.event(e.startsAt, end, _text(e.title), column: column));
  }

  return byDay.map((dayRef, entries) {
    entries.sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      // Stacked vertically (mobile) a full-width event reads as the heading of
      // what follows, so it comes before the entries starting with it.
      // Venue-bound events order by column like sessions.
      int kind(_Entry e) => e.eventLabel != null && e.column == null ? 0 : 1;
      final byKind = kind(a).compareTo(kind(b));
      if (byKind != 0) return byKind;
      return (a.column ?? 0).compareTo(b.column ?? 0);
    });
    // Every start and end is a row boundary: an entry spans from its own start
    // tick to its own end tick, so entries never have to share a row.
    final ticks = <DateTime>{
      for (final e in entries) ...[e.start, e.end],
    }.toList()..sort();
    return MapEntry(dayRef, (ticks: ticks, entries: entries));
  });
}

_Cell _buildCell(Session s, Map<String, Speaker> speakersById) {
  final speakers = [for (final id in s.speakerIds) ?speakersById[id]];
  for (final id in s.speakerIds) {
    if (!speakersById.containsKey(id)) {
      stderr.writeln("warning: session ${s.id} refers to unknown speaker '$id'; omitting them.");
    }
  }

  final names = [
    for (final speaker in speakers)
      if (speaker.name.trim().isNotEmpty) speaker.name.trim(),
  ];
  final avatar = speakers
      .map((speaker) => speaker.avatarUrl?.trim() ?? '')
      .firstWhere((url) => url.isNotEmpty, orElse: () => '');

  final description = _text(s.description);
  return (
    title: _text(s.title),
    // Missing on LT compilations, which have no single owner.
    speakerName: names.isEmpty ? null : (ja: names.join('、'), en: names.join(', ')),
    avatarUrl: avatar.isEmpty ? null : avatar,
    description: description.ja.isEmpty && description.en.isEmpty ? null : description,
    tagRefs: [
      if (s.isBeginnersLightningTalk) '_tagBeginnersLt' else if (s.isLightningTalk) '_tagLt',
      if (s.isHandsOn) '_tagHandsOn',
      if (s.primaryLocale == 'en') '_tagEn' else '_tagJa',
    ],
  );
}

/// Falls each locale back to the other so a single-language entry still renders
/// on both site locales (`LocaleMap` itself does not — both fields are just
/// required strings).
_Text _text(LocaleMap value) => (
  ja: _firstNonEmpty([value.ja, value.en]),
  en: _firstNonEmpty([value.en, value.ja]),
);

String _firstNonEmpty(List<String?> candidates) =>
    candidates.firstWhere((c) => c != null && c.trim().isNotEmpty, orElse: () => '')!.trim();

String? _dayRefFor(DateTime instant) => _kDayRefByDate[_mmdd(instant)];

DateTime _jst(DateTime instant) => instant.toUtc().add(_kJst);

String _mmdd(DateTime instant) {
  final j = _jst(instant);
  return '${_two(j.month)}.${_two(j.day)}';
}

String _hhmm(DateTime instant) {
  final j = _jst(instant);
  return '${_two(j.hour)}:${_two(j.minute)}';
}

String _two(int n) => n.toString().padLeft(2, '0');

// ── Dart emission ───────────────────────────────────────────────────────────

void _writeDart({required List<_Room> rooms, required Map<String, _Day> days}) {
  final usedTags = <String>{
    for (final day in days.values)
      for (final entry in day.entries)
        if (entry.cell case final cell?) ...cell.tagRefs,
  };

  final out = StringBuffer()
    ..writeln('// GENERATED FILE — do not edit by hand.')
    ..writeln('// Source of truth: the `sessions` / `speakers` / `venues` / `timelineEvents`')
    ..writeln('// Firestore collections (packages/data), imported from Sessionize by')
    ..writeln('// tool/import_sessions.dart.')
    ..writeln('// Regenerate via: fvm dart run melos sessions:generate')
    // Imports go unused when the programme is still empty; the file must stay
    // analysis-clean either way.
    ..writeln('// ignore_for_file: lines_longer_than_80_chars, directives_ordering, unused_import')
    ..writeln()
    ..writeln("import 'generated_tokens.dart';")
    ..writeln("import 'sponsors.dart' show LocalizedText;")
    ..writeln("import 'timetable.dart';")
    ..writeln();

  for (final ref in _kTags.keys.where(usedTags.contains)) {
    out.writeln('const $ref = ${_localizedText(_kTags[ref]!)};');
  }
  if (usedTags.isNotEmpty) out.writeln();

  out.writeln('const List<TimetableRoom> generatedTimetableRooms = [');
  for (final room in rooms) {
    out.writeln('  TimetableRoom(name: ${_localizedText(room.name)}, colorHex: ${room.colorRef}),');
  }
  out
    ..writeln('];')
    ..writeln()
    ..writeln('const Map<TimetableDay, TimetableProgramme> generatedTimetableByDay = {');

  for (final MapEntry(key: dayRef, value: day) in days.entries) {
    final tickIndex = {for (final (i, t) in day.ticks.indexed) t: i};
    out
      ..writeln('  $dayRef: TimetableProgramme(')
      ..writeln('    ticks: [${day.ticks.map((t) => _str(_hhmm(t))).join(', ')}],')
      ..writeln('    entries: [');
    for (final entry in day.entries) {
      final startTick = tickIndex[entry.start]!;
      final endTick = tickIndex[entry.end]!;
      if (entry.eventLabel case final label?) {
        out
          ..writeln('      TimetableEntry.event(')
          ..writeln('        startTick: $startTick,')
          ..writeln('        endTick: $endTick,');
        if (entry.column case final column?) {
          out.writeln('        roomIndex: $column,');
        }
        out
          ..writeln('        eventLabel: ${_localizedText(label)},')
          ..writeln('      ),');
        continue;
      }
      final cell = entry.cell!;
      out
        ..writeln('      TimetableEntry.session(')
        ..writeln('        startTick: $startTick,')
        ..writeln('        endTick: $endTick,')
        ..writeln('        roomIndex: ${entry.column},')
        ..writeln('        session: TimetableSession(')
        ..writeln('          title: ${_localizedText(cell.title)},');
      if (cell.speakerName case final name?) {
        out.writeln('          speakerName: ${_localizedText(name)},');
      }
      if (cell.avatarUrl case final url?) {
        out.writeln('          speakerAvatarUrl: ${_str(url)},');
      }
      if (cell.description case final description?) {
        out.writeln('          description: ${_localizedText(description)},');
      }
      if (cell.tagRefs.isNotEmpty) {
        out.writeln('          tags: [${cell.tagRefs.join(', ')}],');
      }
      out
        ..writeln('        ),')
        ..writeln('      ),');
    }
    out
      ..writeln('    ],')
      ..writeln('  ),');
  }

  out.writeln('};');
  File(_outFile).writeAsStringSync(out.toString());
}

String _localizedText(_Text value) => 'LocalizedText(ja: ${_str(value.ja)}, en: ${_str(value.en)})';

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

/// Single-quoted Dart string literal with the necessary escapes. Non-ASCII is
/// emitted verbatim (Dart source is UTF-8).
String _str(String s) {
  final b = StringBuffer("'");
  for (final r in s.runes) {
    switch (r) {
      case 0x5c: // backslash
        b.write(r'\\');
      case 0x27: // single quote
        b.write(r"\'");
      case 0x24: // dollar
        b.write(r'\$');
      case 0x0a:
        b.write(r'\n');
      case 0x0d:
        b.write(r'\r');
      case 0x09:
        b.write(r'\t');
      default:
        b.writeCharCode(r);
    }
  }
  b.write("'");
  return b.toString();
}
