import 'package:data/data.dart';
import 'package:dashboard/feature/session/data/provider/session_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final sessionListProvider = StreamProvider<List<Session>>(
  (ref) => ref.watch(sessionRepositoryProvider).watchAll(),
);
