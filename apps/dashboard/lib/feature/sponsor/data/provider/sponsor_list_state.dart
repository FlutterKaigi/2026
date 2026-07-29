import 'package:data/data.dart';
import 'package:dashboard/feature/sponsor/data/provider/sponsor_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final sponsorListProvider = StreamProvider<List<Sponsor>>(
  // Hide tiers the dashboard does not recognize instead of failing the whole list.
  (ref) => ref.watch(sponsorRepositoryProvider).watchAll(excludeUnsupportedTiers: true),
);
