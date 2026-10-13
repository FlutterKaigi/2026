import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/push_notification/data/notification_route.dart';
import 'package:app/feature/push_notification/data/push_notification_provider.dart';
import 'package:app/feature/push_notification/data/push_notification_repository.dart';
import 'package:app/feature/push_notification/ui/push_notification_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fake_push_notification_repository.dart';

void main() {
  late FakePushNotificationRepository repository;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    repository = FakePushNotificationRepository();
  });
  tearDown(() => repository.dispose());

  Future<({GoRouter router, Future<void> Function() pumpApp})> pumpListener(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('最初の画面')),
        ),
        GoRoute(
          path: '/news',
          builder: (_, _) => const Scaffold(body: Text('ニュース一覧')),
        ),
      ],
    );
    addTearDown(router.dispose);

    Future<void> pumpApp() async {
      await tester.pumpWidget(
        TranslationProvider(
          child: ProviderScope(
            overrides: [
              pushNotificationRepositoryProvider.overrideWithValue(repository),
              routerProvider.overrideWithValue(router),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              locale: AppLocale.ja.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (context, child) => PushNotificationListener(child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpApp();
    return (router: router, pumpApp: pumpApp);
  }

  String currentPath(GoRouter router) => router.routeInformationProvider.value.uri.path;

  testWidgets('shows a foreground notification whose Open action goes to its route', (tester) async {
    final (:router, pumpApp: _) = await pumpListener(tester);

    repository.receive(
      ForegroundNotification(title: '開場のお知らせ', body: '受付を開始しました', route: parseNotificationRoute('/news')),
    );
    await tester.pumpAndSettle();

    expect(find.text('開場のお知らせ'), findsOneWidget);
    expect(find.text('受付を開始しました'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    expect(currentPath(router), '/news');
    expect(find.text('ニュース一覧'), findsOneWidget);
  });

  testWidgets('shows a notification without a route and without an Open action', (tester) async {
    await pumpListener(tester);

    repository.receive(const ForegroundNotification(title: 'お知らせ', body: '本文'));
    await tester.pumpAndSettle();

    expect(find.text('お知らせ'), findsOneWidget);
    expect(find.byType(SnackBarAction), findsNothing);
  });

  testWidgets('replaces the shown notification with a newer one', (tester) async {
    await pumpListener(tester);

    repository.receive(const ForegroundNotification(body: '1件目'));
    await tester.pumpAndSettle();
    repository.receive(const ForegroundNotification(body: '2件目'));
    await tester.pumpAndSettle();

    expect(find.text('1件目'), findsNothing);
    expect(find.text('2件目'), findsOneWidget);
  });

  testWidgets('closes a notification with an Open action after ten seconds', (tester) async {
    await pumpListener(tester);

    repository.receive(ForegroundNotification(body: '本文', route: parseNotificationRoute('/news')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    expect(find.text('本文'), findsNothing, reason: 'a snack bar that stays would hold back those of every screen');
  });

  testWidgets('goes to the route of a tapped notification', (tester) async {
    final (:router, pumpApp: _) = await pumpListener(tester);

    repository.open(parseNotificationRoute('/news')!);
    await tester.pumpAndSettle();

    expect(currentPath(router), '/news');
    expect(find.text('ニュース一覧'), findsOneWidget);
  });

  testWidgets('asks for the permission once after the first frame, not on rebuilds', (tester) async {
    final (router: _, :pumpApp) = await pumpListener(tester);
    expect(repository.permissionRequestCount, 1);

    await pumpApp();

    expect(repository.permissionRequestCount, 1);
  });

  testWidgets('stops listening when removed', (tester) async {
    await pumpListener(tester);
    expect(repository.hasListener, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(repository.hasListener, isFalse);
  });
}
