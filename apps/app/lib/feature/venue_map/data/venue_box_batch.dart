import 'package:flutter_scene/scene.dart' as fs;
import 'package:vector_math/vector_math.dart' as vm;

/// Fixed venue furniture shares a cube and one draw per material.
/// Keep moving or fading objects outside these cached shadow batches.
class VenueBoxBatch {
  final root = fs.Node(name: 'Static venue boxes');
  late final _cube = fs.CuboidGeometry(vm.Vector3.all(1));
  final _batches = <fs.Material, fs.InstancedMesh>{};

  void add({
    required vm.Vector3 position,
    required vm.Vector3 size,
    required fs.Material material,
    double yaw = 0,
  }) {
    final batch = _batches.putIfAbsent(material, () {
      // These groups span the floor, so retain per-instance visibility tests.
      final batch = fs.InstancedMesh(geometry: _cube, material: material, cullInstances: true);
      root.add(
        fs.Node()
          ..shadowStatic = true
          ..addComponent(fs.InstancedMeshComponent(batch)),
      );
      return batch;
    });
    batch.addInstance(vm.Matrix4.compose(position, vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), yaw), size));
  }
}
