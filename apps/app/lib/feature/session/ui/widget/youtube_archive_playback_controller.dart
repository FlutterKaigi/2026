import 'package:flutter/foundation.dart';

/// Stops platform playback immediately, including while Flutter has no frames.
class YouTubeArchivePlaybackController extends ChangeNotifier {
  void stop() => notifyListeners();
}
