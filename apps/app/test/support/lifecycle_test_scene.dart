import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart' as fs;
import 'package:flutter_test/flutter_test.dart';

/// Scene construction needs Impeller even when testing only the view lifecycle.
/// Run these tests with `flutter test --enable-impeller --enable-flutter-gpu`.
LifecycleTestScene? createLifecycleTestScene() {
  try {
    return LifecycleTestScene();
  } on Exception catch (error) {
    if (!error.toString().contains('Flutter GPU requires the Impeller rendering backend')) {
      rethrow;
    }
    markTestSkipped('Requires --enable-impeller --enable-flutter-gpu');
    return null;
  }
}

/// Exercises the real SceneView and ticker without rendering GPU assets.
final class LifecycleTestScene extends fs.Scene {
  @override
  void render(fs.Camera camera, Canvas canvas, {Rect? viewport, double? pixelRatio}) {}

  void dispose() {
    renderScene.semanticsComponentsChanged.dispose();
    renderScene.widgetComponentsChanged.dispose();
  }
}
