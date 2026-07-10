import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final newsListRepositoryProvider = Provider<NewsRepository>(
  (_) => FirestoreNewsRepository(),
);
