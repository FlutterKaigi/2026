import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_repository.dart';
import 'package:app/feature/exchange/ui/page/exchange_scan_page.dart';
import 'package:app/feature/profile/data/provider/user_profile_repository.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'fake_auth_repository.dart';
import 'fake_profile_exchange_repository.dart';
import 'fake_user_profile_repository.dart';

void main() {
  // mobile_scanner talks to the platform over a method channel that has no
  // implementation in widget tests. Faking the platform (rather than
  // stubbing a channel) keeps `MobileScannerController.start()` inside its
  // own documented error handling (`value.error` -> `errorBuilder`) instead
  // of throwing an unhandled `MissingPluginException` from `initState()`'s
  // fire-and-forget `_initializeController()`. `onDetect` itself is a plain
  // callback stored on the `MobileScanner` widget, so it can still be
  // invoked directly regardless of this — the tests below never depend on a
  // real camera preview rendering.
  final originalPlatform = MobileScannerPlatform.instance;
  setUpAll(() => MobileScannerPlatform.instance = _FakeMobileScannerPlatform());
  tearDownAll(() => MobileScannerPlatform.instance = originalPlatform);

  Widget buildSubject({
    required FakeAuthRepository authRepository,
    required FakeUserProfileRepository profileRepository,
    required FakeProfileExchangeRepository exchangeRepository,
  }) => TranslationProvider(
    child: ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        userProfileRepositoryProvider.overrideWithValue(profileRepository),
        profileExchangeRepositoryProvider.overrideWithValue(exchangeRepository),
      ],
      child: MaterialApp(
        locale: const Locale('ja'),
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const ExchangeScanPage()),
                ),
                child: const Text('open scan'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  UserProfile ownProfile() => UserProfile(
    id: 'uid-1',
    displayName: 'Me',
    countryOrRegion: 'JP',
    createdAt: DateTime.utc(2026, 8),
    updatedAt: DateTime.utc(2026, 8),
  );

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  Future<void> openScanPage(WidgetTester tester, Widget subject) async {
    await tester.pumpWidget(subject);
    await tester.pumpAndSettle();
    await tester.tap(find.text('open scan'));
    await tester.pumpAndSettle();
  }

  Future<void> detect(WidgetTester tester, String rawValue) async {
    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    scanner.onDetect!(BarcodeCapture(barcodes: [Barcode(rawValue: rawValue)]));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a profile prompt instead of the camera when reached without a profile', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository();
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();
    addTearDown(exchangeRepository.dispose);

    await openScanPage(
      tester,
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        exchangeRepository: exchangeRepository,
      ),
    );

    expect(find.text('プロフィールを作成すると自分のQRコードを表示できます'), findsOneWidget);
    expect(find.byType(MobileScanner), findsNothing);
  });

  testWidgets('rejects an unrelated QR code without creating an exchange', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: ownProfile());
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();
    addTearDown(exchangeRepository.dispose);

    await openScanPage(
      tester,
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        exchangeRepository: exchangeRepository,
      ),
    );

    await detect(tester, 'not a profile-exchange code');

    expect(find.text('読み取れませんでした。プロフィール交換用のQRコードか確認してください'), findsOneWidget);
    expect(exchangeRepository.createCalls, isEmpty);
  });

  testWidgets("rejects the signed-in user's own QR code without creating an exchange", (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: ownProfile());
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();
    addTearDown(exchangeRepository.dispose);

    await openScanPage(
      tester,
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        exchangeRepository: exchangeRepository,
      ),
    );

    await detect(tester, 'v1.uid-1.9999999999.deadbeef');

    expect(find.text('自分のQRコードは読み取れません'), findsOneWidget);
    expect(exchangeRepository.createCalls, isEmpty);
  });

  testWidgets('creates the exchange and returns to the previous page on success', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: ownProfile());
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();
    addTearDown(exchangeRepository.dispose);

    await openScanPage(
      tester,
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        exchangeRepository: exchangeRepository,
      ),
    );

    await detect(tester, 'v1.uid-2.9999999999.deadbeef');

    expect(exchangeRepository.createCalls, [(uid: 'uid-1', otherUid: 'uid-2', token: 'v1.uid-2.9999999999.deadbeef')]);
    expect(find.text('プロフィールを交換しました'), findsOneWidget);
    expect(find.text('open scan'), findsOneWidget);
    expect(find.byType(ExchangeScanPage), findsNothing);
  });

  testWidgets('shows an already-exchanged message and keeps scanning on a duplicate scan', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: ownProfile());
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository()
      ..nextError = const ProfileExchangeAlreadyExistsException();
    addTearDown(exchangeRepository.dispose);

    await openScanPage(
      tester,
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        exchangeRepository: exchangeRepository,
      ),
    );

    await detect(tester, 'v1.uid-2.9999999999.deadbeef');

    expect(find.text('すでに交換済みです'), findsOneWidget);
    expect(find.byType(ExchangeScanPage), findsOneWidget);
  });

  testWidgets('shows a generic failure message for any other repository error', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: ownProfile());
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository()..nextError = Exception('boom');
    addTearDown(exchangeRepository.dispose);

    await openScanPage(
      tester,
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        exchangeRepository: exchangeRepository,
      ),
    );

    await detect(tester, 'v1.uid-2.9999999999.deadbeef');

    expect(find.text('プロフィールを交換できませんでした'), findsOneWidget);
    expect(find.byType(ExchangeScanPage), findsOneWidget);
  });

  testWidgets('shows a camera error message when the camera is unavailable', (tester) async {
    final authRepository = FakeAuthRepository(initialUser: FakeUser(uid: 'uid-1'));
    addTearDown(authRepository.dispose);
    final profileRepository = FakeUserProfileRepository(initialProfile: ownProfile());
    addTearDown(profileRepository.dispose);
    final exchangeRepository = FakeProfileExchangeRepository();
    addTearDown(exchangeRepository.dispose);

    await openScanPage(
      tester,
      buildSubject(
        authRepository: authRepository,
        profileRepository: profileRepository,
        exchangeRepository: exchangeRepository,
      ),
    );

    expect(find.text('カメラを利用できません。設定でカメラへのアクセスを許可してください'), findsOneWidget);
  });
}

/// Fails every `start()` the way an unavailable camera would, so
/// [MobileScannerController] surfaces it through `value.error` (and the
/// widget's `errorBuilder`) rather than a raw platform-channel exception.
final class _FakeMobileScannerPlatform extends MobileScannerPlatform {
  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) {
    throw const MobileScannerException(
      errorCode: MobileScannerErrorCode.genericError,
      errorDetails: MobileScannerErrorDetails(message: 'No platform camera in widget tests.'),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
