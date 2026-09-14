import 'package:app/feature/venue_map/data/venue_walk_scene.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart' as fs;

/// Renders the retained scene in the map area and suspends hidden frame work.
class VenueSceneViewport extends StatelessWidget {
  const VenueSceneViewport({required this.game, required this.pixelRatio, super.key});
  final VenueWalkScene game;
  final double pixelRatio;

  @override
  Widget build(BuildContext context) => fs.SceneView(
    game.scene,
    camera: game.camera,
    pixelRatio: pixelRatio,
    autoTick: !game.paused,
    onTick: game.tick,
  );
}
