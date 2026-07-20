import 'package:app/feature/live_captions/data/provider/live_captions_repository.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Streams the latest finalized caption segments for one venue, oldest first.
final liveCaptionSegmentsProvider = StreamProvider.autoDispose.family<List<LiveCaptionSegment>, String>(
  (ref, roomId) => ref.watch(liveCaptionsRepositoryProvider).watchLatestSegments(roomId),
);
