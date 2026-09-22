import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart' as fs;

/// Decode the shared floor artwork at the plan's logical resolution for 3D.
///
/// Flutter Scene 0.23's cooked texture loader transcodes these images to ETC2
/// on Android at runtime, taking over 30 seconds on the emulator. Direct PNG
/// decoding avoids that work. Halving the source dimensions bounds the two
/// RGBA textures to about 14.6 MiB including mipmaps (instead of 58.5 MiB).
/// The full-resolution assets remain available to the zoomable 2D map.
Future<fs.Texture2D> loadVenueFloorTexture({required bool dark}) async {
  final asset = dark ? 'assets/venue_map/floor_map_base_dark.png' : 'assets/venue_map/floor_map_base.png';
  return loadVenuePngTexture(asset, targetWidth: 1774);
}

/// Upload decoded PNGs with the same mipmaps and filtering as painted artwork.
Future<fs.Texture2D> loadVenuePngTexture(String asset, {int? targetWidth}) async {
  final buffer = await rootBundle.loadBuffer(asset);
  // instantiateImageCodecFromBuffer takes ownership of the encoded buffer.
  final codec = await ui.instantiateImageCodecFromBuffer(buffer, targetWidth: targetWidth, allowUpscaling: false);
  try {
    final frame = await codec.getNextFrame();
    try {
      // Retain the default mipmaps and anisotropic filtering for the floor.
      // Texture2D is scene-owned; unlike loadTexture it has no registry claim.
      return await fs.Texture2D.fromImage(frame.image);
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}
