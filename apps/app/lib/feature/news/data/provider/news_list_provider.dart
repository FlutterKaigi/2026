import 'package:app/feature/news/data/provider/news_list_repository.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Streams published news items, newest first.
final newsListProvider = StreamProvider<List<News>>(
  (ref) => ref.watch(newsListRepositoryProvider).watchAll(),
);
