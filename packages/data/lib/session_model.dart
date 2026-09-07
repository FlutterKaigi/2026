/// The session-related domain models and their Firestore-REST access path —
/// no repositories, and (unlike `session.dart` / `speaker.dart`) no transitive
/// `cloud_firestore` import.
///
/// Import this instead of `package:data/session.dart` from contexts that
/// cannot compile Flutter-framework code, e.g. `tool/import_sessions.dart` and
/// `tool/generate_sessions.dart`, which run via a plain `dart run` and would
/// fail to compile if they pulled in `cloud_firestore` (a Flutter plugin)
/// through the repository exports. Mirrors `news_model.dart`.
library;

export 'src/firestore/firestore_rest_client.dart'
    show FirestoreRestConfig, encodeFirestoreFields, fetchFirestoreDocuments, upsertFirestoreDocument;
export 'src/model/locale_map.dart' show LocaleMap;
export 'src/model/session.dart' show Session;
export 'src/model/speaker.dart' show Speaker;
export 'src/model/timeline_event.dart' show TimelineEvent;
export 'src/model/venue.dart' show Venue;
