import '../firebase_data_client.dart';
import '../model/news.dart';

abstract interface class NewsRepository {
  Future<List<News>> fetchNews();
}

final class FirestoreNewsRepository implements NewsRepository {
  const FirestoreNewsRepository(this._client);

  final FirebaseDataClient _client;

  @override
  Future<List<News>> fetchNews({DateTime? activeAt}) async {
    final documents = await _client.listDocuments(
      collectionPath: 'news',
      orderBy: 'startsAt desc',
    );
    final now = activeAt ?? DateTime.now();
    final news = [
      for (final document in documents)
        News.fromJson(<String, dynamic>{
          ...document.fields,
          'id': document.id,
        }),
    ]..sort((a, b) => b.startsAt.compareTo(a.startsAt));

    return news.where((item) => item.isActiveAt(now)).toList(growable: false);
  }
}
