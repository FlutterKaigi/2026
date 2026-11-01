import 'dart:async';

import 'package:app/feature/session/ui/widget/youtube_archive_html.dart';
import 'package:app/feature/session/ui/widget/youtube_archive_playback_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

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
  WebViewController? _controller;
  bool _stopped = false;

  @override
  void initState() {
    super.initState();
    widget.playbackController.addListener(_stop);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fail());
      return;
    }
    try {
      final package = await PackageInfo.fromPlatform();
      if (!mounted || _stopped) {
        return;
      }
      final origin = youtubeArchiveAppOrigin(package.packageName);
      // baseUrl supplies the HTTP Referer required by YouTube in native apps:
      // https://developers.google.com/youtube/terms/required-minimum-functionality#embedded-player-api-client-identity
      final params = WebViewPlatform.instance is WebKitWebViewPlatform
          ? WebKitWebViewControllerCreationParams(allowsInlineMediaPlayback: true)
          : const PlatformWebViewControllerCreationParams();
      final controller = WebViewController.fromPlatformCreationParams(params);
      _controller = controller;
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.addJavaScriptChannel('YouTubeArchiveChannel', onMessageReceived: (_) => _fail());
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? false) {
              _fail();
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (request.url == 'about:blank' || (uri?.scheme == 'https' && uri?.host == origin.host)) {
              return NavigationDecision.navigate;
            }
            // Keep the wrapper document in place; YouTube's iframe can load
            // its HTTPS documents. The explicit fallback opens external links.
            return !request.isMainFrame && uri?.scheme == 'https'
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      );
      if (!mounted || _stopped) {
        return;
      }
      await controller.loadHtmlString(
        youtubeArchivePlayerHtml(embedUri: widget.embedUri, origin: origin, title: widget.title),
        baseUrl: '${origin.origin}/',
      );
      if (mounted) {
        setState(() {});
      }
    } on Object {
      _fail();
    }
  }

  void _fail() {
    if (mounted && !_stopped) {
      widget.onError();
    }
  }

  @override
  void dispose() {
    widget.playbackController.removeListener(_stop);
    _stop();
    super.dispose();
  }

  void _stop() {
    _stopped = true;
    final controller = _controller;
    if (controller != null) {
      unawaited(_loadBlank(controller));
    }
  }

  Future<void> _loadBlank(WebViewController controller) async {
    try {
      await controller.loadRequest(Uri.parse('about:blank'));
    } on Object {
      // The platform view may already have been disposed by Flutter. In that
      // case its media is already stopped and there is no live UI to update.
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return controller == null
        ? const Center(child: CircularProgressIndicator.adaptive())
        : WebViewWidget(controller: controller);
  }
}
