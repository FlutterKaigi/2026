import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class VenueMap3DSurface extends StatefulWidget {
  const VenueMap3DSurface({required this.onReady, required this.onMessage, required this.interactive, super.key});

  final bool interactive;
  final void Function(void Function(Map<String, Object?>)) onReady;
  final ValueChanged<Map<String, Object?>> onMessage;

  @override
  State<VenueMap3DSurface> createState() => _VenueMap3DSurfaceState();
}

class _VenueMap3DSurfaceState extends State<VenueMap3DSurface> {
  web.HTMLIFrameElement? _frame;
  late final JSFunction _listener;

  @override
  void initState() {
    super.initState();
    _listener = ((web.MessageEvent event) {
      if (!mounted ||
          _frame == null ||
          event.source != _frame!.contentWindow ||
          event.origin != web.window.location.origin) {
        return;
      }
      final payload = event.data;
      if (payload == null || !payload.isA<JSString>()) {
        return;
      }
      final decoded = jsonDecode((payload as JSString).toDart);
      if (decoded is! Map) {
        return;
      }
      final data = Map<String, Object?>.from(decoded);
      if (data['type'] == 'ready') {
        widget.onReady(_send);
      } else {
        widget.onMessage(data);
      }
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  @override
  void didUpdateWidget(VenueMap3DSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _frame?.style.pointerEvents = widget.interactive ? 'auto' : 'none';
  }

  void _send(Map<String, Object?> command) {
    _frame?.contentWindow?.postMessage(jsonEncode(command).toJS, web.window.location.origin.toJS);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    _frame = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (element) {
      final frame = element as web.HTMLIFrameElement;
      _frame = frame;
      frame
        ..title = '3D venue map'
        ..src = Uri.base.resolve('assets/assets/html/venue_floor_plan_webview.html').toString();
      frame.style
        ..pointerEvents = widget.interactive ? 'auto' : 'none'
        ..border = '0'
        ..width = '100%'
        ..height = '100%';
    },
  );
}
