import 'dart:async';

/// Lazily caches the two floor variants and applies texture and surface colors
/// together. A stale async load must never overwrite a newer theme selection.
class VenueThemeTextures<T extends Object> {
  VenueThemeTextures({required this.load});

  final Future<T> Function({required bool dark}) load;
  final _textures = <bool, T>{};
  final _pending = <bool, Future<T>>{};
  bool dark = false;
  bool _disposed = false;

  Future<T> _texture(bool dark) => _pending.putIfAbsent(dark, () async {
    try {
      final texture = await Future<T>.sync(() => load(dark: dark));
      if (!_disposed) {
        _textures[dark] = texture;
      }
      return texture;
    } finally {
      unawaited(_pending.remove(dark));
    }
  });

  Future<void> apply(void Function(T texture, {required bool dark}) update) async {
    while (!_disposed) {
      final requested = dark;
      final texture = _textures[requested] ?? await _texture(requested);
      if (!_disposed && requested == dark) {
        update(texture, dark: requested);
        return;
      }
    }
  }

  void dispose() {
    _disposed = true;
    _textures.clear();
    _pending.clear();
  }
}
