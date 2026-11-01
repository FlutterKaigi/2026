import 'package:app/feature/session/ui/widget/youtube_archive_playback_controller.dart';
import 'package:flutter/material.dart';

/// Keeps UI tests independent of native WebViews and network video playback.
Widget fakeYouTubeArchiveSurface({
  required Uri embedUri,
  required String title,
  required VoidCallback onError,
  required YouTubeArchivePlaybackController playbackController,
}) => ColoredBox(key: ValueKey(embedUri), color: Colors.black);
