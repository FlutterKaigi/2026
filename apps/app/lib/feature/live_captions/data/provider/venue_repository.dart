import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provides the [VenueRepository] implementation backed by Firestore.
final venueRepositoryProvider = Provider<VenueRepository>(
  (ref) => FirestoreVenueRepository(),
);
