import 'package:app/feature/live_captions/data/provider/live_captions_repository.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Streams every caption room, keyed by room id (= venue id), for live badges.
final liveCaptionRoomsProvider = StreamProvider<Map<String, LiveCaptionRoom>>(
  (ref) => ref
      .watch(liveCaptionsRepositoryProvider)
      .watchRooms()
      .map((rooms) => {for (final room in rooms) room.id: room}),
);
