import 'dart:js_interop';

import 'package:app/feature/session/ui/widget/youtube_archive_html.dart';
import 'package:app/feature/session/ui/widget/youtube_archive_playback_controller.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class YouTubeArchiveSurface extends StatefulWidget {
  const YouTubeArchiveSurface({
    required this.embedUri,
    required this.title,
    required this.onError,
    required this.playbackController,
    super.key,
  });

  final Uri embedUri;
  final String title;
  final VoidCallback onError;
  final YouTubeArchivePlaybackController playbackController;

  @override
  State<YouTubeArchiveSurface> createState() => _YouTubeArchiveSurfaceState();
}

class _YouTubeArchiveSurfaceState extends State<YouTubeArchiveSurface> {
  web.HTMLIFrameElement? _frame;
  bool _stopped = false;
  late final JSFunction _listener;

  @override
  void initState() {
    super.initState();
    widget.playbackController.addListener(_stop);
    _listener = ((web.MessageEvent event) {
      if (!mounted ||
          _stopped ||
          _frame == null ||
          event.source != _frame!.contentWindow ||
          event.origin != web.window.location.origin) {
        return;
      }
      final message = event.data;
      if (message != null && message.isA<JSString>() && (message as JSString).toDart == 'youtube-archive-error') {
        widget.onError();
      }
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    widget.playbackController.removeListener(_stop);
    _stop();
    _frame = null;
    super.dispose();
  }

  void _stop() {
    _stopped = true;
    // Destroy the embedded document immediately, including when the app route
    // stays mounted underneath another route or the browser is backgrounded.
    _frame
      ?..srcdoc = ''.toJS
      ..src = 'about:blank'
      ..remove();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (element) {
      final frame = element as web.HTMLIFrameElement;
      if (!mounted || _stopped) {
        frame.remove();
        return;
      }
      _frame = frame;
      frame
        ..title = widget.title
        ..srcdoc = youtubeArchivePlayerHtml(
          embedUri: widget.embedUri,
          origin: Uri.parse(web.window.location.origin),
          title: widget.title,
        ).toJS;
      frame.setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');
      frame.setAttribute('allow', 'autoplay; encrypted-media; picture-in-picture; fullscreen');
      frame.setAttribute('allowfullscreen', '');
      frame.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%';
    },
  );
}
