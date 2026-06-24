import 'package:data/data.dart';
import 'package:dashboard/feature/timeline_event/data/provider/timeline_event_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final timelineEventListProvider = StreamProvider<List<TimelineEvent>>(
  (ref) => ref.watch(timelineEventRepositoryProvider).watchAll(),
);
