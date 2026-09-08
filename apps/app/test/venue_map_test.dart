import 'dart:convert';

import 'package:app/core/designsystem/theme/app_theme.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/venue_map/data/venue_floor_plan.dart';
import 'package:app/feature/venue_map/provider/venue_map_view_mode.dart';
import 'package:app/feature/venue_map/ui/page/venue_map_page.dart';
import 'package:app/feature/venue_map/ui/widget/venue_map_2d_controller.dart';
import 'package:app/feature/venue_map/ui/widget/venue_map_2d_view.dart';
import 'package:app/feature/venue_map/ui/widget/venue_map_3d_view.dart';
import 'package:app/feature/venue_map/ui/widget/venue_place_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late VenueFloorPlan plan;
  setUpAll(() async {
    plan = VenueFloorPlan.fromJson(
      Map<String, Object?>.from(jsonDecode(await rootBundle.loadString('assets/venue_map/floor_plan.json')) as Map),
    );
  });

  test('view preference defaults to 2D and survives a new provider container', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    expect(container.read(venueMapViewModeProvider), VenueMapViewMode.twoD);
    await container.read(venueMapViewModeProvider.notifier).set(VenueMapViewMode.threeD);
    container.dispose();
    final restarted = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(restarted.dispose);
    expect(restarted.read(venueMapViewModeProvider), VenueMapViewMode.threeD);
    await restarted.read(venueMapViewModeProvider.notifier).set(VenueMapViewMode.twoD);
    expect(prefs.getString(VenueMapViewModeNotifier.preferencesKey), 'twoD');
  });

  test('invalid stored mode falls back to 2D', () async {
    SharedPreferences.setMockInitialValues({VenueMapViewModeNotifier.preferencesKey: 'obsolete'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    expect(container.read(venueMapViewModeProvider), VenueMapViewMode.twoD);
  });

  test('floor plan keeps the named halls in the correct rooms and is searchable in both languages', () {
    expect(plan.find('main_hall_a')!.name('ja'), 'JTCC HALL');
    expect(plan.find('main_hall_b')!.name('ja'), 'UPSIDER HALL');
    expect(plan.find('grand_hall_a')!.name('ja'), 'Cupertino');
    expect(plan.find('grand_hall_b')!.name('ja'), 'Material');
    expect(plan.find('grand_hall_a')!.anchor.dy, lessThan(plan.find('grand_hall_b')!.anchor.dy));
    expect(plan.find('mens_wc')!.matches('restroom'), isTrue);
    expect(plan.find('exhibition_hall_2')!.matches('ホワイエ 2'), isTrue);
    expect(plan.find('main_hall_a')!.matches('メインホール'), isTrue);
  });

  test('camera fits both orientations, focuses once, and preserves a subsequent pan on resize', () {
    final camera = VenueMap2DController();
    addTearDown(camera.dispose);
    camera.layout(const Size(360, 540), plan);
    expect(camera.rotated, isTrue);
    for (final corner in [plan.bounds.topLeft, plan.bounds.bottomRight]) {
      expect((Offset.zero & camera.viewport).contains(camera.project(corner)), isTrue);
      expect((camera.unproject(camera.project(corner)) - corner).distance, lessThan(.001));
    }
    final place = plan.find('grand_hall_a')!;
    camera.focus(place);
    expect((camera.project(place.anchor) - camera.viewport.center(Offset.zero)).distance, lessThan(.001));
    camera.transform(nextScale: camera.scale, focalPoint: const Offset(100, 130), worldAnchor: place.anchor);
    final before = camera.unproject(camera.viewport.center(Offset.zero));
    final beforeScale = camera.scale;
    camera.layout(const Size(600, 400), plan);
    expect(camera.scale, beforeScale);
    expect((camera.unproject(camera.viewport.center(Offset.zero)) - before).distance, lessThan(.001));
    camera.rotate();
    expect(camera.rotated, isFalse);
    for (final corner in [plan.bounds.topLeft, plan.bounds.bottomRight]) {
      expect((Offset.zero & camera.viewport).contains(camera.project(corner)), isTrue);
    }
  });

  test('3D selection updates never issue a camera command; an explicit selection focuses once', () {
    final controller = VenueMap3DController();
    final commands = <Map<String, Object?>>[];
    controller.configure({'action': 'configure', 'selected': null});
    controller.focus('grand_hall_a');
    controller.connect(commands.add);
    expect(commands.map((c) => c['action']), ['configure', 'focus']);
    controller.configure({'action': 'configure', 'selected': null, 'active': false});
    controller.configure({'action': 'configure', 'selected': null, 'active': true});
    expect(commands.where((c) => c['action'] == 'focus'), hasLength(1));
    controller.disconnect();
    controller.connect(commands.add);
    expect(commands.where((c) => c['action'] == 'focus'), hasLength(1));
  });

  Future<void> pumpMap(WidgetTester tester, {double textScale = 1, bool dark = false, bool english = false}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.runAsync(() => LocaleSettings.setLocale(english ? AppLocale.en : AppLocale.ja));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          venueFloorPlanProvider.overrideWith((ref) => plan),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: dark ? darkTheme() : lightTheme(),
            locale: Locale(english ? 'en' : 'ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: const Scaffold(body: VenueMapPage(), bottomNavigationBar: SizedBox(height: 80)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mobile search selection, dismissal, and clearing keep normal camera control', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpMap(tester);
    expect(find.byType(VenueMap3DView), findsNothing);
    final camera = tester.widget<VenueMap2DView>(find.byType(VenueMap2DView)).controller;
    final searchY = tester.getCenter(find.text('場所を探す')).dy;
    await tester.tap(find.text('場所を探す'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Cupertino');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Cupertino'));
    await tester.pumpAndSettle();
    expect(find.byType(VenuePlaceSummary), findsOneWidget);
    expect(tester.getCenter(find.text('場所を探す')).dy, searchY);
    final hall = plan.find('grand_hall_a')!;
    expect((camera.project(hall.anchor) - camera.viewport.center(Offset.zero)).distance, lessThan(.001));
    camera.transform(nextScale: camera.scale, focalPoint: const Offset(90, 120), worldAnchor: hall.anchor);
    await tester.pumpAndSettle();
    final worldCenter = camera.unproject(camera.viewport.center(Offset.zero));
    final scale = camera.scale;
    await tester.tap(find.text('場所を探す'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(VenuePlaceSummary), findsOneWidget);
    await tester.tap(find.byTooltip('選択を解除'));
    await tester.pumpAndSettle();
    expect(find.byType(VenuePlaceSummary), findsNothing);
    expect(camera.scale, scale);
    expect((camera.unproject(camera.viewport.center(Offset.zero)) - worldCenter).distance, lessThan(.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('small display, dark theme, English and large text remain usable', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpMap(tester, textScale: 2, dark: true, english: true);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Find a place'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'restroom');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Men’s restroom'), 100, scrollable: find.byType(Scrollable).first);
    expect(find.text('Men’s restroom'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Women’s restroom'), 100, scrollable: find.byType(Scrollable).first);
    expect(find.text('Women’s restroom'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('3D failure offers a working 2D fallback', (tester) async {
    SharedPreferences.setMockInitialValues({VenueMapViewModeNotifier.preferencesKey: 'threeD'});
    final prefs = await SharedPreferences.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.ja);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          venueFloorPlanProvider.overrideWith((ref) => plan),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const VenueMapPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('会場マップを読み込めませんでした'), findsOneWidget);
    await tester.tap(find.text('2Dで表示'));
    await tester.pumpAndSettle();
    expect(find.byType(VenueMap2DView), findsOneWidget);
    expect(prefs.getString(VenueMapViewModeNotifier.preferencesKey), 'twoD');
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
