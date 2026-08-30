import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_code.freezed.dart';

/// A short-lived 6-digit code for exchanging profiles without a camera,
/// issued by the `issueExchangeCode` callable function.
///
/// Unlike `ExchangeToken` this is never cached on-device: the whole point of
/// the code fallback is a live, short window (5 minutes server-side), so
/// there is nothing worth persisting across app restarts.
@freezed
abstract class ExchangeCode with _$ExchangeCode {
  const factory ExchangeCode({
    required String value,
    required DateTime expiresAt,
  }) = _ExchangeCode;

  const ExchangeCode._();

  bool get isExpired => !DateTime.now().isBefore(expiresAt);
}
