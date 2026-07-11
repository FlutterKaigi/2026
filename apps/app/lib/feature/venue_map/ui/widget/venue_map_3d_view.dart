import 'dart:async';
import 'dart:convert';

import 'package:app/core/i18n/strings.g.dart';
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
              _loadError = error.description;
            });
          },
        ),
      );
      await _loadMap(updateState: false);
    } on Object catch (error) {
      _showLoadError('Could not initialize the map WebView: $error');
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
    } on Object catch (error) {
      _showLoadError('Could not load the local map asset: $error');
    }
  }

  void _retryLoadMap() {
    unawaited(_loadMap());
  }

  void _showLoadError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _loadError = message;
    });
  }

  bool _isCriticalWebResourceError(WebResourceError error) {
    final url = error.url;
    return error.isForMainFrame == true ||
        url == null ||
        url.contains(_assetPath) ||
        url.contains('cdn.jsdelivr.net/npm/three');
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
        setState(() => _loadError = 'Could not run map command: $error');
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
        _MapControlBar(
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
                child: _MapViewport(
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

class _MapControlBar extends StatelessWidget {
  const _MapControlBar({
    required this.enabled,
    required this.onCommand,
  });

  final bool enabled;
  final ValueChanged<String> onCommand;

  @override
  Widget build(BuildContext context) {
    final groups = _controlGroups(context.t);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final group in groups) ...[
                _MapControlGroupView(
                  group: group,
                  enabled: enabled,
                  onCommand: onCommand,
                ),
                if (group != groups.last) const SizedBox(width: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_MapControlGroup> _controlGroups(Translations t) {
    final controls = t.venueMap.controls;
    return [
      _MapControlGroup(
        label: controls.view.title,
        controls: [
          _MapControl(
            label: controls.view.threeD,
            icon: Icons.view_in_ar_outlined,
            javaScript: 'window.FloorPlan3D.view3D()',
          ),
          _MapControl(
            label: controls.view.top,
            icon: Icons.vertical_align_top,
            javaScript: 'window.FloorPlan3D.topView()',
          ),
        ],
      ),
      _MapControlGroup(
        label: controls.highlight.title,
        controls: [
          _MapControl(
            label: controls.highlight.mainHalls,
            icon: Icons.event_seat_outlined,
            javaScript: 'window.FloorPlan3D.highlightMainHalls()',
          ),
          _MapControl(
            label: controls.highlight.exhibitionHalls,
            icon: Icons.storefront_outlined,
            javaScript: 'window.FloorPlan3D.highlightExhibitionHalls()',
          ),
          _MapControl(
            label: controls.highlight.grandHalls,
            icon: Icons.meeting_room_outlined,
            javaScript: 'window.FloorPlan3D.highlightGrandHalls()',
          ),
          _MapControl(
            label: controls.highlight.toilets,
            icon: Icons.wc,
            javaScript: 'window.FloorPlan3D.highlightToilets()',
          ),
          _MapControl(
            label: controls.highlight.elevators,
            icon: Icons.elevator_outlined,
            javaScript: 'window.FloorPlan3D.highlightElevators()',
          ),
          _MapControl(
            label: controls.highlight.entrance,
            icon: Icons.login,
            javaScript: 'window.FloorPlan3D.highlightEntranceArea()',
          ),
        ],
      ),
      _MapControlGroup(
        label: controls.labels.title,
        controls: [
          _MapControl(
            label: controls.labels.hide,
            icon: Icons.label_off_outlined,
            javaScript: 'window.FloorPlan3D.hideAllLabels()',
          ),
          _MapControl(
            label: controls.labels.show,
            icon: Icons.label_outline,
            javaScript: 'window.FloorPlan3D.showAllLabels()',
          ),
          _MapControl(
            label: controls.labels.decreaseSize,
            icon: Icons.text_decrease,
            javaScript: 'void window.FloorPlan3D.decreaseLabelSize()',
          ),
          _MapControl(
            label: controls.labels.increaseSize,
            icon: Icons.text_increase,
            javaScript: 'void window.FloorPlan3D.increaseLabelSize()',
          ),
        ],
      ),
    ];
  }
}

class _MapControlGroupView extends StatelessWidget {
  const _MapControlGroupView({
    required this.group,
    required this.enabled,
    required this.onCommand,
  });

  final _MapControlGroup group;
  final bool enabled;
  final ValueChanged<String> onCommand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          group.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final control in group.controls) ...[
              _MapControlButton(
                control: control,
                enabled: enabled,
                onCommand: onCommand,
              ),
              if (control != group.controls.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.control,
    required this.enabled,
    required this.onCommand,
  });

  final _MapControl control;
  final bool enabled;
  final ValueChanged<String> onCommand;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: enabled
          ? () async {
              await _ensureFullyVisible(context);
              if (!context.mounted) {
                return;
              }
              onCommand(control.javaScript);
            }
          : null,
      icon: Icon(control.icon, size: 18),
      label: Text(
        control.label,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _ensureFullyVisible(BuildContext context) async {
    const duration = Duration(milliseconds: 180);
    const curve = Curves.easeOutCubic;

    await Scrollable.ensureVisible(
      context,
      duration: duration,
      curve: curve,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
    if (!context.mounted) {
      return;
    }
    await Scrollable.ensureVisible(
      context,
      duration: duration,
      curve: curve,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }
}

class _MapViewport extends StatelessWidget {
  const _MapViewport({
    required this.controller,
    required this.isLoading,
    required this.loadError,
    required this.onRetry,
  });

  final WebViewController controller;
  final bool isLoading;
  final String? loadError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: colorScheme.surface,
          child: loadError == null
              ? Stack(
                  children: [
                    WebViewWidget(controller: controller),
                    if (isLoading) const _MapLoadingState(),
                  ],
                )
              : _MapErrorState(
                  message: loadError!,
                  onRetry: onRetry,
                ),
        ),
      ),
    );
  }
}

class _MapLoadingState extends StatelessWidget {
  const _MapLoadingState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surface.withValues(alpha: 0.86),
      child: const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }
}

class _MapErrorState extends StatelessWidget {
  const _MapErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_outlined,
                    color: colorScheme.error,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.venueMap.loadError,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(t.common.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapControlGroup {
  const _MapControlGroup({
    required this.label,
    required this.controls,
  });

  final String label;
  final List<_MapControl> controls;
}

class _MapControl {
  const _MapControl({
    required this.label,
    required this.icon,
    required this.javaScript,
  });

  final String label;
  final IconData icon;
  final String javaScript;
}
