import 'package:flutter_scene/build_hooks.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    // Cook the mascot. Floor artwork is decoded directly at a smaller size
    // for 3D to avoid Flutter Scene's expensive runtime ETC2 transcoding.
    buildScenes(
      buildInput: input,
      buildOutput: output,
      inputFilePaths: const ['assets/models/dashmaru.glb'],
    );
  });
}
