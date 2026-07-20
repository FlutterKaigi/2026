import 'package:dart_firebase_admin/firestore.dart';

import '../logging.dart';

/// Loads a per-room prompt context so Gemini keeps proper nouns spelled the
/// way the conference data spells them (session title, speaker names, sponsor
/// company names). Returns `null` when nothing useful is available.
abstract interface class SessionContextLoader {
  Future<String?> load(String roomId);
}

/// [SessionContextLoader] backed by the same Firestore project the captions
/// are written to. Room ids equal venue ids, so the session currently
/// scheduled in the room is found via `sessions.venueId` + the wall clock.
final class FirestoreSessionContextLoader implements SessionContextLoader {
  FirestoreSessionContextLoader(this._firestore, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final Firestore _firestore;
  final DateTime Function() _now;

  /// Longest description excerpt (per language) included in the prompt.
  static const _descriptionLimit = 240;

  /// Upper bound of sponsor names included in the prompt.
  static const _sponsorLimit = 60;

  @override
  Future<String?> load(String roomId) async {
    final buffer = StringBuffer();
    final session = await _currentSession(roomId);
    if (session != null) {
      final title = _localeMap(session['title']);
      final description = _localeMap(session['description']);
      buffer.writeln('セッション名: ${title.$1} / ${title.$2}');
      final speakers = await _speakerNames(session['speakerIds']);
      if (speakers.isNotEmpty) {
        buffer.writeln('登壇者: ${speakers.join('、')}');
      }
      if (description.$1.isNotEmpty) {
        buffer.writeln('セッション概要: ${_truncate(description.$1)}');
      }
      if (description.$2.isNotEmpty) {
        buffer.writeln('Session description: ${_truncate(description.$2)}');
      }
    }

    final sponsors = await _sponsorNames();
    if (sponsors.isNotEmpty) {
      buffer.writeln('スポンサー企業名: ${sponsors.join('、')}');
    }

    final context = buffer.toString().trim();
    return context.isEmpty ? null : context;
  }

  /// The session scheduled right now in this venue, or `null`.
  Future<Map<String, Object?>?> _currentSession(String roomId) async {
    final snapshot = await _firestore
        .collection('sessions')
        .where('venueId', WhereFilter.equal, roomId)
        .get();
    final now = _now();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final startsAt = _toDateTime(data['startsAt']);
      final endsAt = _toDateTime(data['endsAt']);
      if (startsAt == null || endsAt == null) continue;
      if (!now.isBefore(startsAt) && !now.isAfter(endsAt)) return data;
    }
    return null;
  }

  Future<List<String>> _speakerNames(Object? speakerIds) async {
    if (speakerIds is! List) return const [];
    final names = <String>[];
    for (final id in speakerIds.whereType<String>()) {
      final doc = await _firestore.doc('speakers/$id').get();
      final name = doc.data()?['name'];
      if (name is String && name.isNotEmpty) names.add(name);
    }
    return names;
  }

  Future<List<String>> _sponsorNames() async {
    final snapshot = await _firestore.collection('sponsors').get();
    final names = <String>[];
    for (final doc in snapshot.docs.take(_sponsorLimit)) {
      final (ja, en) = _localeMap(doc.data()['name']);
      if (ja.isEmpty && en.isEmpty) continue;
      names.add(ja == en || en.isEmpty ? ja : '$ja / $en');
    }
    return names;
  }

  /// Extracts `(ja, en)` from a `{ja, en}` map field.
  (String, String) _localeMap(Object? value) {
    if (value is! Map) return ('', '');
    final ja = value['ja'];
    final en = value['en'];
    return (ja is String ? ja : '', en is String ? en : '');
  }

  DateTime? _toDateTime(Object? value) {
    if (value is Timestamp) {
      return DateTime.fromMillisecondsSinceEpoch(value.seconds * 1000, isUtc: true);
    }
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  String _truncate(String text) => text.length <= _descriptionLimit ? text : '${text.substring(0, _descriptionLimit)}…';
}

/// Wraps [SessionContextLoader.load] with logging; never throws.
Future<String?> loadSessionContext(SessionContextLoader? loader, String roomId) async {
  if (loader == null) return null;
  try {
    final context = await loader.load(roomId);
    logEvent('session_context', {'roomId': roomId, 'chars': context?.length ?? 0});
    return context;
  } catch (e) {
    logEvent('session_context_error', {'roomId': roomId, 'error': '$e'}, 'error');
    return null;
  }
}
