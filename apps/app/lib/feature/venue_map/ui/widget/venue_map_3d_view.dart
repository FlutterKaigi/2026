import 'dart:async';
import 'dart:convert';

import 'package:app/feature/venue_map/ui/widget/venue_map_control_bar_widget.dart';
import 'package:app/feature/venue_map/ui/widget/venue_map_viewport_widget.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VenueMap3DView extends StatefulWidget {
  const VenueMap3DView({
    required this.languageCode,
    super.key,
  });

  final String languageCode;

  @override
  State<VenueMap3DView> createState() => _VenueMap3DViewState();
}

class _VenueMap3DViewState extends State<VenueMap3DView> {
  static const _assetPath = 'assets/html/venue_floor_plan_webview.html';

  late final WebViewController _controller;
  bool _isLoading = true;
  String? _loadError;
  String? _labelLanguageCode;
  double? _viewportWidth;
  String? _surfaceColorHex;

  bool get _canRunCommands => !_isLoading && _loadError == null;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    unawaited(_configureAndLoadMap());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMapSurfaceColor();
    _syncLabelLanguage();
  }

  @override
  void didUpdateWidget(covariant VenueMap3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.languageCode != widget.languageCode) {
      _syncLabelLanguage();
    }
  }

  Future<void> _configureAndLoadMap() async {
    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isLoading = true;
              _loadError = null;
              _surfaceColorHex = null;
              _labelLanguageCode = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted || _loadError != null) {
              return;
            }
            setState(() => _isLoading = false);
            _syncMapSurfaceColor();
            _syncLabelLanguage();
            _fitMapToViewportWidth();
          },
          onWebResourceError: (error) {
            if (!mounted || !_isCriticalWebResourceError(error)) {
              return;
            }
            setState(() {
              _isLoading = false;
              _loadError = 'web-resource-error';
            });
          },
        ),
      );
      await _loadMap(updateState: false);
    } on Object catch (_) {
      _showLoadError();
    }
  }

  Future<void> _loadMap({bool updateState = true}) async {
    if (updateState) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      await _controller.loadFlutterAsset(_assetPath);
    } on Object catch (_) {
      _showLoadError();
    }
  }

  void _retryLoadMap() {
    unawaited(_loadMap());
  }

  void _showLoadError() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _loadError = 'load-error';
    });
  }

  bool _isCriticalWebResourceError(WebResourceError error) {
    final url = error.url;
    return error.isForMainFrame == true || url == null || url.contains(_assetPath);
  }

  void _runMapCommand(String javaScript) {
    if (!_canRunCommands) {
      return;
    }

    unawaited(
      _controller.runJavaScript(javaScript).catchError((Object error) {
        if (!mounted) {
          return;
        }
        setState(() => _loadError = 'map-command-error');
      }),
    );
  }

  void _updateViewportWidth(double width) {
    if (width <= 0 || (_viewportWidth != null && (width - _viewportWidth!).abs() < 1)) {
      return;
    }
    _viewportWidth = width;
    _fitMapToViewportWidth();
  }

  void _fitMapToViewportWidth() {
    final width = _viewportWidth;
    if (!_canRunCommands || width == null) {
      return;
    }

    final javaScript =
        '''
if (window.FloorPlan3D && window.FloorPlan3D.fitToScreenWidth) {
  window.FloorPlan3D.fitToScreenWidth(${width.toStringAsFixed(1)});
}
''';
    unawaited(_controller.runJavaScript(javaScript).catchError((Object _) {}));
  }

  void _syncLabelLanguage() {
    if (!_canRunCommands) {
      return;
    }

    final languageCode = widget.languageCode == 'ja' ? 'ja' : 'en';
    if (languageCode == _labelLanguageCode) {
      return;
    }
    _labelLanguageCode = languageCode;

    final encodedLanguageCode = jsonEncode(languageCode);
    final javaScript =
        '''
window.__venueMapLanguage = $encodedLanguageCode;
if (window.FloorPlan3D && window.FloorPlan3D.setLabelLanguage) {
  window.FloorPlan3D.setLabelLanguage($encodedLanguageCode);
}
''';
    unawaited(_controller.runJavaScript(javaScript).catchError((Object _) {}));
  }

  void _syncMapSurfaceColor() {
    if (!_canRunCommands) {
      return;
    }

    final surfaceColorHex = _colorToCssHex(Theme.of(context).colorScheme.surface);
    if (surfaceColorHex == _surfaceColorHex) {
      return;
    }
    _surfaceColorHex = surfaceColorHex;

    final javaScript =
        '''
window.__venueMapSurfaceColor = '$surfaceColorHex';
document.documentElement.style.setProperty('--venue-map-surface', '$surfaceColorHex');
if (window.FloorPlan3D && window.FloorPlan3D.setSurfaceColor) {
  window.FloorPlan3D.setSurfaceColor('$surfaceColorHex');
}
''';
    unawaited(_controller.runJavaScript(javaScript).catchError((Object _) {}));
  }

  String _colorToCssHex(Color color) {
    final rgb = color.toARGB32() & 0x00ffffff;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        VenueMapControlBarWidget(
          enabled: _canRunCommands,
          onCommand: _runMapCommand,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                _updateViewportWidth(constraints.maxWidth);
              });

              return Padding(
                padding: EdgeInsets.zero,
                child: VenueMapViewportWidget(
                  controller: _controller,
                  isLoading: _isLoading,
                  loadError: _loadError,
                  onRetry: _retryLoadMap,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
