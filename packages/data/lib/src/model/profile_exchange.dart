import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';

part 'profile_exchange.freezed.dart';
part 'profile_exchange.g.dart';

/// How a `users/{uid}/exchanges/{otherUid}` document was created.
///
/// `scan` is written by the attendee who scanned the other's QR code; `mirror`
/// is written server-side for the other attendee once the scan is verified.
/// Function triggers use this to avoid mirroring their own mirror writes.
@JsonEnum()
enum ProfileExchangeOrigin {
  @JsonValue('scan')
  scan,
  @JsonValue('mirror')
  mirror,
}

/// One entry in `users/{uid}/exchanges`: an attendee met via a profile
/// exchange. The document id is the other attendee's Firebase Auth uid.
@freezed
abstract class ProfileExchange with _$ProfileExchange {
  const ProfileExchange._();

  const factory ProfileExchange({
    /// The other attendee's uid, which is also the document id.
    required String id,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    required ProfileExchangeOrigin origin,

    /// Present only until the `onDocumentCreated` trigger verifies a `scan`
    /// write and clears it, so a validated token is never kept around.
    String? token,

    /// Free-form note visible only to the owner of this subcollection.
    String? note,
  }) = _ProfileExchange;

  factory ProfileExchange.fromJson(Map<String, dynamic> json) => _$ProfileExchangeFromJson(json);
}
