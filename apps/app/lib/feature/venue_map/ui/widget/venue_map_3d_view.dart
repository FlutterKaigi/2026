import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/venue_map/data/venue_floor_plan.dart';
import 'package:app/feature/venue_map/ui/widget/venue_map_3d_surface_native.dart'
    if (dart.library.js_interop) 'package:app/feature/venue_map/ui/widget/venue_map_3d_surface_web.dart';
import 'package:flutter/material.dart';

typedef VenueMapSend = void Function(Map<String, Object?> command);

class VenueMap3DController {
  VenueMapSend? _send;
  Map<String, Object?>? _configuration;
  String? _pendingFocus;

  void configure(Map<String, Object?> configuration) {
    _configuration = configuration;
    _send?.call(configuration);
  }

  void connect(VenueMapSend send) {
    _send = send;
    if (_configuration case final configuration?) {
      send(configuration);
    }
    if (_pendingFocus case final id?) {
      _pendingFocus = null;
      focus(id);
    }
  }

  void disconnect() => _send = null;

  void focus(String id) {
    if (_send == null) {
      _pendingFocus = id;
    } else {
      _send?.call({'action': 'focus', 'value': id});
    }
  }

  void fit() => _send?.call({'action': 'fit'});
  void zoom(double factor) => _send?.call({'action': 'zoom', 'value': factor});
}

class VenueMap3DView extends StatefulWidget {
  const VenueMap3DView({
    required this.controller,
    required this.active,
    required this.selected,
    required this.onSelected,
    required this.onUseTwoD,
    super.key,
  });

  final VenueMap3DController controller;
  final bool active;
  final VenuePlace? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onUseTwoD;

  @override
  State<VenueMap3DView> createState() => _VenueMap3DViewState();
}

class _VenueMap3DViewState extends State<VenueMap3DView> {
  bool _loading = true;
  bool _error = false;
  int _generation = 0;
  Timer? _loadTimeout;

  @override
  void initState() {
    super.initState();
    _startLoadTimeout();
  }

  void _startLoadTimeout() {
    _loadTimeout?.cancel();
    _loadTimeout = Timer(const Duration(seconds: 20), () => _onMessage({'type': 'error'}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  @override
  void didUpdateWidget(VenueMap3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configure();
  }

  void _configure() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    String hex(Color color) => '#${color.toARGB32().toRadixString(16).substring(2)}';
    widget.controller.configure({
      'action': 'configure',
      'active': widget.active,
      'selected': widget.selected?.id,
      'language': Localizations.localeOf(context).languageCode,
      'textScale': MediaQuery.textScalerOf(context).scale(12) / 12,
      'colors': {
        'surface': hex(colors.surface),
        'background': hex(colors.surfaceContainerLowest),
        'service': hex(colors.surfaceContainerHighest),
        'onSurface': hex(colors.onSurface),
        'outline': hex(colors.outlineVariant),
        'primary': hex(colors.primary),
        'primaryContainer': hex(colors.primaryContainer),
        'onPrimaryContainer': hex(colors.onPrimaryContainer),
        'secondary': hex(colors.secondary),
        'onSecondaryContainer': hex(colors.onSecondaryContainer),
        'tertiary': hex(colors.tertiary),
        'onTertiaryContainer': hex(colors.onTertiaryContainer),
        'onSurfaceVariant': hex(colors.onSurfaceVariant),
        'dark': colors.brightness == Brightness.dark,
      },
    });
  }

  void _onMessage(Map<String, Object?> message) {
    if (!mounted) {
      return;
    }
    switch (message['type']) {
      case 'loaded':
        _loadTimeout?.cancel();
        setState(() => _loading = false);
      case 'error':
        _loadTimeout?.cancel();
        widget.controller.disconnect();
        setState(() => _error = true);
      case 'selected':
        if (message['id'] case final String id) {
          widget.onSelected(id);
        }
    }
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    widget.controller.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (_error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 32),
              const SizedBox(height: 16),
              Text(t.venueMap.loadError, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: widget.onUseTwoD, child: Text(t.venueMap.useTwoD)),
              TextButton(
                onPressed: () => setState(() {
                  _generation++;
                  _error = false;
                  _loading = true;
                  _startLoadTimeout();
                }),
                child: Text(t.error.retry),
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        VenueMap3DSurface(
          key: ValueKey(_generation),
          interactive: widget.active,
          onReady: widget.controller.connect,
          onMessage: _onMessage,
        ),
        if (_loading)
          ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: const Center(child: CircularProgressIndicator.adaptive()),
          ),
      ],
    );
  }
}
