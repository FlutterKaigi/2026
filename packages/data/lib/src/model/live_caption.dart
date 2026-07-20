import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';

part 'live_caption.freezed.dart';
part 'live_caption.g.dart';

/// Room-level live captions state (`live_captions/{roomId}`).
///
/// The room id equals the venue id (`venues/{venueId}`), which is how sessions
/// (via `Session.venueId`) and QR codes map to a caption stream. The captions
/// server owns this document; clients only read it.
@freezed
abstract class LiveCaptionRoom with _$LiveCaptionRoom {
  const LiveCaptionRoom._();

  const factory LiveCaptionRoom({
    required String id,
    /// Manual kill switch. Set to false by operators to hide captions even
    /// while the server is connected.
    @Default(true) bool enabled,
    /// True while a broadcaster connection is ingesting audio for this room.
    @Default(false) bool isLive,
    /// BCP-47 tag of the language currently being transcribed (e.g. `ja-JP`).
    String? sourceLang,
    /// Latest in-progress (not yet finalized) transcript, overwritten in place.
    LiveCaptionInterim? interim,
    @FirestoreNullableDateTimeConverter() DateTime? updatedAt,
  }) = _LiveCaptionRoom;

  factory LiveCaptionRoom.fromJson(Map<String, dynamic> json) => _$LiveCaptionRoomFromJson(json);

  /// Whether captions should be shown to attendees right now.
  bool get isShowable => enabled && isLive;
}

/// In-progress transcript line nested in the room document.
@freezed
abstract class LiveCaptionInterim with _$LiveCaptionInterim {
  const factory LiveCaptionInterim({
    required String text,
    required String srcLang,
    @FirestoreNullableDateTimeConverter() DateTime? updatedAt,
  }) = _LiveCaptionInterim;

  factory LiveCaptionInterim.fromJson(Map<String, dynamic> json) => _$LiveCaptionInterimFromJson(json);
}

/// A finalized, translated caption (`live_captions/{roomId}/segments/{id}`).
///
/// Document ids are `{connectionStartMs}-{seq6}` so they sort chronologically
/// across reconnections; order by document id, not by [seq] (which resets per
/// broadcaster connection).
@freezed
abstract class LiveCaptionSegment with _$LiveCaptionSegment {
  const LiveCaptionSegment._();

  const factory LiveCaptionSegment({
    required String id,
    required int seq,
    required String srcLang,
    required String srcText,
    required String ja,
    required String en,
    @Default(0) int startMs,
    @Default(0) int endMs,
    @FirestoreNullableDateTimeConverter() DateTime? createdAt,
  }) = _LiveCaptionSegment;

  factory LiveCaptionSegment.fromJson(Map<String, dynamic> json) => _$LiveCaptionSegmentFromJson(json);
}
