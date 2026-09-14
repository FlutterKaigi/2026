import 'dart:convert';
import 'dart:io';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';
import 'package:app/feature/venue_map/data/venue_walk_scene.dart';
import 'package:app/feature/venue_map/ui/widget/venue_walk_localizations.dart';
import 'package:app/feature/venue_map/ui/widget/venue_walk_run_button.dart';
import 'package:app/feature/venue_map/ui/widget/venue_walk_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late VenueNavigation navigation;
  late Translations ja;
  late Translations en;

  setUpAll(() async {
    navigation = VenueNavigation(
      jsonDecode(File('assets/venue_map/floor_plan.json').readAsStringSync()) as Map<String, Object?>,
    );
    ja = AppLocale.ja.buildSync();
    en = await AppLocale.en.build();
  });

  test('active and completed routes resolve place IDs in the current language', () {
    const destination = 'hall_entrance_information';
    expect(
      ja.venueWalk.headingTo(place: venueWalkPlaceName(ja, navigation, destination)),
      'インフォメーションへ移動中',
    );
    expect(
      en.venueWalk.headingTo(place: venueWalkPlaceName(en, navigation, destination)),
      'Walking to Information',
    );
    const WalkStatus arrived = (
      location: null,
      destination: null,
      notice: WalkNotice.arrived,
      arrivedAt: destination,
      visited: 0,
      running: false,
      overview: false,
    );
    expect(venueWalkNotice(ja, navigation, arrived), 'インフォメーションに到着');
    expect(venueWalkNotice(en, navigation, arrived), 'Arrived at Information');
    expect(venueWalkPlaceName(en, navigation, 'entrance'), 'Entrance');
    expect(venueWalkPlaceName(en, navigation, 'selected_point'), 'Selected spot');
    expect(venueWalkPlaceName(en, navigation, 'creative_board'), 'Creative board');
    expect(venueWalkPlaceName(en, navigation, 'sponsor_3'), 'UPSIDER, Inc.');
  });

  test('photo poses and location captions use the selected language', () {
    expect(VenuePhotoPose.values.map((pose) => pose.label(ja)), ['立つ', '手をふる', '座る', 'ジャンプ']);
    expect(VenuePhotoPose.values.map((pose) => pose.label(en)), ['Stand', 'Wave', 'Sit', 'Jump']);
    expect(
      en.venueWalk.photo.captionAt(place: venueWalkPlaceName(en, navigation, 'entrance')),
      'With Dashumaru at Entrance.',
    );
  });

  testWidgets('switching language updates controls without releasing a held stick or sprint', (tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ja));
    addTearDown(() => LocaleSettings.setLocale(AppLocale.ja));
    final semantics = tester.ensureSemantics();
    try {
      var pressed = false;
      var stick = Offset.zero;
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => Row(
                  children: [
                    Joystick(value: stick, onChanged: (value) => setState(() => stick = value)),
                    VenueWalkRunButton(pressed: pressed, onChanged: (value) => setState(() => pressed = value)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('だしゅまるを動かすスティック'), findsOneWidget);
      final steering = await tester.startGesture(tester.getCenter(find.byType(Joystick)), pointer: 1);
      await steering.moveBy(const Offset(0, -30));
      final sprint = await tester.startGesture(tester.getCenter(find.byType(VenueWalkRunButton)), pointer: 2);
      await tester.pump();
      // Deferred English translations load outside the widget test clock.
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      await tester.pump();
      expect(find.bySemanticsLabel('Stick to move Dashumaru'), findsOneWidget);
      expect(find.bySemanticsLabel('Run'), findsOneWidget);
      expect(find.bySemanticsLabel('走る'), findsNothing);
      expect(pressed, isTrue);
      expect(stick.dy, lessThan(-.8));
      await steering.up();
      await sprint.up();
      expect(pressed, isFalse);
      expect(stick, Offset.zero);
    } finally {
      semantics.dispose();
    }
  });
}
