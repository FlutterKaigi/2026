import 'package:app/feature/contributor/data/provider/contributor_repository.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Streams contributors from Firestore, ordered by contribution count.
///
/// The collection is refreshed daily from the GitHub API by
/// `.github/workflows/refresh_contributors.yaml`, so the app never calls the
/// GitHub API (and never hits its per-IP rate limit) directly.
final contributorListProvider = StreamProvider<List<Contributor>>(
  (ref) => ref.watch(contributorRepositoryProvider).watchAll(),
);
