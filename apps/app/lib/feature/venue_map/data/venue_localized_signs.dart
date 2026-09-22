import 'package:flutter_scene/scene.dart' as fs;
import 'package:vector_math/vector_math.dart' as vm;

/// Switch only sign textures, preserving the scene, camera and walking route.
class VenueLocalizedSigns {
  VenueLocalizedSigns(this._languageCode);

  String _languageCode;
  bool _disposed = false;
  final _signs = <_LocalizedSign>[];

  Future<fs.UnlitMaterial> create(Future<fs.Texture2D> Function(String) render) async {
    final sign = _LocalizedSign(render);
    _signs.add(sign);
    await _apply(sign);
    return sign.material;
  }

  Future<void> setLanguage(String languageCode) async {
    _languageCode = languageCode;
    await Future.wait(_signs.map(_apply));
  }

  Future<void> _apply(_LocalizedSign sign) async {
    final language = _languageCode;
    final texture = await sign.textures.putIfAbsent(language, () => sign.render(language));
    if (!_disposed && language == _languageCode) {
      sign.material.baseColorTexture = texture;
    } else if (!_disposed) {
      await _apply(sign);
    }
  }

  void dispose() {
    _disposed = true;
    _signs.clear();
  }
}

class _LocalizedSign {
  _LocalizedSign(this.render);

  final Future<fs.Texture2D> Function(String) render;
  final textures = <String, Future<fs.Texture2D>>{};
  final material = fs.UnlitMaterial()
    ..baseColorTextureTransform = fs.TextureTransform(offset: vm.Vector2(0, 1), scale: vm.Vector2(1, -1));
}
