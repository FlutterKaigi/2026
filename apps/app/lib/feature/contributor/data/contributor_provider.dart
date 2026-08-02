import 'package:app/feature/contributor/data/contributor_repository.dart';
import 'package:app/feature/contributor/data/model/contributor.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final contributorRepositoryProvider = Provider<ContributorRepository>(
  (ref) => const ContributorRepository(),
);

// Deliberately not autoDispose: the unauthenticated GitHub API allows only 60
// requests per hour per IP, so the result is kept for the app session and
// refreshed explicitly via pull-to-refresh.
final contributorsProvider = FutureProvider<List<Contributor>>(
  (ref) => ref.watch(contributorRepositoryProvider).fetchContributors(),
);
