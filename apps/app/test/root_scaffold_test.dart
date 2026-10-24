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

/// Counts how many times its state is created, to catch pages that are
/// rebuilt from scratch.
class _StateCounter extends StatefulWidget {
  const _StateCounter(this.onCreate);

  final VoidCallback onCreate;

  @override
  State<_StateCounter> createState() => _StateCounterState();
}

class _StateCounterState extends State<_StateCounter> {
  @override
  void initState() {
    super.initState();
    widget.onCreate();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

Future<void> _pumpShell(WidgetTester tester, {Widget? firstPage}) async {
  Widget page(String label) => Scaffold(key: label == 'One' ? _pageKey : null, body: firstPage ?? Text('$label page'));
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

      testWidgets('asks again when the view is laid out without a new size', (tester) async {
        _setView(tester, const Size(678, 466), right: 84, bottom: 34);
        final occlusions = [const Rect.fromLTWH(594, 0, 84, 82)];
        reportOcclusions(tester, occlusions);
        await _pumpShell(tester);
        expect(tester.getRect(find.byType(NavigationRail)).top, 82);

        occlusions[0] = const Rect.fromLTWH(594, 384, 84, 82);
        // iOS reports the same metrics again after laying out the view.
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();

        final rail = tester.getRect(find.byType(NavigationRail));
        expect(rail.top, 0);
        expect(rail.bottom, 384);
      }, variant: _iOS);

      testWidgets('asks again when the app comes back', (tester) async {
        _setView(tester, const Size(678, 466), right: 84, bottom: 34);
        final occlusions = [const Rect.fromLTWH(594, 0, 84, 82)];
        reportOcclusions(tester, occlusions);
        await _pumpShell(tester);

        occlusions[0] = const Rect.fromLTWH(594, 384, 84, 82);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

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

    testWidgets('keeps the page state when the vertical bar comes and goes', (tester) async {
      var created = 0;
      // The inner display: portrait has no vertical bar, landscape does.
      _setView(tester, const Size(669, 951), top: 24, bottom: 20);
      await _pumpShell(tester, firstPage: _StateCounter(() => created++));

      _setView(tester, const Size(951, 669), right: 84, bottom: 34);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      _setView(tester, const Size(669, 951), top: 24, bottom: 20);
      await tester.pumpAndSettle();

      expect(created, 1);
    }, variant: _iOS);

    testWidgets('leaves the keyboard to the page once with a vertical bar', (tester) async {
      _setView(tester, const Size(678, 466), right: 84, bottom: 34);
      tester.view.viewInsets = const FakeViewPadding(bottom: 216 * 3.0);
      const content = ValueKey('content');
      await _pumpShell(tester, firstPage: const SizedBox.expand(key: content));

      // Only the page's own Scaffold makes room for the keyboard.
      expect(tester.getRect(find.byKey(content)).height, 466 - 216);
    }, variant: _iOS);

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

    testWidgets('keeps the page state when the vertical bar comes and goes', (tester) async {
      var created = 0;
      _setView(tester, const Size(669, 951), top: 24, bottom: 20);
      await tester.pumpWidget(
        MaterialApp(home: VerticalBarSafeArea(child: _StateCounter(() => created++))),
      );

      _setView(tester, const Size(951, 669), right: 84, bottom: 34);
      await tester.pump();
      _setView(tester, const Size(669, 951), top: 24, bottom: 20);
      await tester.pump();

      expect(created, 1);
    }, variant: _iOS);

    testWidgets('leaves the page alone without a vertical bar', (tester) async {
      _setView(tester, const Size(402, 874), top: 62, bottom: 34);
      expect(await pumpPage(tester), const Rect.fromLTRB(0, 0, 402, 874));
    }, variant: _iOS);
  });
}
