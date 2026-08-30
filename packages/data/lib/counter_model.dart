/// Flutter-free access to the `counters` Firestore collection (see
/// `packages/data/firebase/schemas/firestore/counter.schema.json`), for
/// contexts that cannot compile `cloud_firestore` — e.g.
/// `tool/generate_exchange_counter.dart`, which runs via a plain `dart run`
/// and would fail to compile if it pulled in `cloud_firestore` (a Flutter
/// plugin). Mirrors `news_model.dart` / `session_model.dart`.
///
/// There is no bespoke `Counter` model here (unlike `news_model.dart`'s
/// `News`): every counter document so far is just an id plus an integer
/// `count` field, and issue-594.md section 8 names the profile-exchange
/// count (this file's first consumer) plus the future missions (#600) and
/// quiz (#592) features as sharing the same `counters/{counterId}`
/// collection — so callers read `fetchFirestoreDocuments('counters', ...)`
/// directly and pick out the `count` field for whichever counter id they
/// need, rather than each maintaining its own copy of that logic.
library;

export 'src/firestore/firestore_rest_client.dart' show FirestoreRestConfig, fetchFirestoreDocuments;
