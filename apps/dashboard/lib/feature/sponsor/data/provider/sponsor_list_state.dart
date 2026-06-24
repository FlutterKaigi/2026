import 'package:data/data.dart';
import 'package:dashboard/feature/sponsor/data/provider/sponsor_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final sponsorListProvider = StreamProvider<List<Sponsor>>(
  (ref) => ref.watch(sponsorRepositoryProvider).watchAll(),
);
