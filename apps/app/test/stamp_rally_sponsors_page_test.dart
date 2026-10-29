import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:app/feature/stamp_rally/data/stamp_rally_provider.dart';
import 'package:app/feature/stamp_rally/ui/page/stamp_rally_sponsors_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';
import 'fake_stamp_rally_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeStampRallyRepository stamps;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    auth = FakeAuthRepository(initialUser: FakeUser(uid: 'me'));
    stamps = FakeStampRallyRepository(sponsorIds: {'s1', 's2'});
  });

  tearDown(() => auth.dispose());

  Widget subject({
    AppLocale locale = AppLocale.ja,
    Stream<StampRallyCard> Function(String uid)? watchCard,
    Stream<Set<String>> Function()? watchSponsorIds,
  }) {
    LocaleSettings.setLocaleSync(locale);
    return ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        stampRallyRepositoryProvider.overrideWithValue(stamps),
        sponsorListProvider.overrideWith((ref) => Stream.value([_sponsor('s1', 'スポンサーA'), _sponsor('s2', 'スポンサーB')])),
        appleSignInAvailabilityProvider.overrideWithValue(false),
        if (watchCard != null) stampRallyCardProvider.overrideWith((ref, uid) => watchCard(uid)),
        if (watchSponsorIds != null) stampRallySponsorIdsProvider.overrideWith((ref) => watchSponsorIds()),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          locale: locale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const StampRallySponsorsPage(),
        ),
      ),
    );
  }

  testWidgets('identifies collected and uncollected sponsors with collection time', (tester) async {
    stamps.card = StampRallyCard(rewardsRedeemedAt: const {}, stamps: {'s1': DateTime(2026, 11, 13, 10, 30)});
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    final collected = find.byKey(const ValueKey('stamp-sponsor-s1'));
    final uncollected = find.byKey(const ValueKey('stamp-sponsor-s2'));
    expect(find.descendant(of: collected, matching: find.text('スポンサーA')), findsOneWidget);
    expect(find.descendant(of: collected, matching: find.text('獲得済み')), findsOneWidget);
    expect(find.descendant(of: collected, matching: find.text('獲得日時 11/13 10:30')), findsOneWidget);
    expect(find.descendant(of: uncollected, matching: find.text('スポンサーB')), findsOneWidget);
    expect(find.descendant(of: uncollected, matching: find.text('未獲得')), findsOneWidget);
    expect(find.text('2個中1個のスタンプを獲得'), findsOneWidget);
  });

  testWidgets('retains stamps from disabled and missing sponsors without counting them twice', (tester) async {
    stamps.sponsorIds = {'s2'};
    stamps.card = StampRallyCard(
      rewardsRedeemedAt: const {},
      stamps: {
        's1': DateTime(2026, 11, 13),
        's2': DateTime(2026, 11, 13),
        'removed': DateTime(2026, 11, 13),
      },
    );
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.text('スポンサーA'), findsOneWidget);
    expect(find.text('スポンサーB'), findsOneWidget);
    expect(find.text('スポンサー（removed）'), findsOneWidget);
    expect(find.text('獲得済み'), findsNWidgets(3));
    expect(find.text('3個中3個のスタンプを獲得'), findsOneWidget);
  });

  testWidgets('waits for sign-in before loading private stamps and clears them on sign-out', (tester) async {
    auth.dispose();
    auth = FakeAuthRepository();
    final watchedUsers = <String>[];
    await tester.pumpWidget(
      subject(
        watchCard: (uid) {
          watchedUsers.add(uid);
          return Stream.value(StampRallyCard(rewardsRedeemedAt: const {}, stamps: {'s1': DateTime(2026, 11, 13)}));
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SignInCard), findsOneWidget);
    expect(watchedUsers, isEmpty);
    expect(find.text('スポンサーA'), findsNothing);

    await auth.signInWithGoogle();
    await tester.pumpAndSettle();

    expect(watchedUsers, ['fake-uid']);
    expect(find.byType(SignInCard), findsNothing);
    expect(find.text('スポンサーA'), findsOneWidget);
    expect(find.text('獲得済み'), findsOneWidget);

    await auth.signOut();
    await tester.pumpAndSettle();

    expect(find.byType(SignInCard), findsOneWidget);
    expect(find.text('スポンサーA'), findsNothing);
    expect(find.text('獲得済み'), findsNothing);
  });

  testWidgets('shows loading and updates collection statuses from the card stream', (tester) async {
    final cards = StreamController<StampRallyCard>();
    addTearDown(cards.close);
    await tester.pumpWidget(subject(watchCard: (_) => cards.stream));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('未獲得'), findsNothing);

    cards.add(StampRallyCard.empty);
    await tester.pumpAndSettle();
    expect(find.text('未獲得'), findsNWidgets(2));

    cards.add(StampRallyCard(rewardsRedeemedAt: const {}, stamps: {'s2': DateTime(2026, 11, 13)}));
    await tester.pumpAndSettle();
    expect(find.text('未獲得'), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const ValueKey('stamp-sponsor-s2')), matching: find.text('獲得済み')),
      findsOneWidget,
    );
  });

  testWidgets('reports failed data loading and recovers on retry', (tester) async {
    var fail = true;
    await tester.pumpWidget(
      subject(
        watchSponsorIds: () => fail ? Stream.error(Exception('offline')) : Stream.value({'s1'}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.text('未獲得'), findsNothing);

    fail = false;
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorView), findsNothing);
    expect(find.text('スポンサーA'), findsOneWidget);
  });

  testWidgets('shows an empty state in English', (tester) async {
    stamps.sponsorIds = {};
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
    await tester.pumpWidget(subject(locale: AppLocale.en));
    await tester.pumpAndSettle();

    expect(find.text('Stamps by sponsor'), findsOneWidget);
    expect(find.text('No participating sponsors yet'), findsOneWidget);
    expect(find.text('0 of 0 stamps collected'), findsOneWidget);
  });

  testWidgets('fits narrow screens with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    stamps.card = StampRallyCard(rewardsRedeemedAt: const {}, stamps: {'s1': DateTime(2026, 11, 13)});
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Sponsor _sponsor(String id, String name) => Sponsor(
  id: id,
  name: LocaleMap(ja: name, en: name),
  description: const LocaleMap(ja: '', en: ''),
  tier: SponsorTier.gold,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
