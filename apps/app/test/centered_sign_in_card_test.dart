import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/auth/data/provider/auth_repository.dart';
import 'package:app/feature/auth/ui/widget/centered_sign_in_card.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/exchange/ui/page/exchange_home_page.dart';
import 'package:app/feature/exchange/ui/page/exchange_list_page.dart';
import 'package:app/feature/exchange/ui/page/exchange_scan_page.dart';
import 'package:app/feature/exchange/ui/page/exchange_share_link_page.dart';
import 'package:app/feature/mission/ui/page/mission_page.dart';
import 'package:app/feature/profile/ui/page/profile_edit_page.dart';
import 'package:app/feature/quiz/ui/page/quiz_event_list_page.dart';
import 'package:app/feature/quiz/ui/page/quiz_page.dart';
import 'package:app/feature/sns_post/ui/page/sns_post_page.dart';
import 'package:app/feature/stamp_rally/ui/page/stamp_rally_link_page.dart';
import 'package:app/feature/stamp_rally/ui/page/stamp_rally_page.dart';
import 'package:app/feature/stamp_rally/ui/page/stamp_rally_scan_page.dart';
import 'package:app/feature/support_lt/ui/page/support_lt_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_auth_repository.dart';

final _exchangeToken =
    'v1.other-uid.${DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000}.deadbeef';

final _signedOutPages = <({String name, Widget page, String description})>[
  (name: 'mission', page: const MissionPage(), description: 'ミッションの達成状況を見るにはサインインしてください'),
  (name: 'SNS post', page: const SnsPostPage(), description: 'SNS投稿を登録するにはサインインしてください'),
  (name: 'Support LT', page: const SupportLtPage(), description: '応援LTに参加登録するには\nサインインしてください'),
  (name: 'Support LT link', page: const SupportLtPage(linkCode: '123456'), description: '応援LTに参加登録するには\nサインインしてください'),
  (name: 'stamp rally', page: const StampRallyPage(), description: 'スタンプを集めるにはサインインしてください'),
  (name: 'stamp rally scan', page: const StampRallyScanPage(), description: 'スタンプを集めるにはサインインしてください'),
  (name: 'stamp rally link', page: StampRallyLinkPage(token: 'ab' * 32), description: 'スタンプを集めるにはサインインしてください'),
  (name: 'quiz', page: const QuizPage(eventId: 'event'), description: 'クイズ大会に参加するにはサインインしてください'),
  (name: 'quiz list', page: const QuizEventListPage(), description: 'クイズ大会に参加するにはサインインしてください'),
  (name: 'exchange home', page: const ExchangeHomePage(), description: 'サインインすると自分のQRコードを表示できます'),
  (name: 'exchange scan', page: const ExchangeScanPage(), description: 'サインインすると自分のQRコードを表示できます'),
  (name: 'exchange list', page: const ExchangeListPage(), description: 'サインインすると自分のQRコードを表示できます'),
  (name: 'share link', page: ExchangeShareLinkPage(token: _exchangeToken), description: 'サインインすると相手とプロフィールを交換できます'),
  (name: 'profile edit', page: const ProfileEditPage(), description: 'プロフィールを作成するにはサインインしてください'),
];

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  Future<void> pumpSignedOut(WidgetTester tester, Widget page, {required Size size, double textScale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => page)],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepository),
            appleSignInAvailabilityProvider.overrideWithValue(false),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (:name, :page, :description) in _signedOutPages) {
    testWidgets('$name centers the sign-in card in the signed-out body', (tester) async {
      await pumpSignedOut(tester, page, size: const Size(400, 1000));

      final centered = find.byType(CenteredSignInCard);
      expect(find.descendant(of: centered, matching: find.text(description)), findsOneWidget);
      final bodyTop = tester.getBottomLeft(find.byType(AppBar)).dy;
      final bodyBottom = tester.getBottomLeft(find.byType(Scaffold)).dy;
      expect(tester.getCenter(find.byType(SignInCard)).dy, moreOrLessEquals((bodyTop + bodyBottom) / 2, epsilon: 1));
    });

    testWidgets('$name scrolls to every sign-in option on a small screen at 2x text', (tester) async {
      await pumpSignedOut(tester, page, size: const Size(320, 568), textScale: 2);

      expect(tester.takeException(), isNull);
      final emailOption = find.text('メールアドレスでサインイン');
      await tester.ensureVisible(emailOption);
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(emailOption).dy, lessThanOrEqualTo(568));
    });
  }
}
