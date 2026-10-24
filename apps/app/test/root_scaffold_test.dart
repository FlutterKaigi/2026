import 'package:app/core/ui/root_scaffold.dart';
import 'package:app/core/ui/widget/vertical_bar_safe_area.dart';
import 'package:app/core/util/reserved_regions.dart';
import 'package:app/core/util/vertical_bar_edge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _pageKey = ValueKey('page');
final _iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

/// Sizes the test view like an iPhone Duo display, in logical pixels.
void _setView(WidgetTester tester, Size size, {double left = 0, double top = 0, double right = 0, double bottom = 0}) {
  const ratio = 3.0;
  tester.view.devicePixelRatio = ratio;
  tester.view.physicalSize = size * ratio;
  tester.view.padding = FakeViewPadding(
    left: left * ratio,
    top: top * ratio,
    right: right * ratio,
    bottom: bottom * ratio,
  );
  addTearDown(tester.view.reset);
}

Future<void> _pumpShell(WidgetTester tester) async {
  Widget page(String label) => Scaffold(key: label == 'One' ? _pageKey : null, body: Text('$label page'));
  final router = GoRouter(
    initialLocation: '/one',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => RootScaffold(
          navigationShell: navigationShell,
          destinations: const [
            RootDestination(icon: Icons.event_outlined, label: 'One'),
            RootDestination(icon: Icons.map_outlined, label: 'Two'),
          ],
        ),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/one', builder: (context, state) => page('One'))],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/two', builder: (context, state) => page('Two'))],
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  group('VerticalBarEdge', () {
    testWidgets('finds the side holding the bar on iOS', (tester) async {
      expect(VerticalBarEdge.fromPadding(const EdgeInsets.only(right: 84, bottom: 34)), VerticalBarEdge.right);
      expect(VerticalBarEdge.fromPadding(const EdgeInsets.only(left: 84, bottom: 34)), VerticalBarEdge.left);
      // Portrait iPhones, and landscape iPhones with insets on both sides.
      expect(VerticalBarEdge.fromPadding(const EdgeInsets.only(top: 62, bottom: 34)), isNull);
      expect(VerticalBarEdge.fromPadding(const EdgeInsets.only(left: 62, right: 62, bottom: 21)), isNull);
      expect(VerticalBarEdge.fromPadding(const EdgeInsets.only(top: 24, right: 84)), isNull);
    }, variant: _iOS);

    testWidgets('is never reported outside iOS', (tester) async {
      expect(VerticalBarEdge.fromPadding(const EdgeInsets.only(right: 48)), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });

  group('RootScaffold', () {
    testWidgets('moves the tabs into a vertical bar on the right', (tester) async {
      _setView(tester, const Size(466, 678), right: 84, bottom: 34);
      await _pumpShell(tester);

      expect(find.byType(NavigationBar), findsNothing);
      final rail = tester.getRect(find.byType(NavigationRail));
      expect(rail.left, 382);
      expect(rail.right, 466);
      final page = tester.getRect(find.byKey(_pageKey));
      expect(page.left, 0);
      expect(page.right, 382);

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(find.text('Two page'), findsOneWidget);
    }, variant: _iOS);

    testWidgets('moves the tabs into a vertical bar on the left', (tester) async {
      _setView(tester, const Size(678, 466), left: 84, bottom: 34);
      await _pumpShell(tester);

      final rail = tester.getRect(find.byType(NavigationRail));
      expect(rail.left, 0);
      expect(rail.right, 84);
      final page = tester.getRect(find.byKey(_pageKey));
      expect(page.left, 84);
      expect(page.right, 678);
    }, variant: _iOS);

    group('with the camera reported by UIKit', () {
      void reportOcclusions(WidgetTester tester, List<Rect> rects) {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(reservedRegionsChannel, (call) async {
          return [
            for (final rect in rects)
              {'x': rect.left, 'y': rect.top, 'width': rect.width, 'height': rect.height, 'active': true},
          ];
        });
        addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(reservedRegionsChannel, null));
      }

      testWidgets('keeps the tabs below the camera and status icons at the top', (tester) async {
        _setView(tester, const Size(466, 678), right: 84, bottom: 34);
        reportOcclusions(tester, [const Rect.fromLTWH(382, 0, 84, 174)]);
        await _pumpShell(tester);

        final rail = tester.getRect(find.byType(NavigationRail));
        expect(rail.top, 174);
        expect(rail.bottom, 678 - 34);
      }, variant: _iOS);

      testWidgets('keeps the tabs above the camera at the bottom', (tester) async {
        // The closed device turned so that the camera is at the bottom right.
        _setView(tester, const Size(678, 466), right: 84, bottom: 34);
        reportOcclusions(tester, [const Rect.fromLTWH(594, 384, 84, 82)]);
        await _pumpShell(tester);

        final rail = tester.getRect(find.byType(NavigationRail));
        expect(rail.top, 0);
        expect(rail.bottom, 384);
      }, variant: _iOS);

      testWidgets('ignores occlusions outside the vertical bar', (tester) async {
        _setView(tester, const Size(951, 669), right: 84, bottom: 34);
        reportOcclusions(tester, [const Rect.fromLTWH(400, 0, 60, 60)]);
        await _pumpShell(tester);

        final rail = tester.getRect(find.byType(NavigationRail));
        expect(rail.top, 0);
        expect(rail.bottom, 669 - 34);
      }, variant: _iOS);
    });

    testWidgets('keeps the navigation bar without a vertical bar', (tester) async {
      _setView(tester, const Size(402, 874), top: 62, bottom: 34);
      await _pumpShell(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(tester.getRect(find.byKey(_pageKey)).width, 402);
    }, variant: _iOS);
  });

  group('VerticalBarSafeArea', () {
    Future<Rect> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VerticalBarSafeArea(child: Scaffold(key: _pageKey)),
        ),
      );
      return tester.getRect(find.byKey(_pageKey));
    }

    testWidgets('keeps the page out of the vertical bar', (tester) async {
      _setView(tester, const Size(466, 678), right: 84, bottom: 34);
      expect(await pumpPage(tester), const Rect.fromLTRB(0, 0, 382, 678));
    }, variant: _iOS);

    testWidgets('leaves the page alone without a vertical bar', (tester) async {
      _setView(tester, const Size(402, 874), top: 62, bottom: 34);
      expect(await pumpPage(tester), const Rect.fromLTRB(0, 0, 402, 874));
    }, variant: _iOS);
  });
}
