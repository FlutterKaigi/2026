import 'package:app/feature/venue_map/data/venue_walk_architecture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  double opacity(vm.Vector3 camera, vm.Vector3 focus, {bool overview = false}) => venueEntranceHeaderOpacity(
    camera: camera,
    focus: focus,
    center: vm.Vector3.zero(),
    width: 5.2,
    overview: overview,
  );

  test('a close camera looking through the entrance clears the overhead sign', () {
    expect(opacity(vm.Vector3(0, 2.7, -4), vm.Vector3(0, 1.1, 2)), 0);
    // The same doorway works when walking back toward the entrance.
    expect(opacity(vm.Vector3(0, 2.7, 4), vm.Vector3(0, 1.1, -2)), 0);
    expect(opacity(vm.Vector3(0, 2.7, -5), vm.Vector3(0, 1.1, 2)), closeTo(.5, .001));
  });

  test('overview and distant cameras retain the entrance sign', () {
    expect(opacity(vm.Vector3(0, 12, -14), vm.Vector3(0, 1.1, 2)), 1);
    expect(opacity(vm.Vector3(0, 2.7, -4), vm.Vector3(0, 1.1, 2), overview: true), 1);
  });

  test('a sign behind the camera or outside the sightline is not faded', () {
    expect(opacity(vm.Vector3(0, 2.7, -4), vm.Vector3(0, 1.1, -2)), 1);
    expect(opacity(vm.Vector3(7, 2.7, -4), vm.Vector3(7, 1.1, 2)), 1);
    expect(opacity(vm.Vector3(0, 2.7, -4), vm.Vector3(7, 1.1, -4)), 1);
  });
}
