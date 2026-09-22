import 'package:app/feature/venue_map/data/venue_walk_scene.dart';
import 'package:app/feature/venue_map/ui/widget/venue_scene_viewport.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart' as fs;
import 'package:flutter_test/flutter_test.dart';

import 'support/lifecycle_test_scene.dart';

void main() {
  testWidgets('the retained 3D scene pauses and resumes repeatedly without creating another ticker', (tester) async {
    final scene = createLifecycleTestScene();
    if (scene == null) {
      return;
    }
    final game = _TickingScene(scene);
    addTearDown(game.dispose);

    Future<void> pumpViewport({required bool paused}) async {
      game.paused = paused;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: VenueSceneViewport(game: game, pixelRatio: 1),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }

    await pumpViewport(paused: false);
    expect(game.ticks, isNotEmpty);
    final viewState = tester.state(find.byType(fs.SceneView));

    for (var i = 0; i < 3; i++) {
      await pumpViewport(paused: true);
      final pausedTicks = game.ticks.length;
      await tester.pump(const Duration(seconds: 1));
      expect(game.ticks, hasLength(pausedTicks));
      expect(tester.binding.hasScheduledFrame, isFalse);

      await pumpViewport(paused: false);
      expect(tester.takeException(), isNull);
      expect(game.ticks.length, greaterThan(pausedTicks));
      expect(tester.state(find.byType(fs.SceneView)), same(viewState));
    }

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}

class _TickingScene extends VenueWalkScene {
  _TickingScene(this._scene);

  final LifecycleTestScene _scene;
  final ticks = <double>[];

  @override
  LifecycleTestScene get scene => _scene;

  @override
  void tick(Duration elapsed, double delta) => ticks.add(delta);

  @override
  void dispose() {
    _scene.dispose();
    super.dispose();
  }
}
