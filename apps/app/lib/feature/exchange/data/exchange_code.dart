import 'package:clock/clock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_code.freezed.dart';

/// A short-lived 6-digit code for exchanging profiles without a camera,
/// issued by the `issueExchangeCode` callable function.
///
/// Unlike `ExchangeToken` this is never persisted to disk: the whole point of
/// the code fallback is a live, short window (5 minutes server-side), so
/// there is nothing worth surviving an app restart for.
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
