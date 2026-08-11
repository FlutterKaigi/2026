/// Imports accepted sessions and their speakers from the Sessionize API into
/// the `sessions` / `speakers` / `timelineEvents` Firestore collections that
/// `packages/data` (and therefore the admin dashboard, the Flutter app and the
/// website) read from.
///
/// This is the *upstream* half of the session pipeline:
///
/// ```
/// Sessionize API ──(this script)──▶ Firestore ──(generate_sessions.dart)──▶ website
/// ```
///
/// Design notes:
///
///   - **Document ids are Sessionize ids.** A session lands at
///     `sessions/<sessionize session id>` and a speaker at
///     `speakers/<sessionize speaker uuid>`, so re-running the import updates
///     the same documents instead of creating duplicates. No extra
///     `sessionizeId` field is needed.
///
///   - **Only fully scheduled sessions are imported.** Sessionize leaves
///     `startsAt` / `endsAt` / `roomId` null until the schedule is built, and
///     `Session` requires all three. Sessions without a slot are skipped (and
///     counted in the summary) rather than written with placeholder values.
///
///   - **Dashboard edits are preserved.** Writes use an explicit update mask,
///     so fields this script does not own (`isHandsOn`, `sessionizeUrl`) are
///     never touched. Translated `title` / `description` are only overwritten
///     when the Sessionize-side original actually changed, and even then only
///     the original-language half is rewritten — the translation is left for
///     the translation pass / dashboard to refresh.
///
///   - **Plenary sessions become timeline events.** Sessionize marks breaks,
///     lunch and the like as *service* sessions, but so are the sponsor slots
///     and other room-bound programme items — the two are indistinguishable in
///     the API. What does separate them is `isPlenumSession`: only the
///     event-wide slots carry it. Those become the `timelineEvents` collection
///     (matching how `apps/app` merges the two into one timetable); every other
///     service session is imported as a normal session so it keeps its room,
///     description and speakers.
///
/// Run via:
///
/// ```sh
/// # Local: writes to the Firestore emulator (start it first, e.g.
/// #   fvm dart run melos firebase:start).
/// SESSIONIZE_ENDPOINT_ID=xxxxxxxx fvm dart run melos sessions:import
///
/// # Preview without writing anything.
/// SESSIONIZE_ENDPOINT_ID=xxxxxxxx fvm dart run tool/import_sessions.dart --dry-run
///
/// # STG / prod: point at the real project over HTTPS.
/// SESSIONIZE_ENDPOINT_ID=xxxxxxxx \
///   FIREBASE_PROJECT_ID=flutterkaigi-2026-stg \
///   FIRESTORE_HOST=firestore.googleapis.com \
///   FIRESTORE_ACCESS_TOKEN=$(gcloud auth print-access-token) \
///   fvm dart run tool/import_sessions.dart
/// ```
///
/// Environment:
///   - `SESSIONIZE_ENDPOINT_ID` — **required**. The API endpoint id from the
///     Sessionize "API / Embed" page. Treat it as a secret: the endpoint needs
///     no authentication, so anyone holding the id can read whatever it
///     exposes. Point it at an endpoint limited to *Accepted and informed*
///     sessions; this script refuses anything else (see [_kAcceptedStatus]).
///   - `FIREBASE_PROJECT_ID` / `FIRESTORE_EMULATOR_HOST` / `FIRESTORE_HOST` /
///     `FIRESTORE_ACCESS_TOKEN` / `FIRESTORE_API_KEY` — same contract as
///     `tool/generate_news.dart` and `tool/firebase_seed.dart`.
///   - `SESSIONIZE_API_BASE` — overrides the Sessionize API base URL. Only
///     needed to run the import against a local fixture; defaults to the real
///     API.
library;

import 'dart:convert';
import 'dart:io';

import 'package:data/session_model.dart';
import 'package:http/http.dart' as http;

// Firestore defaults — kept in sync with tool/firebase_seed.dart.
const _defaultProjectId = 'dev-flutterkaigi-2026';
const _defaultFirestoreHost = 'localhost:8080';

const _defaultSessionizeApiBase = 'https://sessionize.com/api/v2';

/// The event's timezone (JST), applied to Sessionize timestamps that carry no
/// explicit UTC offset. See [_parseSessionizeDateTime].
const _kEventUtcOffset = '+09:00';

/// Sessionize's status for a session that made it into the programme. Anything
/// else (`Nominated`, `Declined`) means the endpoint is not restricted to
/// accepted sessions and must not reach Firestore.
const _kAcceptedStatus = 'Accepted';

/// Sessionize category group titles, as configured on the CfS form.
const _kCategorySessionFormat = 'Session format';
const _kCategoryLanguage = 'Language';

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');

  final endpointId = Platform.environment['SESSIONIZE_ENDPOINT_ID']?.trim();
  if (endpointId == null || endpointId.isEmpty) {
    stderr.writeln(
      'error: SESSIONIZE_ENDPOINT_ID is required (the endpoint id from the '
      "Sessionize 'API / Embed' page).",
    );
    exitCode = 64; // EX_USAGE
    return;
  }

  final payload = await _fetchSessionize(endpointId);
  final categories = _CategoryCatalog.fromPayload(payload);

  final config = _resolveFirestoreConfig();
  final venues = await fetchFirestoreDocuments('venues', config);
  final existingSessions = _byId(await fetchFirestoreDocuments('sessions', config));
  final existingSpeakers = _byId(await fetchFirestoreDocuments('speakers', config));
  final existingEvents = _byId(await fetchFirestoreDocuments('timelineEvents', config));

  final venueIdByRoomId = _resolveVenueMapping(payload.rooms, venues);

  final plan = _buildPlan(
    payload: payload,
    categories: categories,
    venueIdByRoomId: venueIdByRoomId,
    existingSessions: existingSessions,
    existingSpeakers: existingSpeakers,
    existingEvents: existingEvents,
  );

  plan.report();

  if (dryRun) {
    stdout.writeln('\nDry run — nothing was written.');
    return;
  }
  if (plan.writes.isEmpty) {
    stdout.writeln('\nNothing to write; Firestore is already up to date.');
    return;
  }

  // Speakers first: sessions reference them via `speakerIds`.
  for (final write in plan.writes) {
    await upsertFirestoreDocument(
      write.path,
      write.data,
      config,
      updateMask: write.updateMask,
    );
  }
  stdout.writeln('\nWrote ${plan.writes.length} document(s) to Firestore.');
}

// ── Sessionize ──────────────────────────────────────────────────────────────

/// The subset of the Sessionize `view/All` response this script consumes.
class _SessionizePayload {
  _SessionizePayload({
    required this.sessions,
    required this.speakers,
    required this.categories,
    required this.rooms,
  });

  factory _SessionizePayload.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String key) =>
        ((json[key] as List?) ?? const []).whereType<Map<String, dynamic>>().toList();

    return _SessionizePayload(
      sessions: list('sessions'),
      speakers: list('speakers'),
      categories: list('categories'),
      rooms: list('rooms'),
    );
  }

  final List<Map<String, dynamic>> sessions;
  final List<Map<String, dynamic>> speakers;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> rooms;
}

Future<_SessionizePayload> _fetchSessionize(String endpointId) async {
  // `SESSIONIZE_API_BASE` exists so the import can be exercised against a
  // local fixture server: Sessionize holds no scheduled sessions until the
  // programme is built, which would otherwise leave this path untestable.
  final base = Platform.environment['SESSIONIZE_API_BASE']?.trim();
  final uri = Uri.parse(
    '${base == null || base.isEmpty ? _defaultSessionizeApiBase : base}/$endpointId/view/All',
  );
  stdout.writeln('Fetching Sessionize endpoint $endpointId.');

  final resp = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 30));
  if (resp.statusCode != 200) {
    throw HttpException('Sessionize returned ${resp.statusCode}: ${resp.body}', uri: uri);
  }

  final payload = _SessionizePayload.fromJson(
    jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>,
  );
  stdout.writeln(
    'Sessionize returned ${payload.sessions.length} session(s), '
    '${payload.speakers.length} speaker(s), ${payload.rooms.length} room(s).',
  );
  if (payload.categories.isEmpty) {
    stderr.writeln(
      "warning: the endpoint returned no categories — enable 'Session format' "
      "/ 'Language' / 'Category' under Submission fields on the Sessionize "
      'API / Embed page, otherwise session format and locale cannot be '
      'derived.',
    );
  }
  return payload;
}

/// Resolves Sessionize `categoryItems` ids to their group + item names.
class _CategoryCatalog {
  const _CategoryCatalog(this._groupByItemId, this._nameByItemId);

  factory _CategoryCatalog.fromPayload(_SessionizePayload payload) {
    final groupByItemId = <int, String>{};
    final nameByItemId = <int, String>{};
    for (final group in payload.categories) {
      final title = (group['title'] ?? '').toString();
      for (final item in ((group['items'] as List?) ?? const []).whereType<Map<String, dynamic>>()) {
        final id = _asInt(item['id']);
        if (id == null) continue;
        groupByItemId[id] = title;
        nameByItemId[id] = (item['name'] ?? '').toString();
      }
    }
    return _CategoryCatalog(groupByItemId, nameByItemId);
  }

  final Map<int, String> _groupByItemId;
  final Map<int, String> _nameByItemId;

  /// The selected item name within [groupTitle] for [session], if any.
  String? itemFor(Map<String, dynamic> session, String groupTitle) {
    for (final raw in ((session['categoryItems'] as List?) ?? const [])) {
      final id = _asInt(raw);
      if (id != null && _groupByItemId[id] == groupTitle) {
        return _nameByItemId[id];
      }
    }
    return null;
  }
}

// ── Mapping ─────────────────────────────────────────────────────────────────

/// Maps Sessionize room ids onto Firestore `venues` document ids by comparing
/// the room name against each venue's `name.ja` / `name.en`.
///
/// Sessionize has no notion of our venue ids, and rooms only exist once the
/// schedule is built — so this is name-based by necessity. Keeping the venue
/// names in Firestore identical to the Sessionize room names is what makes the
/// import work; anything unmatched is reported rather than silently dropped.
Map<int, String> _resolveVenueMapping(
  List<Map<String, dynamic>> rooms,
  List<Map<String, dynamic>> venues,
) {
  final venueIdByName = <String, String>{};
  for (final venue in venues) {
    final id = (venue['id'] ?? '').toString();
    final name = venue['name'];
    if (id.isEmpty || name is! Map) continue;
    for (final value in name.values) {
      final key = _normalizeName(value?.toString() ?? '');
      if (key.isNotEmpty) venueIdByName[key] = id;
    }
  }

  final mapping = <int, String>{};
  for (final room in rooms) {
    final roomId = _asInt(room['id']);
    final roomName = (room['name'] ?? '').toString();
    if (roomId == null) continue;
    final venueId = venueIdByName[_normalizeName(roomName)];
    if (venueId == null) {
      stderr.writeln(
        "warning: Sessionize room '$roomName' has no matching venue in "
        'Firestore; its sessions will be skipped. Add a venue whose name '
        'matches, or rename the room.',
      );
      continue;
    }
    mapping[roomId] = venueId;
  }
  return mapping;
}

/// Sessionize's `Language` category mapped onto `Session.primaryLocale`.
String _primaryLocaleOf(Map<String, dynamic> session, _CategoryCatalog categories) {
  final language = categories.itemFor(session, _kCategoryLanguage) ?? '';
  return language.toLowerCase().contains('english') ? 'en' : 'ja';
}

/// Whether [session] is a lightning talk, and whether it is the beginners'
/// variant. Matched on substrings because the CfS item labels carry
/// qualifiers, e.g. `LT (Japanese only)` / `ビギナーズ LT (Japanese only)`.
({bool isLightningTalk, bool isBeginners}) _formatOf(
  Map<String, dynamic> session,
  _CategoryCatalog categories,
) {
  final format = categories.itemFor(session, _kCategorySessionFormat) ?? '';
  // Check the beginners' variant first — its label also contains "LT".
  if (format.contains('ビギナーズ')) {
    return (isLightningTalk: true, isBeginners: true);
  }
  if (format.contains('LT')) {
    return (isLightningTalk: true, isBeginners: false);
  }
  return (isLightningTalk: false, isBeginners: false);
}

/// Extracts an X (Twitter) handle from a Sessionize speaker link list.
///
/// Sessionize stores full profile URLs, while `Speaker.xId` holds the bare
/// handle (e.g. `flutter_taro`). Returns null when the speaker did not provide
/// one, in which case the import leaves any dashboard-entered value alone.
String? _xIdOf(Map<String, dynamic> speaker) {
  for (final link in ((speaker['links'] as List?) ?? const []).whereType<Map<String, dynamic>>()) {
    if ((link['linkType'] ?? '').toString() != 'Twitter') continue;
    final url = (link['url'] ?? '').toString().trim();
    if (url.isEmpty) continue;
    final segments = Uri.tryParse(url)?.pathSegments.where((s) => s.isNotEmpty).toList() ?? const [];
    if (segments.isEmpty) continue;
    return segments.first.replaceFirst('@', '');
  }
  return null;
}

// ── Write planning ──────────────────────────────────────────────────────────

/// A single Firestore upsert: which document, the fields to send, and the
/// update mask limiting which of them may be written.
class _Write {
  const _Write({required this.path, required this.data, required this.updateMask});

  final String path;
  final Map<String, Object?> data;
  final List<String> updateMask;
}

class _Plan {
  final writes = <_Write>[];
  final skipped = <String, int>{};
  var unchanged = 0;

  void skip(String reason) => skipped[reason] = (skipped[reason] ?? 0) + 1;

  void report() {
    stdout.writeln('\nPlanned writes: ${writes.length}, unchanged: $unchanged');
    for (final entry in skipped.entries) {
      stdout.writeln('  skipped ${entry.value}: ${entry.key}');
    }
  }
}

_Plan _buildPlan({
  required _SessionizePayload payload,
  required _CategoryCatalog categories,
  required Map<int, String> venueIdByRoomId,
  required Map<String, Map<String, dynamic>> existingSessions,
  required Map<String, Map<String, dynamic>> existingSpeakers,
  required Map<String, Map<String, dynamic>> existingEvents,
}) {
  final plan = _Plan();
  final now = DateTime.now().toUtc();

  // Speakers referenced by at least one importable session. Speakers whose
  // sessions are all unscheduled would otherwise land in Firestore without
  // anything pointing at them.
  final referencedSpeakerIds = <String>{};

  for (final session in payload.sessions) {
    final id = (session['id'] ?? '').toString();
    if (id.isEmpty) continue;

    final status = (session['status'] ?? '').toString();
    final isService = session['isServiceSession'] == true;
    // Only the event-wide slots (opening, lunch, the closing party) become
    // timeline events. Room-bound service sessions — sponsor slots, the LT
    // block, the quiz — are part of the programme and stay sessions.
    final isPlenary = session['isPlenumSession'] == true;
    // Service sessions carry no acceptance status; everything else must be
    // accepted. A non-accepted session means the endpoint is not restricted
    // to the programme — refuse it rather than leaking it into Firestore.
    if (!isService && status != _kAcceptedStatus) {
      plan.skip("status is '$status', not $_kAcceptedStatus — check the endpoint's 'Includes sessions' setting");
      continue;
    }

    final startsAt = _parseSessionizeDateTime(session['startsAt']);
    final endsAt = _parseSessionizeDateTime(session['endsAt']);
    if (startsAt == null) {
      plan.skip('not scheduled yet (startsAt is null)');
      continue;
    }

    final title = (session['title'] ?? '').toString().trim();
    if (title.isEmpty) {
      plan.skip('missing title');
      continue;
    }

    if (isPlenary) {
      // Timeline events allow a null venue (a break is not tied to a room).
      final roomId = _asInt(session['roomId']);
      final write = _planTimelineEvent(
        id: id,
        title: title,
        startsAt: startsAt,
        endsAt: endsAt,
        venueId: roomId == null ? null : venueIdByRoomId[roomId],
        existing: existingEvents[id],
        now: now,
      );
      if (write == null) {
        plan.unchanged++;
      } else {
        plan.writes.add(write);
      }
      continue;
    }

    if (endsAt == null) {
      plan.skip('not scheduled yet (endsAt is null)');
      continue;
    }
    final roomId = _asInt(session['roomId']);
    final venueId = roomId == null ? null : venueIdByRoomId[roomId];
    if (venueId == null) {
      plan.skip('no room assigned, or the room has no matching venue');
      continue;
    }

    final speakerIds = ((session['speakers'] as List?) ?? const [])
        .map((s) => s.toString())
        .where((s) => s.isNotEmpty)
        .toList();
    referencedSpeakerIds.addAll(speakerIds);

    final write = _planSession(
      id: id,
      session: session,
      categories: categories,
      title: title,
      startsAt: startsAt,
      endsAt: endsAt,
      venueId: venueId,
      speakerIds: speakerIds,
      existing: existingSessions[id],
      now: now,
    );
    if (write == null) {
      plan.unchanged++;
    } else {
      plan.writes.add(write);
    }
  }

  for (final speaker in payload.speakers) {
    final id = (speaker['id'] ?? '').toString();
    if (id.isEmpty || !referencedSpeakerIds.contains(id)) continue;

    final write = _planSpeaker(
      id: id,
      speaker: speaker,
      existing: existingSpeakers[id],
      now: now,
    );
    if (write == null) {
      plan.unchanged++;
    } else {
      plan.writes.add(write);
    }
  }

  return plan;
}

/// Builds the `sessions/<id>` write, or null when nothing changed.
_Write? _planSession({
  required String id,
  required Map<String, dynamic> session,
  required _CategoryCatalog categories,
  required String title,
  required DateTime startsAt,
  required DateTime endsAt,
  required String venueId,
  required List<String> speakerIds,
  required Map<String, dynamic>? existing,
  required DateTime now,
}) {
  final primaryLocale = _primaryLocaleOf(session, categories);
  final format = _formatOf(session, categories);
  final description = (session['description'] ?? '').toString().trim();

  final fields = <String, Object?>{
    'primaryLocale': primaryLocale,
    'startsAt': startsAt,
    'endsAt': endsAt,
    'venueId': venueId,
    'speakerIds': speakerIds,
    'isLightningTalk': format.isLightningTalk,
    'isBeginnersLightningTalk': format.isBeginners,
  };
  // `isHandsOn` and `sessionizeUrl` are deliberately absent: Sessionize has no
  // equivalent, so they stay owned by the dashboard.

  final text = _planLocalizedText(
    existing: existing,
    primaryLocale: primaryLocale,
    title: title,
    description: description,
  );
  fields.addAll(text.fields);

  return _finalizeWrite(
    path: 'sessions/$id',
    fields: fields,
    extraMask: text.mask,
    existing: existing,
    now: now,
  );
}

/// Builds the `timelineEvents/<id>` write, or null when nothing changed.
_Write? _planTimelineEvent({
  required String id,
  required String title,
  required DateTime startsAt,
  required DateTime? endsAt,
  required String? venueId,
  required Map<String, dynamic>? existing,
  required DateTime now,
}) {
  final fields = <String, Object?>{
    'startsAt': startsAt,
    'endsAt': endsAt,
    'venueId': venueId,
  };
  // Service sessions have no language category; they are authored in Japanese.
  final text = _planLocalizedText(
    existing: existing,
    primaryLocale: 'ja',
    title: title,
    description: null,
  );
  fields.addAll(text.fields);

  return _finalizeWrite(
    path: 'timelineEvents/$id',
    fields: fields,
    extraMask: text.mask,
    existing: existing,
    now: now,
  );
}

/// Builds the `speakers/<id>` write, or null when nothing changed.
_Write? _planSpeaker({
  required String id,
  required Map<String, dynamic> speaker,
  required Map<String, dynamic>? existing,
  required DateTime now,
}) {
  final name = (speaker['fullName'] ?? '').toString().trim();
  if (name.isEmpty) return null;

  final avatarUrl = (speaker['profilePicture'] ?? '').toString().trim();
  final bio = (speaker['bio'] ?? '').toString().trim();
  final xId = _xIdOf(speaker);

  final fields = <String, Object?>{
    'name': name,
    'avatarUrl': avatarUrl.isEmpty ? null : avatarUrl,
    'bio': bio.isEmpty ? null : bio,
    // Only sent when Sessionize actually has one, so a handle entered in the
    // dashboard survives a speaker who left the field blank.
    'xId': ?xId,
  };

  return _finalizeWrite(
    path: 'speakers/$id',
    fields: fields,
    extraMask: const [],
    existing: existing,
    now: now,
  );
}

/// Decides which halves of `title` / `description` this import may write.
///
/// Sessionize only ever holds the original language, so the translated half is
/// owned by the translation pass and the dashboard. The original half is
/// rewritten only when it actually changed upstream; on a first import both
/// halves are seeded with the original so the document is valid until the
/// translation lands.
({Map<String, Object?> fields, List<String> mask}) _planLocalizedText({
  required Map<String, dynamic>? existing,
  required String primaryLocale,
  required String title,
  required String? description,
}) {
  final other = primaryLocale == 'ja' ? 'en' : 'ja';
  final fields = <String, Object?>{};
  final mask = <String>[];

  void plan(String field, String value) {
    final current = existing?[field];
    if (current is! Map) {
      // First import: seed both locales with the original text.
      fields[field] = {primaryLocale: value, other: value};
      mask
        ..add('$field.$primaryLocale')
        ..add('$field.$other');
      return;
    }
    if ((current[primaryLocale] ?? '').toString() == value) {
      return; // Original unchanged — leave the translation untouched.
    }
    // Original changed upstream: refresh only that half. The now-stale
    // translation is left in place for the translation pass to revisit.
    fields[field] = {primaryLocale: value};
    mask.add('$field.$primaryLocale');
  }

  plan('title', title);
  if (description != null) plan('description', description);

  return (fields: fields, mask: mask);
}

/// Adds timestamps, drops the write when every field already matches, and
/// assembles the update mask.
_Write? _finalizeWrite({
  required String path,
  required Map<String, Object?> fields,
  required List<String> extraMask,
  required Map<String, dynamic>? existing,
  required DateTime now,
}) {
  // `title` / `description` are masked per locale by [_planLocalizedText];
  // everything else is a whole-field write.
  final scalarFields = {...fields}..removeWhere((k, _) => k == 'title' || k == 'description');

  final changed =
      existing == null ||
      extraMask.isNotEmpty ||
      scalarFields.entries.any((e) => !_sameValue(existing[e.key], e.value));
  if (!changed) return null;

  final data = {...fields, 'updatedAt': now};
  final mask = [...scalarFields.keys, ...extraMask, 'updatedAt'];
  if (existing == null) {
    data['createdAt'] = now;
    mask.add('createdAt');
  }

  return _Write(path: path, data: data, updateMask: mask);
}

// ── Firestore config ────────────────────────────────────────────────────────

/// Resolves the [FirestoreRestConfig] from the `FIRESTORE_*` /
/// `FIREBASE_PROJECT_ID` env vars; defaults to the local emulator.
FirestoreRestConfig _resolveFirestoreConfig() {
  final projectId = Platform.environment['FIREBASE_PROJECT_ID'] ?? _defaultProjectId;
  final emulatorHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  final host = _normalizeHost(
    Platform.environment['FIRESTORE_HOST'] ?? emulatorHost ?? _defaultFirestoreHost,
  );
  final isEmulator = emulatorHost != null || host.startsWith('localhost') || host.startsWith('127.0.0.1');

  stdout.writeln(
    'Importing into Firestore '
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

// ── Helpers ─────────────────────────────────────────────────────────────────

Map<String, Map<String, dynamic>> _byId(List<Map<String, dynamic>> docs) => {
  for (final doc in docs)
    if ((doc['id'] ?? '').toString().isNotEmpty) doc['id'].toString(): doc,
};

/// Compares a decoded Firestore value against a value about to be written.
/// Timestamps arrive as ISO-8601 strings from the REST read path but as
/// [DateTime] on the write side, so they are normalised before comparing.
bool _sameValue(Object? existing, Object? next) {
  if (next is DateTime) {
    final current = _asDateTime(existing);
    return current != null && current.isAtSameMomentAs(next);
  }
  if (next is List) {
    if (existing is! List || existing.length != next.length) return false;
    for (var i = 0; i < next.length; i++) {
      if (!_sameValue(existing[i], next[i])) return false;
    }
    return true;
  }
  if (next is Map) {
    if (existing is! Map || existing.length != next.length) return false;
    for (final entry in next.entries) {
      if (!existing.containsKey(entry.key)) return false;
      if (!_sameValue(existing[entry.key], entry.value)) return false;
    }
    return true;
  }
  return existing == next;
}

/// Parses a Sessionize schedule timestamp.
///
/// Sessionize reports schedule times in the event's own timezone, and whether
/// an explicit offset is attached depends on the event configuration. A bare
/// `2026-10-29T10:15:00` would otherwise be read in the *runner's* local zone
/// — nine hours off whenever CI runs in UTC — so anything without an offset is
/// pinned to [_kEventUtcOffset].
DateTime? _parseSessionizeDateTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final hasOffset = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(value);
  return DateTime.tryParse(hasOffset ? value : '$value$_kEventUtcOffset')?.toUtc();
}

DateTime? _asDateTime(Object? value) {
  if (value is DateTime) return value.toUtc();
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value)?.toUtc();
  return null;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

/// Case- and whitespace-insensitive key for venue/room name matching.
String _normalizeName(String value) => value.replaceAll(RegExp(r'\s+'), '').toLowerCase();

String _normalizeHost(String host) {
  var value = host.trim().replaceFirst(RegExp(r'^https?://'), '');
  while (value.endsWith('/')) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}
