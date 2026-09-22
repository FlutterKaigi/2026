import 'package:app/feature/exchange/data/exchange_code_redeem_handler.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_profile_exchange_repository.dart';

void main() {
  group('ExchangeCodeRedeemHandler', () {
    late FakeProfileExchangeRepository repository;

    setUp(() => repository = FakeProfileExchangeRepository());
    tearDown(() => repository.dispose());

    ExchangeCodeRedeemHandler buildHandler(_StubExchangeCodeRedeemer redeemer) => ExchangeCodeRedeemHandler(
      myUid: 'uid-1',
      redeemer: redeemer,
      repository: repository,
    );

    test('creates the exchange from the token the redeemer returns', () async {
      final outcome = await buildHandler(_StubExchangeCodeRedeemer()).redeem('123456');

      expect(outcome, isA<RedeemExchangeCodeSucceeded>());
      expect(repository.createCalls, [
        (uid: 'uid-1', otherUid: 'uid-2', token: 'v1.uid-2.9999999999.deadbeef'),
      ]);
    });

    test('reports ExchangeAlreadyExists when the exchange is already in the list', () async {
      repository.nextError = const ProfileExchangeAlreadyExistsException();

      final outcome = await buildHandler(_StubExchangeCodeRedeemer()).redeem('123456');

      expect(outcome, isA<RedeemExchangeCodeAlreadyExists>());
    });

    test('maps a not-found FirebaseFunctionsException to Invalid', () async {
      final redeemer = _StubExchangeCodeRedeemer()
        ..nextError = FirebaseFunctionsException(code: 'not-found', message: 'not found');

      final outcome = await buildHandler(redeemer).redeem('123456');

      expect(outcome, isA<RedeemExchangeCodeInvalid>());
      expect(repository.createCalls, isEmpty);
    });

    test('maps an invalid-argument FirebaseFunctionsException to Invalid', () async {
      final redeemer = _StubExchangeCodeRedeemer()
        ..nextError = FirebaseFunctionsException(code: 'invalid-argument', message: 'bad format');

      final outcome = await buildHandler(redeemer).redeem('abcdef');

      expect(outcome, isA<RedeemExchangeCodeInvalid>());
    });

    test('maps a failed-precondition FirebaseFunctionsException to Self', () async {
      final redeemer = _StubExchangeCodeRedeemer()
        ..nextError = FirebaseFunctionsException(code: 'failed-precondition', message: 'own code');

      final outcome = await buildHandler(redeemer).redeem('123456');

      expect(outcome, isA<RedeemExchangeCodeSelf>());
    });

    test('maps a resource-exhausted FirebaseFunctionsException to RateLimited', () async {
      final redeemer = _StubExchangeCodeRedeemer()
        ..nextError = FirebaseFunctionsException(code: 'resource-exhausted', message: 'too many attempts');

      final outcome = await buildHandler(redeemer).redeem('123456');

      expect(outcome, isA<RedeemExchangeCodeRateLimited>());
    });

    test('maps an unrecognized FirebaseFunctionsException to Failed', () async {
      final redeemer = _StubExchangeCodeRedeemer()
        ..nextError = FirebaseFunctionsException(code: 'internal', message: 'boom');

      final outcome = await buildHandler(redeemer).redeem('123456');

      expect(outcome, isA<RedeemExchangeCodeFailed>());
    });

    test('reports Failed when the redeemer throws a non-Firebase exception', () async {
      final redeemer = _StubExchangeCodeRedeemer()..nextError = Exception('network down');

      final outcome = await buildHandler(redeemer).redeem('123456');

      expect(outcome, isA<RedeemExchangeCodeFailed>());
    });

    test('reports Failed when the returned token does not parse', () async {
      final redeemer = _StubExchangeCodeRedeemer()..nextToken = 'not-a-token';

      final outcome = await buildHandler(redeemer).redeem('123456');

      expect(outcome, isA<RedeemExchangeCodeFailed>());
      expect(repository.createCalls, isEmpty);
    });
  });
}

class _StubExchangeCodeRedeemer implements ExchangeCodeRedeemer {
  /// When set, the next [redeem] throws this error once.
  Exception? nextError;

  /// Overrides the token value the next successful [redeem] returns.
  String nextToken = 'v1.uid-2.9999999999.deadbeef';

  @override
  Future<ExchangeToken> redeem(String code) async {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    return ExchangeToken(value: nextToken, expiresAt: DateTime.now().add(const Duration(hours: 24)));
  }
}
