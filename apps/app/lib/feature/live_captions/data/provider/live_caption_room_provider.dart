import 'package:app/feature/live_captions/data/provider/live_captions_repository.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Streams the caption room document for one venue (`null` until it exists).
final liveCaptionRoomProvider = StreamProvider.autoDispose.family<LiveCaptionRoom?, String>(
  (ref, roomId) => ref.watch(liveCaptionsRepositoryProvider).watchRoom(roomId),
);
