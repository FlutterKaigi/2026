import 'package:flutter/foundation.dart';

/// Connects the map's place search to the retained walking scene.
class VenueWalkController {
  ValueChanged<String>? _onDestination;
  String? _pending;

  void goTo(String placeId) {
    final callback = _onDestination;
    if (callback == null) {
      _pending = placeId;
    } else {
      callback(placeId);
    }
  }

  void connect(ValueChanged<String> callback) {
    _onDestination = callback;
    final pending = _pending;
    _pending = null;
    if (pending != null) {
      callback(pending);
    }
  }

  void disconnect() => _onDestination = null;
}
