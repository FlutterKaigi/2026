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
///   - `timelineEvents` become full-width `TimetableSlot.event` rows; sessions
///     sharing a start/end become one `TimetableSlot.sessions` row.
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

  final slotCount = days.values.fold<int>(0, (sum, slots) => sum + slots.length);
  stdout.writeln(
    'Wrote $_outFile with ${rooms.length} room(s) and $slotCount slot(s) '
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
typedef _Room = ({String venueId, String name, String colorRef});

/// One session cell.
typedef _Cell = ({
  _Text title,
  _Text? speakerName,
  String? avatarUrl,
  _Text? description,
  List<String> tagRefs,
});

/// One row of the timetable grid: either parallel sessions ([byRoom], aligned
/// to the room columns) or a full-width timeline event ([eventLabel]).
class _Slot {
  _Slot.sessions(this.start, this.end, int roomCount)
    : byRoom = List<_Cell?>.filled(roomCount, null),
      eventLabel = null;

  _Slot.event(this.start, this.end, this.eventLabel) : byRoom = const [];

  final DateTime start;
  final DateTime end;
  final List<_Cell?> byRoom;
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
        // `TimetableRoom.name` is a plain String, not LocalizedText, so the
        // column header cannot switch language. English is preferred as the
        // shorter, locale-neutral label ("Hall A" over "ホール A").
        name: _firstNonEmpty([v.name.en, v.name.ja]),
        colorRef: _kRoomColorRefs[i % _kRoomColorRefs.length],
      ),
  ];
}

/// Groups sessions and timeline events into per-day, time-ordered rows, keyed
/// by the `TimetableDay` enum reference the generated file emits.
Map<String, List<_Slot>> _buildDays(_Data data, List<_Room> rooms) {
  final roomIndex = {for (final (i, r) in rooms.indexed) r.venueId: i};
  // Every enum day is present, even when empty — the website indexes this map
  // with `!` and would throw on a missing key.
  final byDay = {for (final ref in _kDayRefByDate.values) ref: <_Slot>[]};
  // Sessions sharing a start/end share a row; events always get their own.
  final sessionSlots = <String, _Slot>{};

  for (final s in [...data.sessions]..sort((a, b) => a.id.compareTo(b.id))) {
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

    final key = '$dayRef|${s.startsAt.toUtc().toIso8601String()}|${s.endsAt.toUtc().toIso8601String()}';
    final slot = sessionSlots.putIfAbsent(key, () {
      final created = _Slot.sessions(s.startsAt, s.endsAt, rooms.length);
      byDay[dayRef]!.add(created);
      return created;
    });
    if (slot.byRoom[column] != null) {
      stderr.writeln(
        'warning: session ${s.id} collides with another session in venue '
        "'${s.venueId}' at ${_hhmm(s.startsAt)}; keeping the first and skipping this one.",
      );
      continue;
    }
    slot.byRoom[column] = _buildCell(s, data.speakersById);
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
      // The row renders "start – end"; without an end there is nothing better
      // to show than the start time again.
      stderr.writeln('warning: timeline event ${e.id} has no endsAt; showing its start time as the end.');
    }
    byDay[dayRef]!.add(_Slot.event(e.startsAt, e.endsAt ?? e.startsAt, _text(e.title)));
  }

  for (final slots in byDay.values) {
    slots.sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      // A break ending where a session starts belongs above it.
      final byEnd = a.end.compareTo(b.end);
      if (byEnd != 0) return byEnd;
      return (a.eventLabel != null ? 0 : 1).compareTo(b.eventLabel != null ? 0 : 1);
    });
  }
  return byDay;
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

void _writeDart({required List<_Room> rooms, required Map<String, List<_Slot>> days}) {
  final usedTags = <String>{
    for (final slots in days.values)
      for (final slot in slots)
        for (final cell in slot.byRoom)
          if (cell != null) ...cell.tagRefs,
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
    out.writeln('  TimetableRoom(name: ${_str(room.name)}, colorHex: ${room.colorRef}),');
  }
  out
    ..writeln('];')
    ..writeln()
    ..writeln('const Map<TimetableDay, List<TimetableSlot>> generatedTimetableByDay = {');

  for (final MapEntry(key: dayRef, value: slots) in days.entries) {
    out.writeln('  $dayRef: [');
    for (final slot in slots) {
      final start = _str(_hhmm(slot.start));
      final end = _str(_hhmm(slot.end));
      if (slot.eventLabel case final label?) {
        out.writeln('    TimetableSlot.event($start, $end, ${_localizedText(label)}),');
        continue;
      }
      out.writeln('    TimetableSlot.sessions($start, $end, [');
      for (final cell in slot.byRoom) {
        if (cell == null) {
          out.writeln('      null,');
          continue;
        }
        out
          ..writeln('      TimetableSession(')
          ..writeln('        title: ${_localizedText(cell.title)},');
        if (cell.speakerName case final name?) {
          out.writeln('        speakerName: ${_localizedText(name)},');
        }
        if (cell.avatarUrl case final url?) {
          out.writeln('        speakerAvatarUrl: ${_str(url)},');
        }
        if (cell.description case final description?) {
          out.writeln('        description: ${_localizedText(description)},');
        }
        if (cell.tagRefs.isNotEmpty) {
          out.writeln('        tags: [${cell.tagRefs.join(', ')}],');
        }
        out.writeln('      ),');
      }
      out.writeln('    ]),');
    }
    out.writeln('  ],');
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
