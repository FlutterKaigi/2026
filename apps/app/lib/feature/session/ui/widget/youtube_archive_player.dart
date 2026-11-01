import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/feature/session/ui/widget/youtube_archive_playback_controller.dart';
import 'package:app/feature/session/ui/widget/youtube_archive_surface_native.dart'
    if (dart.library.js_interop) 'package:app/feature/session/ui/widget/youtube_archive_surface_web.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef YouTubeArchiveSurfaceBuilder = Widget Function({
  required Uri embedUri,
  required String title,
  required VoidCallback onError,
  required YouTubeArchivePlaybackController playbackController,
});

final youtubeArchiveSurfaceBuilderProvider = Provider<YouTubeArchiveSurfaceBuilder>(
  (ref) => YouTubeArchiveSurface.new,
);

/// An inline recording with the original YouTube link available as a fallback.
class YouTubeArchivePlayer extends ConsumerStatefulWidget {
  const YouTubeArchivePlayer({required this.archiveUri, required this.title, this.launcher, super.key});

  final Uri archiveUri;
  final String title;
  final ExternalUrlLauncher? launcher;

  @override
  ConsumerState<YouTubeArchivePlayer> createState() => _YouTubeArchivePlayerState();
}

class _YouTubeArchivePlayerState extends ConsumerState<YouTubeArchivePlayer> with WidgetsBindingObserver {
  bool _foreground = true;
  bool _failed = false;
  int _generation = 0;
  final _playbackController = YouTubeArchivePlaybackController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || _isForeground(lifecycle);
  }

  @override
  void didUpdateWidget(YouTubeArchivePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.archiveUri != widget.archiveUri) {
      _failed = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) {
      return;
    }
    final foreground = _isForeground(state);
    if (_foreground == foreground) {
      return;
    }
    if (!foreground) {
      // Paused apps do not draw frames, so stop immediately rather than waiting
      // for build to remove the platform view.
      _playbackController.stop();
    }
    setState(() {
      _foreground = foreground;
      if (!_foreground) {
        _generation++;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playbackController.stop();
    _playbackController.dispose();
    super.dispose();
  }

  void _onError() {
    if (mounted) {
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final embedUri = youtubeArchiveEmbedUri(widget.archiveUri.toString());
    // Removing the platform surface stops playback when another route covers
    // these details or the app goes into the background. Returning never autoplays.
    final visible = _foreground && (ModalRoute.isCurrentOf(context) ?? true);
    return Column(
      key: const ValueKey('youtube-archive-player'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (embedUri != null && !_failed)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 200),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: visible
                  ? KeyedSubtree(
                      key: ValueKey((embedUri, _generation)),
                      child: ref.watch(youtubeArchiveSurfaceBuilderProvider)(
                        embedUri: embedUri,
                        title: '${t.sessionDetails.archive}: ${widget.title}',
                        onError: _onError,
                        playbackController: _playbackController,
                      ),
                    )
                  : const ColoredBox(color: Colors.black),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(t.sessionDetails.archivePlaybackError),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => unawaited(
              launchExternalUrl(
                context,
                uri: widget.archiveUri,
                failureMessage: t.links.openError,
                launcher: widget.launcher,
              ),
            ),
            icon: const Icon(Icons.open_in_new),
            label: Text(t.sessionDetails.openYoutube),
          ),
        ),
      ],
    );
  }
}

// Flutter Web loses window focus when the visible YouTube iframe receives it.
// Inactive is therefore still foreground; hidden/paused/detached stop playback.
bool _isForeground(AppLifecycleState state) =>
    state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
