import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides the [NewsRepository] implementation backed by Firestore.
final newsRepositoryProvider = Provider<NewsRepository>(
  (ref) => FirestoreNewsRepository(),
);
