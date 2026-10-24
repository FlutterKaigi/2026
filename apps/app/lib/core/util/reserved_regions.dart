import 'package:flutter/services.dart';

/// Channel to the Runner, which reports the screen regions that iOS reserves
/// for hardware, such as the camera inside iPhone Duo's vertical bar.
const reservedRegionsChannel = MethodChannel('jp.flutterkaigi.conf2026/reserved_regions');

/// Returns the active occlusions (`UIView.reservedRegions(kind: .occlusion)`)
/// in logical pixels, or `null` when the platform cannot report them.
///
/// The safe area does not say where in the vertical bar the camera sits: it
/// moves from the top to the bottom as the closed device rotates.
Future<List<Rect>?> fetchOcclusions() async {
  try {
    final regions = await reservedRegionsChannel.invokeListMethod<Map<Object?, Object?>>('occlusions');
    return [
      for (final region in regions ?? const <Map<Object?, Object?>>[])
        if (region['active'] == true)
          Rect.fromLTWH(
            (region['x']! as num).toDouble(),
            (region['y']! as num).toDouble(),
            (region['width']! as num).toDouble(),
            (region['height']! as num).toDouble(),
          ),
    ];
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}
