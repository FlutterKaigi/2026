import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final timelineEventRepositoryProvider = Provider<TimelineEventRepository>(
  (_) => FirestoreTimelineEventRepository(),
);
