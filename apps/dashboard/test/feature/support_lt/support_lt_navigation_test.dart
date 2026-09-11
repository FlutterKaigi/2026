import 'package:dashboard/core/router/paths.dart';
import 'package:dashboard/core/router/router.dart';
import 'package:dashboard/core/ui/scaffold_with_nav.dart';
import 'package:dashboard/feature/auth/data/provider/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('typed route points to the support LT page', () {
    expect(const SupportLtRoute().location, AppPaths.supportLt);
  });

  Future<GoRouter> showNav(WidgetTester tester, Size size, {double textScale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (_, _, child) => ScaffoldWithNav(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, _) => const Text('Home content')),
            GoRoute(path: '/support-lt', builder: (_, _) => const Text('Support LT content')),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authStateProvider.overrideWith((_) => Stream.value(null))],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('wide navigation can scroll to support LT on a short window', (tester) async {
    await showNav(tester, const Size(1000, 450));

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('応援LT'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('応援LT'));
    await tester.pumpAndSettle();

    expect(find.text('Support LT content'), findsOneWidget);
    expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow navigation opens a drawer and closes it after choosing support LT', (tester) async {
    await showNav(tester, const Size(375, 700));

    expect(find.byType(NavigationRail), findsNothing);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('応援LT'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('応援LT'));
    await tester.pumpAndSettle();

    expect(find.text('Support LT content'), findsOneWidget);
    expect(tester.state<ScaffoldState>(find.byType(Scaffold)).isDrawerOpen, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('browser-sized navigation stays usable with fractional text metrics', (tester) async {
    await showNav(tester, const Size(1280, 900), textScale: 1.15);

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('応援LT'));
    await tester.tap(find.text('応援LT'));
    await tester.pumpAndSettle();

    expect(find.text('Support LT content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
