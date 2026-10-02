import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_repository.dart';
import 'package:app/feature/stamp_rally/data/stamp_rally_provider.dart';
import 'package:app/feature/stamp_rally/ui/page/stamp_rally_link_page.dart';
import 'package:app/feature/stamp_rally/ui/page/stamp_rally_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';
import 'fake_stamp_rally_repository.dart';

final _token = 'ab' * 32;

void main() {
  group('parseStampRallyUrl', () {
    test('accepts /s/<token> on any origin', () {
      for (final origin in ['https://2026-app.flutterkaigi.jp', 'https://example.com', 'http://localhost:8780']) {
        expect(parseStampRallyUrl('$origin/s/$_token'), _token);
      }
    });

    test('rejects other shapes', () {
      for (final raw in [
        _token,
        'https://2026-app.flutterkaigi.jp/x/$_token',
        'https://2026-app.flutterkaigi.jp/s/${_token.toUpperCase()}',
        'https://2026-app.flutterkaigi.jp/s/${_token.substring(1)}',
        'https://2026-app.flutterkaigi.jp/s/$_token/extra',
        'ftp://example.com/s/$_token',
      ]) {
        expect(parseStampRallyUrl(raw), isNull, reason: raw);
      }
    });
  });

  late FakeAuthRepository auth;
  late FakeStampRallyRepository stamps;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    auth = FakeAuthRepository(initialUser: FakeUser(uid: 'me'));
    stamps = FakeStampRallyRepository(sponsorIds: {'s1', 's2'});
  });

  Widget subject(String location, {ProviderContainer? container}) {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/s/:token',
          builder: (_, state) => StampRallyLinkPage(token: state.pathParameters['token']!),
        ),
        GoRoute(path: '/account/stamp-rally', builder: (_, _) => const StampRallyPage()),
      ],
    );
    addTearDown(router.dispose);
    final overrides = [
      authRepositoryProvider.overrideWithValue(auth),
      stampRallyRepositoryProvider.overrideWithValue(stamps),
      sponsorRepositoryProvider.overrideWithValue(_FakeSponsorRepository()),
      appleSignInAvailabilityProvider.overrideWithValue(false),
    ];
    final app = MaterialApp.router(
      routerConfig: router,
      locale: AppLocale.ja.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
    return TranslationProvider(
      child: container == null
          ? ProviderScope(retry: (_, _) => null, overrides: overrides, child: app)
          : UncontrolledProviderScope(container: container, child: app),
    );
  }

  testWidgets('the card shows progress, prizes, and which sponsors were stamped', (tester) async {
    stamps.card = StampRallyCard(
      stamps: {'s1': DateTime.utc(2026, 11, 13, 1)},
      rewardsRedeemedAt: {1: DateTime.utc(2026, 11, 13, 2)},
    );
    await tester.pumpWidget(subject('/account/stamp-rally'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('あと1個で景品#2'), findsOneWidget);
    expect(find.textContaining('交換済み'), findsOneWidget);
    expect(find.bySemanticsLabel('スポンサーA、獲得済み'), findsOneWidget);
    expect(find.bySemanticsLabel('スポンサーB、未獲得'), findsOneWidget);
  });

  testWidgets('a stamp link scans once and announces a new checkpoint', (tester) async {
    stamps.scanResult = StampRallyStampResult(
      sponsorId: 's1',
      alreadyAcquired: false,
      acquiredAt: DateTime.utc(2026, 11, 13),
      stampCount: 1,
      newCheckpoints: const [1],
      checkpoints: const [1, 2],
    );
    await tester.pumpWidget(subject('/s/$_token'));
    await tester.pumpAndSettle();

    expect(find.text('スタンプを獲得しました！'), findsOneWidget);
    expect(find.text('景品#1 の条件を達成しました！'), findsOneWidget);
    expect(stamps.scannedTokens, [_token]);
  });

  testWidgets('a reward link lists the prizes to hand over with every redemption time', (tester) async {
    stamps.scanResult = StampRallyRewardResult(
      redeemedCheckpoints: const [1, 2],
      redeemedAt: DateTime.utc(2026, 11, 13),
      stampCount: 14,
      checkpoints: const [7, 14, 22],
      rewardsRedeemedAt: {1: DateTime.utc(2026, 11, 13), 2: DateTime.utc(2026, 11, 13)},
    );
    await tester.pumpWidget(subject('/s/$_token'));
    await tester.pumpAndSettle();

    expect(find.text('#1, #2 の景品を受け取れます'), findsOneWidget);
    expect(find.textContaining('#2 交換日時'), findsOneWidget);
  });

  testWidgets('an unknown signature is reported as an invalid code', (tester) async {
    stamps.scanError = FirebaseFunctionsException(code: 'not-found', message: 'not found');
    await tester.pumpWidget(subject('/s/$_token'));
    await tester.pumpAndSettle();

    expect(find.text('無効なQRコードです'), findsOneWidget);
  });

  testWidgets('a malformed token is rejected without calling the server', (tester) async {
    await tester.pumpWidget(subject('/s/not-a-token'));
    await tester.pumpAndSettle();

    expect(find.text('無効なQRコードです'), findsOneWidget);
    expect(stamps.scannedTokens, isEmpty);
  });

  testWidgets('a signed-out visitor is queued and resolved after signing in on the page', (tester) async {
    auth = FakeAuthRepository();
    stamps.scanResult = StampRallyThanksCardResult(alreadyRedeemed: false, redeemedAt: DateTime.utc(2026, 11, 13));
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        stampRallyRepositoryProvider.overrideWithValue(stamps),
        sponsorRepositoryProvider.overrideWithValue(_FakeSponsorRepository()),
        appleSignInAvailabilityProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(subject('/s/$_token', container: container));
    await tester.pumpAndSettle();

    expect(find.byType(SignInCard), findsOneWidget);
    expect(container.read(pendingStampRallyTokenProvider)?.token, _token);
    expect(stamps.scannedTokens, isEmpty);

    await auth.signInWithGoogle();
    await tester.pumpAndSettle();

    expect(find.text('サンクスカードを受け取れます'), findsOneWidget);
    expect(stamps.scannedTokens, [_token]);
    expect(container.read(pendingStampRallyTokenProvider), isNull);
  });
}

final class _FakeSponsorRepository implements SponsorRepository {
  @override
  Stream<List<Sponsor>> watchAll({bool excludeUnsupportedTiers = false}) => Stream.value([
    _sponsor('s1', 'スポンサーA', 'flutter'),
    _sponsor('s2', 'スポンサーB', 'unknown-slug'),
    _sponsor('s3', '対象外', null),
  ]);

  @override
  Future<void> save(Sponsor sponsor) async {}

  @override
  Future<void> delete(String id) async {}
}

Sponsor _sponsor(String id, String name, String? slug) => Sponsor(
  id: id,
  name: LocaleMap(ja: name, en: name),
  description: const LocaleMap(ja: '', en: ''),
  tier: SponsorTier.gold,
  slug: slug,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
