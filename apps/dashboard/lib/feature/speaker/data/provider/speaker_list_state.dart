import 'package:data/data.dart';
import 'package:dashboard/feature/speaker/data/provider/speaker_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final speakerListProvider = StreamProvider<List<Speaker>>(
  (ref) => ref.watch(speakerRepositoryProvider).watchAll(),
);
