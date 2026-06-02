import 'package:data/data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'news_provider.g.dart';

@Riverpod(keepAlive: true)
NewsRepository newsRepository(Ref ref) {
  return FirestoreNewsRepository();
}

@riverpod
Future<List<News>> news(Ref ref) {
  return ref.watch(newsRepositoryProvider).fetchNews();
}
