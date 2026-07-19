import 'package:data/data.dart';
import 'package:dashboard/feature/venue/data/provider/venue_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final venueListProvider = StreamProvider<List<Venue>>(
  (ref) => ref.watch(venueRepositoryProvider).watchAll(),
);
