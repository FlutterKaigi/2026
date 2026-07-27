/// The `News` domain model only — no `FirestoreNewsRepository`/`NewsRepository`,
/// and (unlike `news.dart`) no transitive `cloud_firestore` import.
///
/// Import this instead of `package:data/news.dart` from contexts that cannot
/// compile Flutter-framework code, e.g. `tool/generate_news.dart`, which runs
/// via a plain `dart run` and would fail to compile if it pulled in
/// `cloud_firestore` (a Flutter plugin) through the repository export.
library;

export 'src/model/locale_map.dart' show LocaleMap;
export 'src/model/news.dart' show News;
