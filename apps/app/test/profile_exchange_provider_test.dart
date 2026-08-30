import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/exchange/data/exchange_code.dart';
import 'package:app/feature/exchange/data/exchange_code_redeem_handler.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';

void main() {
  // myExchangeCodeProvider is autoDispose, so leaving and re-entering the
  // exchange screen tears down and rebuilds its AsyncNotifier — a pumpWidget
  // per screen visit can't reproduce that reliably, because Flutter's element
  // diffing reuses the ProviderScope's container (and therefore the still
  // undisposed provider) whenever the pumped widget tree keeps the same
  // shape. A fresh ProviderContainer per "visit" is what actually exercises
  // build() running again.
  group('myExchangeCodeProvider', () {
    test('reuses a still-valid cached code across separate provider instances', () async {
      final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
      addTearDown(authRepository.dispose);
      final codeIssuer = _StubExchangeCodeIssuer();
      final codeCache = InMemoryExchangeCodeCacheRepository();

      final firstVisit = _container(authRepository: authRepository, codeIssuer: codeIssuer, codeCache: codeCache);
      final firstCode = await _readCode(firstVisit);
      expect(codeIssuer.issueCallCount, 1);
      firstVisit.dispose(); // Leaves the exchange screen.

      final secondVisit = _container(authRepository: authRepository, codeIssuer: codeIssuer, codeCache: codeCache);
      addTearDown(secondVisit.dispose);
      final secondCode = await _readCode(secondVisit); // Re-enters the exchange screen.

      expect(codeIssuer.issueCallCount, 1, reason: 'the still-valid cached code must be reused, not reissued');
      expect(secondCode, firstCode);
    });

    test('issues a fresh code across separate provider instances once the cached one expired', () async {
      final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
      addTearDown(authRepository.dispose);
      final codeIssuer = _StubExchangeCodeIssuer()..nextExpiresAt = DateTime.now().subtract(const Duration(seconds: 1));
      final codeCache = InMemoryExchangeCodeCacheRepository();

      final firstVisit = _container(authRepository: authRepository, codeIssuer: codeIssuer, codeCache: codeCache);
      await _readCode(firstVisit);
      expect(codeIssuer.issueCallCount, 1);
      firstVisit.dispose();

      codeIssuer.nextExpiresAt = null;
      final secondVisit = _container(authRepository: authRepository, codeIssuer: codeIssuer, codeCache: codeCache);
      addTearDown(secondVisit.dispose);
      await _readCode(secondVisit);

      expect(codeIssuer.issueCallCount, 2);
    });

    test("keeps separate uids on the same cache instance from seeing each other's code", () async {
      final codeIssuer = _StubExchangeCodeIssuer();
      final codeCache = InMemoryExchangeCodeCacheRepository();

      final firstUser = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
      addTearDown(firstUser.dispose);
      final firstContainer = _container(authRepository: firstUser, codeIssuer: codeIssuer, codeCache: codeCache);
      await _readCode(firstContainer);
      firstContainer.dispose();

      final secondUser = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-2'));
      addTearDown(secondUser.dispose);
      final secondContainer = _container(authRepository: secondUser, codeIssuer: codeIssuer, codeCache: codeCache);
      addTearDown(secondContainer.dispose);
      await _readCode(secondContainer);

      expect(codeIssuer.issueCallCount, 2, reason: "uid-2 must not reuse uid-1's cached code");
    });
  });
}

ProviderContainer _container({
  required FakeAuthRepository authRepository,
  required ExchangeCodeIssuer codeIssuer,
  required ExchangeCodeCacheRepository codeCache,
}) => ProviderContainer(
  overrides: [
    authRepositoryProvider.overrideWithValue(authRepository),
    exchangeCodeIssuerProvider.overrideWithValue(codeIssuer),
    exchangeCodeCacheRepositoryProvider.overrideWithValue(codeCache),
  ],
);

/// Reads [myExchangeCodeProvider] to its resolved value.
///
/// Polls via [ProviderContainer.listen] rather than `container.read(provider
/// .future)`: the latter hung indefinitely for this specific
/// autoDispose-AsyncNotifier-depending-on-a-StreamProvider combination when
/// this file ran alongside other test files, even though the equivalent
/// `.future` read works fine for either provider in isolation.
Future<ExchangeCode> _readCode(ProviderContainer container) async {
  final authSubscription = container.listen(authStateChangesProvider, (_, _) {});
  for (var i = 0; i < 200 && authSubscription.read().isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  authSubscription.close();

  final codeSubscription = container.listen(myExchangeCodeProvider, (_, _) {});
  for (var i = 0; i < 200 && codeSubscription.read().isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  final state = codeSubscription.read();
  codeSubscription.close();
  return state.requireValue;
}

class _StubExchangeCodeIssuer implements ExchangeCodeIssuer {
  int issueCallCount = 0;

  /// Overrides the next issued code's expiry; defaults to 5 minutes from now.
  DateTime? nextExpiresAt;

  @override
  Future<ExchangeCode> issue() async {
    issueCallCount++;
    return ExchangeCode(
      value: '123456',
      expiresAt: nextExpiresAt ?? DateTime.now().add(const Duration(minutes: 5)),
    );
  }
}
