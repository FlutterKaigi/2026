import '../firestore/firestore_rest_client.dart';
import '../model/news.dart';

/// Fetches `news` documents via the Firestore REST API and decodes them
/// into [News].
///
/// Flutter-free — unlike [NewsRepository]/`FirestoreNewsRepository` (see
/// `package:data/news.dart`), this needs no `cloud_firestore` platform
/// channels or running Firebase app, so it works from plain `dart run`
/// scripts (e.g. `tool/generate_news.dart`).
///
/// A single malformed document (e.g. missing a required field) is skipped
/// with a warning via [onWarning] rather than failing the whole fetch — one
/// bad `news` doc should not blank out the rest of the list.
Future<List<News>> fetchNewsViaFirestoreRest(
  FirestoreRestConfig config, {
  void Function(String message)? onWarning,
}) async {
  final docs = await fetchFirestoreDocuments('news', config);
  final news = <News>[];
  for (final doc in docs) {
    try {
      news.add(News.fromJson(doc));
    } catch (e) {
      onWarning?.call('skipping malformed news document ${doc['id']}: $e');
    }
  }
  return news;
}
