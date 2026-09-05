import 'package:clock/clock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_code.freezed.dart';

/// A time-limited 6-digit code for exchanging profiles without a camera,
/// issued by the `issueExchangeCode` callable function.
///
/// Redeemable by any number of attendees until [expiresAt] (5 minutes
/// server-side), so one attendee can read their code out to the people around
/// them the way they would hold up a QR code.
///
/// Unlike `ExchangeToken` this is never persisted to disk: `issueExchangeCode`
/// hands back the same live code rather than minting a new one, so an app
/// restart recovers it without a local copy.
@freezed
abstract class ExchangeCode with _$ExchangeCode {
  const factory ExchangeCode({
    required String value,
    required DateTime expiresAt,
  }) = _ExchangeCode;

  const ExchangeCode._();

  // Routed through package:clock (rather than DateTime.now() directly) so
  // widget tests can advance this via the FakeAsync clock that
  // `testWidgets` already runs every test body inside, and assert the
  // expired state appears from time passing alone.
  bool get isExpired => !clock.now().isBefore(expiresAt);
}
