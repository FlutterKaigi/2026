import 'package:app/feature/venue_map/ui/widget/venue_walk_controller.dart';
import 'package:app/feature/venue_map/ui/widget/venue_walk_run_button.dart';
import 'package:app/feature/venue_map/ui/widget/venue_walk_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a destination selected while the scene is paused is delivered once on resume', () {
    final controller = VenueWalkController();
    final destinations = <String>[];
    controller
      ..connect(destinations.add)
      ..disconnect()
      ..goTo('main_hall_a')
      ..goTo('grand_hall_a');
    expect(destinations, isEmpty);
    controller
      ..connect(destinations.add)
      ..connect(destinations.add);
    expect(destinations, ['grand_hall_a']);
  });

  testWidgets('two thumbs can steer and hold sprint independently, with immediate release', (tester) async {
    var sprint = false;
    var stick = Offset.zero;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Row(
              children: [
                Joystick(value: stick, onChanged: (value) => setState(() => stick = value)),
                VenueWalkRunButton(
                  pressed: sprint,
                  onChanged: (value) => setState(() => sprint = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final steering = await tester.startGesture(
      tester.getCenter(find.byType(Joystick)),
      pointer: 1,
    );
    await steering.moveBy(const Offset(0, -34));
    final running = await tester.startGesture(
      tester.getCenter(find.byType(VenueWalkRunButton)),
      pointer: 2,
    );
    await tester.pump();
    expect(sprint, isTrue); // No long-press delay.
    expect(stick.dy, lessThan(-.9));

    await steering.up();
    await running.moveBy(const Offset(200, 0)); // A drifting thumb keeps the hold.
    await tester.pump();
    expect(stick, Offset.zero);
    expect(sprint, isTrue);

    await running.up();
    await tester.pump();
    expect(sprint, isFalse);
  });

  testWidgets('a cancelled sprint touch restores walking without releasing the steering thumb', (tester) async {
    var sprint = false;
    var stick = Offset.zero;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Row(
              children: [
                Joystick(value: stick, onChanged: (value) => setState(() => stick = value)),
                VenueWalkRunButton(
                  pressed: sprint,
                  onChanged: (value) => setState(() => sprint = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final steering = await tester.startGesture(
      tester.getCenter(find.byType(Joystick)),
      pointer: 1,
    );
    await steering.moveBy(const Offset(34, 0));
    final running = await tester.startGesture(
      tester.getCenter(find.byType(VenueWalkRunButton)),
      pointer: 2,
    );
    await tester.pump();
    expect(sprint, isTrue);

    await running.cancel();
    await tester.pump();
    expect(sprint, isFalse);
    expect(stick.dx, greaterThan(.9));
    await steering.up();
    expect(stick, Offset.zero);
  });

  testWidgets('reset clears a held stick and ignores that finger until a new touch starts', (tester) async {
    var stick = Offset.zero;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                Joystick(value: stick, onChanged: (value) => setState(() => stick = value)),
                TextButton(onPressed: () => setState(() => stick = Offset.zero), child: const Text('Reset')),
              ],
            ),
          ),
        ),
      ),
    );
    final finger = await tester.startGesture(tester.getCenter(find.byType(Joystick)), pointer: 1);
    await finger.moveBy(const Offset(34, 0));
    await tester.pump();
    expect(stick.dx, greaterThan(.9));
    await tester.tap(find.text('Reset'), pointer: 2);
    await tester.pump();
    expect(stick, Offset.zero);
    final knob = tester.getCenter(find.byIcon(Icons.pets_outlined));
    expect(knob, tester.getCenter(find.byType(Joystick)));
    await finger.moveBy(const Offset(0, 10));
    await tester.pump();
    expect(stick, Offset.zero);
    await finger.up();
    final next = await tester.startGesture(tester.getCenter(find.byType(Joystick)), pointer: 3);
    await next.moveBy(const Offset(0, -34));
    await tester.pump();
    expect(stick.dy, lessThan(-.9));
    await next.up();
  });
}
