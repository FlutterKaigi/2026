import 'package:data/data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/provider/firebase_data_client.dart';

part 'news_provider.g.dart';

@Riverpod(keepAlive: true)
NewsRepository newsRepository(Ref ref) {
  return FirestoreNewsRepository(ref.watch(firebaseDataClientProvider));
}

@riverpod
Future<List<News>> news(Ref ref) {
  return ref.watch(newsRepositoryProvider).fetchNews();
}
