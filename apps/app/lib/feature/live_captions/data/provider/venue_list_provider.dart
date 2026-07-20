import 'package:app/feature/live_captions/data/provider/venue_repository.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Streams all venues, keyed by venue id, for name lookups.
final venueMapProvider = StreamProvider<Map<String, Venue>>(
  (ref) => ref
      .watch(venueRepositoryProvider)
      .watchAll()
      .map((venues) => {for (final venue in venues) venue.id: venue}),
);
