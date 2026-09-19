import 'dart:convert';
import 'dart:io';

import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';

/// Compile with `dart compile exe` for comparable, non-JIT route timings.
/// Pass the floor_plan.json path when the executable lives outside this folder.
void main(List<String> args) {
  final file = args.isEmpty
      ? File.fromUri(Platform.script.resolve('../../assets/venue_map/floor_plan.json'))
      : File(args.single);
  final data = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final samples = <String, List<double>>{
    for (final id in [
      'main_hall_a',
      'main_hall_b',
      'grand_hall_a',
      'grand_hall_b',
      'mens_wc',
      'womens_wc',
      'accessible_wc',
    ])
      id: [],
  };
  for (var run = 0; run < 30; run++) {
    // Match a newly loaded map and the same sequence of selected destinations.
    final nav = VenueNavigation(data);
    for (final entry in samples.entries) {
      final place = nav.places.firstWhere((place) => place.id == entry.key);
      final watch = Stopwatch()..start();
      final route = nav.routeToPlace(VenueNavigation.spawn, place);
      watch.stop();
      if (route.isEmpty || !nav.canStand(route.last)) {
        throw StateError('No reachable route to ${entry.key}');
      }
      entry.value.add(watch.elapsedMicroseconds / 1000);
    }
  }
  for (final entry in samples.entries) {
    final values = entry.value..sort();
    stdout.writeln(
      '${entry.key}: median=${values[values.length ~/ 2].toStringAsFixed(2)} ms, '
      'p95=${values[(values.length * .95).ceil() - 1].toStringAsFixed(2)} ms',
    );
  }
}
