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
  late Map<String, Object?> sourcePlan;
  late VenueFloorPlan plan;
  setUpAll(() async {
    sourcePlan = Map<String, Object?>.from(
      jsonDecode(await rootBundle.loadString('assets/venue_map/floor_plan.json')) as Map,
    );
    plan = VenueFloorPlan.fromJson(sourcePlan);
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

  test('reviewed map contains every numbered sponsor and visitor facility without sponsor ranks', () {
    final sponsors = plan.places.where((p) => p.type == VenuePlaceType.sponsor).toList();
    expect(sponsors.map((p) => p.boothNumber), List.generate(22, (i) => i + 1));
    expect(sponsors.first.name('ja'), 'Flutter');
    expect(sponsors.map((p) => p.markerColor).toSet(), hasLength(1));
    expect((sourcePlan['booths']! as List).map((b) => (b as Map)['color']).toSet(), hasLength(1));
    for (final p in sponsors) {
      expect(p.subtitle('ja'), matches(RegExp(r'^ホワイエ[12]$')));
      expect(p.subtitle('en'), matches(RegExp(r'^Foyer [12]$')));
    }
    expect(plan.find('elevators'), isNull);
    expect(plan.find('accessible_wc')!.iconData, Icons.accessible);
    expect(plan.find('ask_up')!.relatedHallId, 'main_hall_b');
    expect(plan.find('ask_jt')!.relatedHallId, 'main_hall_a');
    expect(plan.find('ask_b')!.relatedHallId, 'grand_hall_b');
    expect(plan.places.where((p) => p.id.startsWith('trash_')), hasLength(2));
    expect(sourcePlan['escalators'], hasLength(4));
    for (final point in [
      const Offset(860, 703),
      const Offset(860, 738),
      const Offset(1020, 703),
      const Offset(1020, 738),
    ]) {
      expect(plan.placeAt(point)?.id, 'escalators');
    }
    for (final p in plan.places) {
      expect(plan.isRestricted(p.anchor), isFalse, reason: p.id);
      expect(plan.placeAt(p.anchor)?.id, p.id, reason: p.id);
    }
  });

  test('booth numbers have readable contrast on their shared color', () {
    for (final p in plan.places.where((p) => p.boothNumber != null)) {
      final a = p.markerColor.computeLuminance();
      final b = p.markerTextColor.computeLuminance();
      final contrast = ((a > b ? a : b) + .05) / ((a < b ? a : b) + .05);
      expect(contrast, greaterThanOrEqualTo(4.5), reason: p.id);
    }
  });

  test('search accepts exact booth numbers, circled numbers, names and both languages', () {
    expect(plan.places.where((p) => p.matches('1')).map((p) => p.id), ['sponsor_1']);
    expect(plan.places.where((p) => p.matches('#15')).map((p) => p.id), ['sponsor_15']);
    expect(plan.find('sponsor_22')!.matches('㉒'), isTrue);
    expect(plan.find('sponsor_2')!.matches('日本トレカ'), isTrue);
    expect(plan.find('sponsor_6')!.matches('HACOMONO'), isTrue);
    expect(plan.find('accessible_wc')!.matches('accessible'), isTrue);
  });

  test('hall entrances select their hall and closed areas remain unselectable', () {
    for (final (point, id) in [
      (const Offset(444, 355), 'main_hall_a'),
      (const Offset(444, 617), 'main_hall_b'),
      (const Offset(1407, 328), 'grand_hall_a'),
      (const Offset(1407, 647), 'grand_hall_b'),
    ]) {
      expect(plan.placeAt(point)?.id, id);
    }
    for (final point in [const Offset(800, 200), const Offset(1390, 180), const Offset(1340, 670), Offset.zero]) {
      expect(plan.placeAt(point), isNull);
    }
    expect(plan.publicEntrances, hasLength(10));
  });

  test('2D and offline 3D use the identical reviewed geometry and icon glyphs', () async {
    final html = await rootBundle.loadString('assets/html/venue_floor_plan_webview.html');
    final embeddedPlan = RegExp(r'const PLAN = (\{[^\n]+\});').firstMatch(html)!;
    expect(jsonDecode(embeddedPlan.group(1)!), sourcePlan);
    final embedded = RegExp(r'const MAP_ICONS = (\{[^;]+\});').firstMatch(html)!;
    final icons = Map<String, String>.from(jsonDecode(embedded.group(1)!) as Map);
    for (final p in plan.places.where((p) => p.type == VenuePlaceType.facility)) {
      expect(icons[p.materialIcon], String.fromCharCode(p.iconData.codePoint), reason: p.id);
      expect(p.mapLabel('en'), isNotEmpty);
    }
    expect(html.contains('MAP_ART_DARK'), isTrue);
    expect((await rootBundle.load(plan.artAsset)).lengthInBytes, greaterThan(10000));
    expect((await rootBundle.load(plan.artAssetDark)).lengthInBytes, greaterThan(10000));
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

  testWidgets('visible labels stay readable across selection and rotation; dense booth labels appear on zoom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpMap(tester);
    final camera = tester.widget<VenueMap2DView>(find.byType(VenueMap2DView)).controller;

    void expectAllLabels() {
      final boxes = <Rect>[];
      for (final place in plan.places) {
        if (!(Offset.zero & camera.viewport).contains(camera.project(place.anchor))) {
          continue;
        }
        if (place.type == VenuePlaceType.sponsor && camera.scale < .5) {
          continue;
        }
        final label = find.byTooltip(place.semanticsLabel('ja'));
        expect(label, findsOneWidget, reason: '${place.id} must stay visible');
        final box = tester.getRect(label);
        expect(box.size.width, greaterThanOrEqualTo(24));
        expect(box.size.height, greaterThanOrEqualTo(24));
        for (final other in boxes) {
          expect(box.overlaps(other), isFalse, reason: '${place.id} must remain readable and tappable');
        }
        boxes.add(box);
      }
    }

    expectAllLabels();
    await tester.tap(find.byTooltip(plan.find('hall_entrance_information')!.name('ja')));
    await tester.pumpAndSettle();
    expectAllLabels();
    for (var rotation = 0; rotation < 4; rotation++) {
      camera.rotate();
      camera.zoom(.7);
      await tester.pumpAndSettle();
      expectAllLabels();
      expect(
        find.byTooltip(plan.find('mens_wc')!.name('ja')),
        findsOneWidget,
        reason:
            'rotation=$rotation viewport=${camera.viewport} scale=${camera.scale} mens=${camera.project(plan.find('mens_wc')!.anchor)}',
      );
      expect(find.byTooltip(plan.find('womens_wc')!.name('ja')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('sponsor directory selects a numbered table and clearing search restores the list', (tester) async {
    tester.view.physicalSize = const Size(1100, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpMap(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'スポンサー 22'));
    await tester.enterText(find.byType(TextField), '15');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'GENDA'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Flutter'), findsNothing);
    await tester.tap(find.widgetWithText(ListTile, 'GENDA'));
    await tester.pumpAndSettle();
    final map = tester.widget<VenueMap2DView>(find.byType(VenueMap2DView));
    expect(map.selected?.boothNumber, 15);
    expect(find.byTooltip('15 · GENDA'), findsOneWidget);
    await tester.tap(find.byTooltip('検索をクリア'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Flutter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English restroom captions appear after zoom without overflowing', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpMap(tester, english: true);
    final camera = tester.widget<VenueMap2DView>(find.byType(VenueMap2DView)).controller;
    camera.focus(plan.find('accessible_wc')!);
    await tester.pumpAndSettle();
    expect(find.text('Accessible'), findsOneWidget);
    expect(find.byTooltip('Accessible restroom'), findsOneWidget);
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
