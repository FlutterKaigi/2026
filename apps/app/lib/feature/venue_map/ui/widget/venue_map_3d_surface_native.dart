import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VenueMap3DSurface extends StatefulWidget {
  const VenueMap3DSurface({required this.onReady, required this.onMessage, required this.interactive, super.key});

  final bool interactive;
  final void Function(void Function(Map<String, Object?>)) onReady;
  final ValueChanged<Map<String, Object?>> onMessage;

  @override
  State<VenueMap3DSurface> createState() => _VenueMap3DSurfaceState();
}

class _VenueMap3DSurfaceState extends State<VenueMap3DSurface> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fail());
      return;
    }
    try {
      final controller = WebViewController();
      _controller = controller;
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.addJavaScriptChannel(
        'VenueMapChannel',
        onMessageReceived: (message) {
          if (!mounted) {
            return;
          }
          final data = Map<String, Object?>.from(jsonDecode(message.message) as Map);
          if (data['type'] == 'ready') {
            widget.onReady((command) => unawaited(_send(command)));
          } else {
            widget.onMessage(data);
          }
        },
      );
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? false) {
              _fail();
            }
          },
          onNavigationRequest: (request) => request.url.startsWith('file:') || request.url == 'about:blank'
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      );
      await controller.loadFlutterAsset('assets/html/venue_floor_plan_webview.html');
      if (mounted) {
        setState(() {});
      }
    } on Exception {
      _fail();
    }
  }

  Future<void> _send(Map<String, Object?> command) async {
    try {
      if (mounted) {
        await _controller?.runJavaScript('window.VenueMap.receive(${jsonEncode(command)})');
      }
    } on Exception {
      _fail();
    }
  }

  void _fail() {
    if (mounted) {
      widget.onMessage({'type': 'error'});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return controller == null ? const SizedBox.expand() : WebViewWidget(controller: controller);
  }
}
