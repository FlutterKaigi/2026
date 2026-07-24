import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides access to the Firestore `sponsors` collection.
final sponsorRepositoryProvider = Provider<SponsorRepository>(
  (ref) => FirestoreSponsorRepository(),
);
