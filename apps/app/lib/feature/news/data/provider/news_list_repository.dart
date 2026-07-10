import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides the [NewsRepository] implementation backed by Firestore.
final newsListRepositoryProvider = Provider<NewsRepository>(
  (ref) => FirestoreNewsRepository(),
);
