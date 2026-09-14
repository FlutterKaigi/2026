import 'package:flutter_scene/build_hooks.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    // Use the supplied mascot and the same floor image as the 2D/3D views.
    buildScenes(
      buildInput: input,
      buildOutput: output,
      inputFilePaths: const ['assets/models/dashmaru.glb'],
    );
    buildTextures(
      buildInput: input,
      buildOutput: output,
      textures: const ['assets/venue_map/floor_map_base.png', 'assets/venue_map/floor_map_base_dark.png'],
    );
  });
}
