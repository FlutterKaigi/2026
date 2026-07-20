import 'package:data/data.dart';
import 'package:dashboard/feature/news/data/provider/news_list_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final newsListProvider = StreamProvider<List<News>>(
  (ref) => ref.watch(newsListRepositoryProvider).watchAll(),
);
