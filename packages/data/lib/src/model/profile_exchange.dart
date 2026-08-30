import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';

part 'profile_exchange.freezed.dart';
part 'profile_exchange.g.dart';

/// One side of an exchanged profile, stored at `users/{uid}/exchanges/{otherUid}`.
///
/// Each attendee keeps their own copy of the exchange in their own
/// subcollection; the other side is mirrored by a Cloud Function so an
/// attendee can remove an entry from their own list without affecting the
/// other party's list.
@freezed
abstract class ProfileExchange with _$ProfileExchange {
  const ProfileExchange._();

  const factory ProfileExchange({
    /// uid of the other attendee, which is also the document id.
    required String id,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    required ProfileExchangeOrigin origin,

    /// Signed exchange token presented when this document was created by a
    /// scan. Verified and cleared (set to `null`) by a Cloud Function once
    /// the mirror side has been created, so it never lingers in Firestore.
    String? token,

    /// Free-form note visible only to the owner of this subcollection.
    String? note,
  }) = _ProfileExchange;

  factory ProfileExchange.fromJson(Map<String, dynamic> json) => _$ProfileExchangeFromJson(json);

  /// Upper bound on [note] length, enforced in Firestore rules too.
  static const noteMaxLength = 300;
}

/// How a [ProfileExchange] entry came to exist.
enum ProfileExchangeOrigin {
  /// The owner scanned the other attendee's QR code (or redeemed their code).
  @JsonValue('scan')
  scan,

  /// The entry was mirrored by a Cloud Function after the other attendee
  /// scanned the owner's QR code.
  @JsonValue('mirror')
  mirror,
}
