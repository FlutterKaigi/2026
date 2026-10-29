import 'package:data/data.dart';
import 'package:data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:stamp_rally_viewer/app.dart';
import 'package:stamp_rally_viewer/providers.dart';

import 'fake_repositories.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeStampRallyRepository stamps;
  late FakeSponsorRepository sponsors;

  setUp(() {
    auth = FakeAuthRepository();
    stamps = FakeStampRallyRepository();
    sponsors = FakeSponsorRepository();
  });

  tearDown(() async {
    await auth.dispose();
    await stamps.dispose();
  });

  Widget subject() => ProviderScope(
    retry: (_, _) => null,
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      stampRallyRepositoryProvider.overrideWithValue(stamps),
      sponsorRepositoryProvider.overrideWithValue(sponsors),
    ],
    child: const StampRallyViewerApp(),
  );

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  for (final anonymous in [false, true]) {
    testWidgets('${anonymous ? 'anonymous' : 'signed-out'} visitors cannot subscribe to private histories', (
      tester,
    ) async {
      if (anonymous) auth.setUser(FakeUser(uid: 'anonymous', isAnonymous: true));

      await tester.pumpWidget(subject());
      await tester.pumpAndSettle();

      expect(find.text('Google でログイン'), findsOneWidget);
      expect(find.text('ログアウト'), findsNothing);
      expect(stamps.watchedUids, isEmpty);
      expect(sponsors.excludesUnsupportedTiers, isEmpty);
    });
  }

  testWidgets('Google login opens only the signed-in attendee history', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tapText(tester, 'Google でログイン');

    expect(auth.calls, ['google']);
    expect(stamps.watchedUids, ['attendee']);
    expect(find.text('attendee@example.com'), findsOneWidget);
    expect(find.text('Google でログイン'), findsNothing);
  });

  testWidgets('email login trims the address while preserving the password', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '  attendee@example.com  ');
    await tester.enterText(find.byType(TextFormField).at(1), ' password with spaces ');

    await tapText(tester, 'メールアドレスでログイン');

    expect(auth.calls, ['email']);
    expect(auth.lastEmail, 'attendee@example.com');
    expect(auth.lastPassword, ' password with spaces ');
    expect(stamps.watchedUids, ['attendee']);
  });

  testWidgets('a failed login explains the error and permits retry without reading cards', (tester) async {
    auth.nextError = FirebaseAuthException(code: 'popup-blocked');
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tapText(tester, 'Google でログイン');

    expect(find.text('ブラウザのポップアップを許可して、再度ログインしてください。'), findsOneWidget);
    expect(stamps.watchedUids, isEmpty);

    await tapText(tester, 'Google でログイン');

    expect(auth.calls, ['google', 'google']);
    expect(stamps.watchedUids, ['attendee']);
  });

  testWidgets('password reset sends the normalized address without signing in', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '  attendee@example.com  ');

    await tapText(tester, 'パスワードを忘れた方');

    expect(auth.lastResetEmail, 'attendee@example.com');
    expect(find.textContaining('再設定可能なアカウントの場合'), findsOneWidget);
    expect(stamps.watchedUids, isEmpty);
  });

  testWidgets('history names sponsors and preserves removed sponsors and prizes with JST timestamps', (tester) async {
    auth.setUser(FakeUser());
    stamps.cards['attendee'] = StampRallyCard(
      stamps: {'s1': DateTime.utc(2026, 11, 13, 0, 30), 'removed': DateTime.utc(2026, 11, 13, 1)},
      rewardsRedeemedAt: {1: DateTime.utc(2026, 11, 13, 2), 4: DateTime.utc(2026, 11, 13, 3)},
      thanksCardRedeemedAt: DateTime.utc(2026, 11, 13, 4),
    );

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.text('スポンサー A'), findsOneWidget);
    expect(find.text('スポンサー情報なし（removed）'), findsOneWidget);
    expect(find.text('獲得済み · 2026/11/13 09:30'), findsOneWidget);
    expect(find.text('獲得済み · 2026/11/13 10:00'), findsOneWidget);
    expect(find.text('景品 #4'), findsOneWidget);
    expect(find.text('過去の交換記録'), findsOneWidget);
    expect(find.text('交換済み · 2026/11/13 11:00'), findsOneWidget);
    expect(find.text('交換済み · 2026/11/13 12:00'), findsOneWidget);
    expect(find.text('交換済み · 2026/11/13 13:00'), findsOneWidget);
    expect(find.text('交換可能・未交換'), findsOneWidget);
    expect(sponsors.excludesUnsupportedTiers, [true]);

    await tapText(tester, '未獲得 1');

    expect(find.text('スポンサー B'), findsOneWidget);
    expect(find.text('スポンサー A'), findsNothing);
    expect(find.text('スポンサー情報なし（removed）'), findsNothing);
    expect(find.text('景品 #4'), findsOneWidget);
  });

  testWidgets('an attendee with no records sees the empty state and unredeemed rewards', (tester) async {
    auth.setUser(FakeUser());

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.textContaining('まだスタンプを獲得していません。'), findsOneWidget);
    expect(find.text('獲得済み 0'), findsOneWidget);
    expect(find.text('未獲得 2'), findsOneWidget);
    expect(find.text('交換可能・未交換'), findsNothing);
    expect(find.textContaining('交換済み ·'), findsNothing);
    expect(find.text('未交換'), findsNWidgets(4));
  });

  testWidgets('a failed card stream shows an error and reload creates a fresh subscription', (tester) async {
    auth.setUser(FakeUser());
    stamps.cardErrors['attendee'] = StateError('backend unavailable');

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.textContaining('履歴を読み込めませんでした。'), findsOneWidget);
    expect(find.textContaining('まだスタンプを獲得していません。'), findsNothing);

    stamps.cardErrors.clear();
    stamps.cards['attendee'] = StampRallyCard(stamps: {'s1': DateTime.utc(2026, 11, 13)}, rewardsRedeemedAt: {});
    await tapText(tester, '再読み込み');

    expect(stamps.watchedUids, ['attendee', 'attendee']);
    expect(find.text('スポンサー A'), findsOneWidget);
    expect(find.textContaining('履歴を読み込めませんでした。'), findsNothing);
  });

  testWidgets('live updates refresh the same account without another card subscription', (tester) async {
    auth.setUser(FakeUser());
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    stamps.emitCard(
      'attendee',
      StampRallyCard(stamps: {'s1': DateTime.utc(2026, 11, 13)}, rewardsRedeemedAt: {1: DateTime.utc(2026, 11, 13, 1)}),
    );
    await tester.pumpAndSettle();

    expect(find.text('スポンサー A'), findsOneWidget);
    expect(find.text('交換済み · 2026/11/13 10:00'), findsOneWidget);
    expect(stamps.watchedUids, ['attendee']);
  });

  testWidgets('switching accounts hides old history while loading, and sign-out cancels private streams', (
    tester,
  ) async {
    auth.setUser(FakeUser(uid: 'first', email: 'first@example.com'));
    stamps.cards['first'] = StampRallyCard(stamps: {'s1': DateTime.utc(2026, 11, 13)}, rewardsRedeemedAt: {});
    stamps.pendingCards.add('second');
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(find.text('スポンサー A'), findsOneWidget);

    auth.setUser(FakeUser(uid: 'second', email: 'second@example.com'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('スポンサー A'), findsNothing);
    expect(find.text('first@example.com'), findsNothing);
    expect(stamps.watchedUids, ['first', 'second']);
    expect(stamps.cancelledUids, contains('first'));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    stamps.emitCard('first', StampRallyCard(stamps: {'removed': DateTime.utc(2026, 11, 13)}, rewardsRedeemedAt: {}));
    stamps.emitCard('second', StampRallyCard(stamps: {'s2': DateTime.utc(2026, 11, 13)}, rewardsRedeemedAt: {}));
    await tester.pumpAndSettle();

    expect(find.text('second@example.com'), findsOneWidget);
    expect(find.text('スポンサー B'), findsOneWidget);
    expect(find.text('スポンサー A'), findsNothing);
    expect(find.text('スポンサー情報なし（removed）'), findsNothing);

    await tapText(tester, 'ログアウト');

    expect(find.text('Google でログイン'), findsOneWidget);
    expect(find.text('スポンサー B'), findsNothing);
    expect(stamps.cancelledUids, contains('second'));
    expect(auth.calls, ['signOut']);
  });

  testWidgets('login and history fit a 360px screen at large text scale', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    auth.setUser(FakeUser(email: 'a-long-attendee-email-address@example.com'));
    stamps.cards['attendee'] = StampRallyCard(stamps: {'s1': DateTime.utc(2026, 11, 13)}, rewardsRedeemedAt: {});
    await tester.pumpAndSettle();

    expect(find.text('スポンサー A'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('景品 #2'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
