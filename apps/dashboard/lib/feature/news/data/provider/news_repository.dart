import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final newsRepositoryProvider = Provider<NewsRepository>(
  (_) => FirestoreNewsRepository(),
);
