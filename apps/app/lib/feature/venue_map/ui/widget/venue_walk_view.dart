import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';
import 'package:app/feature/venue_map/data/venue_walk_scene.dart';
import 'package:app/feature/venue_map/provider/venue_walk_scene_factory.dart';
import 'package:app/feature/venue_map/ui/widget/venue_scene_viewport.dart';
import 'package:app/feature/venue_map/ui/widget/venue_walk_controller.dart';
import 'package:app/feature/venue_map/ui/widget/venue_walk_photo_studio.dart';
import 'package:app/feature/venue_map/ui/widget/venue_walk_run_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class VenueWalkView extends ConsumerStatefulWidget {
  const VenueWalkView({
    required this.controller,
    required this.active,
    required this.onUseTwoD,
    this.showcase = true,
    super.key,
  });
  final VenueWalkController controller;
  final bool active;
  final VoidCallback onUseTwoD;
  final bool showcase;
  @override
  ConsumerState<VenueWalkView> createState() => _VenueWalkViewState();
}

class _VenueWalkViewState extends ConsumerState<VenueWalkView> {
  VenueWalkScene? game;
  Object? error;
  final focus = FocusNode(debugLabel: 'Venue walking controls');
  late final AppLifecycleListener lifecycle;
  bool ready = false;
  double lastScale = 1;
  bool _foreground = true;
  bool _tickerEnabled = true;
  bool _helpOpen = false;

  ColorScheme get colors => Theme.of(context).colorScheme;
  bool get _active => widget.active && _foreground && _tickerEnabled && !_helpOpen;

  void _syncActivity() {
    final g = game;
    if (g == null) {
      return;
    }
    if (!_active) {
      widget.controller.disconnect();
      if (!g.paused && ready) {
        g.stop();
      }
    }
    g.paused = !_active;
    if (!_active) {
      focus.unfocus();
    } else if (ready) {
      widget.controller.connect(g.goToPlace);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    game?.setDarkMode(dark: Theme.of(context).brightness == Brightness.dark);
    _syncActivity();
  }

  @override
  void didUpdateWidget(VenueWalkView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.disconnect();
    }
    _syncActivity();
  }

  @override
  void initState() {
    super.initState();
    lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _foreground = state == AppLifecycleState.resumed;
        _syncActivity();
        if (mounted) {
          setState(() {});
        }
      },
    );
    unawaited(load());
  }

  Future<void> load() async {
    final next = ref.read(venueWalkSceneFactoryProvider)(showcase: widget.showcase);
    game?.dispose();
    game = next;
    try {
      await next.load().timeout(const Duration(seconds: 30));
      if (!mounted || game != next) {
        return;
      }
      next.setDarkMode(dark: Theme.of(context).brightness == Brightness.dark);
      setState(() {
        ready = true;
        error = null;
      });
      _syncActivity();
    } on Object catch (e, stack) {
      debugPrint('Venue walk failed: $e\n$stack');
      if (game == next) {
        game = null;
        next.dispose();
      }
      if (mounted) {
        setState(() {
          ready = false;
          error = e;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.controller.disconnect();
    lifecycle.dispose();
    focus.dispose();
    game?.dispose();
    super.dispose();
  }

  KeyEventResult onKey(FocusNode node, KeyEvent event) {
    if (!ready || !_active) {
      return KeyEventResult.ignored;
    }
    final g = game!;
    final key = event.logicalKey;
    if (g.photoMode) {
      if (key == LogicalKeyboardKey.escape && event is KeyDownEvent) {
        closePhoto();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final movementKeys = {
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    };
    if (movementKeys.contains(key)) {
      if (event is KeyUpEvent) {
        g.keys.remove(key);
      } else {
        g.keys.add(key);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (event is KeyDownEvent) {
        g.stop();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void action(VoidCallback callback) {
    callback();
    focus.requestFocus();
  }

  void openPhoto() {
    game!.enterPhotoMode();
    setState(() {});
    focus.requestFocus();
  }

  void closePhoto() {
    game!.exitPhotoMode();
    setState(() {});
    focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: focus,
    canRequestFocus: _active,
    onKeyEvent: onKey,
    onFocusChange: (focused) {
      if (!focused && ready) {
        // A closing search sheet can transfer focus after its destination was
        // selected. Release held controls without cancelling that new route.
        game!.releaseInput();
      }
    },
    child: IgnorePointer(
      ignoring: !_active,
      child: !ready
          ? Center(
              child: error == null
                  ? const CircularProgressIndicator.adaptive()
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(context.t.venueMap.loadError),
                          const SizedBox(height: 12),
                          FilledButton.tonal(onPressed: widget.onUseTwoD, child: Text(context.t.venueMap.useTwoD)),
                          TextButton(
                            onPressed: () {
                              setState(() => error = null);
                              unawaited(load());
                            },
                            child: Text(context.t.error.retry),
                          ),
                        ],
                      ),
                    ),
            )
          : game!.photoMode
          ? VenueWalkPhotoStudio(game: game!, onClose: closePhoto)
          : LayoutBuilder(
              builder: (context, box) {
                final landscape = box.maxHeight < 360 && box.maxWidth > box.maxHeight;
                return viewport(
                  wide: box.maxWidth >= 900,
                  compact: box.maxWidth < 600 || landscape,
                  landscape: landscape,
                );
              },
            ),
    ),
  );

  Widget viewport({required bool wide, required bool compact, required bool landscape}) {
    final g = game!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(wide ? 24 : 20),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: LayoutBuilder(
          builder: (context, box) {
            final size = box.biggest;
            g.viewAspect = size.width / size.height;
            g.compactView = compact;
            return Stack(
              fit: StackFit.expand,
              children: [
                Semantics(
                  label: 'だしゅまると会場さんぽ。スティック、床のタップ、または矢印キーで歩けます。',
                  child: Listener(
                    onPointerDown: (_) => focus.requestFocus(),
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        GestureBinding.instance.pointerSignalResolver.register(
                          event,
                          (_) => g.zoom(math.exp(event.scrollDelta.dy * .0015)),
                        );
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) => g.tapFloor(details.localPosition, size),
                      onScaleStart: (_) => lastScale = 1,
                      onScaleUpdate: (details) {
                        if (details.pointerCount > 1) {
                          g.zoom(lastScale / details.scale);
                          lastScale = details.scale;
                        } else {
                          g.orbit(details.focalPointDelta);
                        }
                      },
                      child: VenueSceneViewport(
                        game: g,
                        pixelRatio: math.min(MediaQuery.devicePixelRatioOf(context), 1.5),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: HallLabels(
                      g,
                      colors: Theme.of(context).colorScheme,
                      overviewTopInset: landscape
                          ? 80
                          : compact
                          ? 140
                          : 180,
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: ValueListenableBuilder<WalkStatus>(
                    valueListenable: g.status,
                    builder: (context, s, _) {
                      if (s.location == null && s.destination == null && s.notice == null) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        constraints: BoxConstraints(
                          maxWidth:
                              size.width -
                              (landscape
                                  ? widget.showcase
                                        ? 244
                                        : 140
                                  : wide
                                  ? 228
                                  : compact
                                  ? 92
                                  : 150),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (s.location != null) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ただいま',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(s.location!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                            if (s.destination != null)
                              Text(
                                '${s.destination}へ移動中',
                                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary),
                              ),
                            if (s.notice != null)
                              Text(
                                s.notice!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: s.motion == 'そこへは移動できません'
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (!compact)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: wide ? 178 : 110,
                      height: wide ? 91 : 63,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: CustomPaint(painter: MiniMap(g, Theme.of(context).colorScheme)),
                    ),
                  ),
                if (widget.showcase && !landscape)
                  Positioned(
                    left: 16,
                    top: 108,
                    child: _WalkOnly(
                      game: g,
                      child: Row(
                        children: [
                          _SurfaceButton(tooltip: '撮影モード', icon: Icons.photo_camera_outlined, onPressed: openPhoto),
                          const SizedBox(width: 8),
                          _SurfaceButton(
                            tooltip: 'フォトスポットへ歩く',
                            icon: Icons.add_photo_alternate_outlined,
                            onPressed: () => action(() => g.goTo(g.decorations!.layout.photoSpot, name: 'クリエイティブボード')),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  right: 16,
                  top: compact
                      ? 16
                      : wide
                      ? 117
                      : 89,
                  child: ValueListenableBuilder<WalkStatus>(
                    valueListenable: g.status,
                    builder: (context, s, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (landscape && widget.showcase)
                          _WalkOnly(
                            game: g,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _SurfaceButton(
                                  tooltip: '撮影モード',
                                  icon: Icons.photo_camera_outlined,
                                  onPressed: openPhoto,
                                ),
                                const SizedBox(width: 8),
                                _SurfaceButton(
                                  tooltip: 'フォトスポットへ歩く',
                                  icon: Icons.add_photo_alternate_outlined,
                                  onPressed: () =>
                                      action(() => g.goTo(g.decorations!.layout.photoSpot, name: 'クリエイティブボード')),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        _SurfaceButton(
                          tooltip: s.overview ? 'だしゅまるを追う' : 'フロア全体を見る',
                          icon: s.overview ? Icons.person_pin_circle_outlined : Icons.map_outlined,
                          label: compact
                              ? null
                              : s.overview
                              ? '追いかける'
                              : '全体を見る',
                          onPressed: () => action(g.toggleOverview),
                        ),
                        if (landscape) ...[
                          const SizedBox(width: 8),
                          _SurfaceButton(
                            tooltip: '遊び方',
                            icon: Icons.help_outline,
                            onPressed: () => showAbout(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!landscape)
                  Positioned(
                    right: 16,
                    top: compact ? 68 : (wide ? 169 : 141),
                    child: _SurfaceButton(
                      tooltip: '遊び方',
                      icon: Icons.help_outline,
                      onPressed: () => showAbout(context),
                    ),
                  ),
                Positioned(
                  left: 18,
                  bottom: landscape ? 12 : 18,
                  child: _WalkOnly(
                    game: g,
                    child: Column(
                      children: [
                        ValueListenableBuilder<Offset>(
                          valueListenable: g.stickInput,
                          builder: (context, value, _) => Joystick(
                            value: value,
                            onChanged: (value) {
                              g.stick = value;
                              focus.requestFocus();
                            },
                          ),
                        ),
                        if (!landscape) ...[
                          const SizedBox(height: 5),
                          Text(
                            'スティックで歩く',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: landscape ? 12 : 18,
                  child: ValueListenableBuilder<WalkStatus>(
                    valueListenable: g.status,
                    builder: (context, s, _) => s.overview
                        ? const SizedBox.shrink()
                        : Flex(
                            direction: landscape ? Axis.horizontal : Axis.vertical,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (s.destination != null) ...[
                                _SurfaceButton(
                                  tooltip: '移動を止める',
                                  icon: Icons.stop_rounded,
                                  label: compact ? null : 'ここで止まる',
                                  onPressed: () => action(g.stop),
                                ),
                                SizedBox(width: landscape ? 8 : 0, height: landscape ? 0 : 8),
                              ],
                              _SurfaceButton(
                                tooltip: '入口に戻る',
                                icon: Icons.restart_alt,
                                onPressed: () => action(g.reset),
                              ),
                              SizedBox(width: landscape ? 8 : 0, height: landscape ? 0 : 8),
                              _SurfaceButton(
                                tooltip: '手をふる',
                                icon: Icons.waving_hand_outlined,
                                label: compact ? null : '手をふる',
                                onPressed: () => action(g.wave),
                              ),
                              SizedBox(width: landscape ? 10 : 0, height: landscape ? 0 : 10),
                              VenueWalkRunButton(
                                pressed: s.running,
                                onChanged: (value) => action(() => g.setSprintHeld(pressed: value)),
                              ),
                            ],
                          ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: ValueListenableBuilder<WalkStatus>(
                    valueListenable: g.status,
                    builder: (context, s, _) => s.overview
                        ? Center(
                            child: _SurfaceButton(
                              tooltip: 'さんぽに戻る',
                              label: 'さんぽに戻る',
                              icon: Icons.pets_outlined,
                              onPressed: () => action(g.toggleOverview),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> showAbout(BuildContext context) async {
    setState(() => _helpOpen = true);
    _syncActivity();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('会場さんぽの遊び方'),
        scrollable: true,
        content: Text(
          '左下のスティックで歩きます。右下の走るアイコンを押している間は走り、離すと歩く速さに戻ります。\n\n'
          '背景をドラッグして見回し、ピンチで近づいたり離れたりできます。床をタップすると、その場所まで自動で歩きます。\n\n'
          '「場所を探す」で行き先を選んで、4つのホールを巡ってみましょう。地図アイコンで会場全体を見渡せます。\n\n'
          '${widget.showcase ? 'カメラで記念撮影。隣の写真アイコンを押すと、クリエイティブボードの前まで歩きます。ポーズやフレームを選んで撮影できます。\n\n' : ''}'
          'パソコンでは W A S D または矢印キーで移動、Shiftを押している間は走り、Escで止まります。\n\n'
          '5階の会場を散歩できます。実際の現在地を示すものではなく、エスカレーターでの階移動はできません。\n\n'
          '3Dモデル: yakitama5 / flutter_deck_slides\nだしゅまる: FlutterKaigi',
          style: const TextStyle(fontSize: 13, height: 1.8),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _helpOpen = false);
    _syncActivity();
  }
}

class _WalkOnly extends StatelessWidget {
  const _WalkOnly({required this.game, required this.child});
  final VenueWalkScene game;
  final Widget child;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<WalkStatus>(
    valueListenable: game.status,
    child: child,
    builder: (context, state, child) => state.overview ? const SizedBox.shrink() : child!,
  );
}

class _SurfaceButton extends StatelessWidget {
  const _SurfaceButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.label,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
                if (label != null) ...[
                  const SizedBox(width: 7),
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class Joystick extends StatefulWidget {
  const Joystick({required this.value, required this.onChanged, super.key});
  final Offset value;
  final ValueChanged<Offset> onChanged;
  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  int? pointer;
  @override
  void didUpdateWidget(Joystick oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset/backgrounding cancels a held touch as well as its visual offset.
    if (widget.value == Offset.zero && oldWidget.value != Offset.zero) {
      pointer = null;
    }
  }

  void move(Offset local) {
    var delta = local - const Offset(52, 52);
    if (delta.distance > 34) {
      delta = delta / delta.distance * 34;
    }
    widget.onChanged(delta / 34);
  }

  void release() {
    pointer = null;
    widget.onChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'だしゅまるを動かすスティック',
    child: Listener(
      onPointerDown: (e) {
        if (pointer == null) {
          pointer = e.pointer;
          move(e.localPosition);
        }
      },
      onPointerMove: (e) {
        if (pointer == e.pointer) {
          move(e.localPosition);
        }
      },
      onPointerUp: (e) {
        if (pointer == e.pointer) {
          release();
        }
      },
      onPointerCancel: (e) {
        if (pointer == e.pointer) {
          release();
        }
      },
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: .78),
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 5,
              child: Icon(Icons.keyboard_arrow_up, size: 19, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            Positioned(
              bottom: 5,
              child: Icon(Icons.keyboard_arrow_down, size: 19, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            Positioned(
              left: 5,
              child: Icon(Icons.keyboard_arrow_left, size: 19, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            Positioned(
              right: 5,
              child: Icon(Icons.keyboard_arrow_right, size: 19, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            Transform.translate(
              offset: widget.value * 34,
              child: Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: .18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(Icons.pets_outlined, color: Theme.of(context).colorScheme.onPrimary, size: 20),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class HallLabels extends CustomPainter {
  HallLabels(this.game, {required this.colors, required this.overviewTopInset}) : super(repaint: game);
  final VenueWalkScene game;
  final double overviewTopInset;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    if (game.showcase && !game.overview) {
      return;
    }
    final placed = <Rect>[];
    for (final p in game.navigation.places.where((p) => p.type == 'hall' || p.type == 'sponsor')) {
      // The current hall is named in the HUD. Leave the mascot's face visible.
      if (!game.overview && game.position.distanceTo(p.anchor) < 55) {
        continue;
      }
      if (p.type == 'sponsor' && (game.overview || game.position.distanceTo(p.anchor) > 190)) {
        continue;
      }
      final offset = game.camera.worldToScreen(game.world(p.anchor, p.type == 'hall' ? 1.05 : .72), size);
      if (offset == null ||
          (!game.overview &&
              (offset.dx < 20 || offset.dx > size.width - 20 || offset.dy < 110 || offset.dy > size.height - 160))) {
        continue;
      }
      final tp = TextPainter(
        text: TextSpan(
          text: p.number?.toString() ?? p.name,
          style: TextStyle(
            fontFamily: 'Noto Sans JP',
            fontSize: p.number != null ? 10 : 12,
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final center = game.overview
          ? Offset(
              offset.dx.clamp(tp.width / 2 + 20, size.width - tp.width / 2 - 20),
              offset.dy.clamp(overviewTopInset, math.max(overviewTopInset, size.height - 80)),
            )
          : offset;
      var r = Rect.fromCenter(center: center, width: tp.width + 18, height: tp.height + 12);
      if (game.overview) {
        // Narrow overview projections put neighbouring halls close together.
        // Place their labels separately and connect displaced labels to halls.
        final bounds = Rect.fromLTRB(12, overviewTopInset - r.height / 2, size.width - 12, size.height - 64);
        final candidates = [
          r,
          for (final other in placed) ...[
            r.translate(other.right + 8 - r.left, 0),
            r.translate(other.left - 8 - r.right, 0),
            r.translate(0, other.bottom + 8 - r.top),
            r.translate(0, other.top - 8 - r.bottom),
          ],
        ]..sort((a, b) => (a.center - center).distanceSquared.compareTo((b.center - center).distanceSquared));
        for (final candidate in candidates) {
          if (candidate.left >= bounds.left &&
              candidate.top >= bounds.top &&
              candidate.right <= bounds.right &&
              candidate.bottom <= bounds.bottom &&
              placed.every((other) => !candidate.inflate(4).overlaps(other))) {
            r = candidate;
            break;
          }
        }
        placed.add(r);
      }
      if ((r.center - offset).distance > 12) {
        canvas.drawLine(
          offset,
          r.center,
          Paint()
            ..color = colors.primary.withValues(alpha: .5)
            ..strokeWidth = 1,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        Paint()..color = colors.surfaceContainerHigh.withValues(alpha: .93),
      );
      tp.paint(canvas, Offset(r.left + 9, r.top + 6));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(HallLabels oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.game != game || oldDelegate.overviewTopInset != overviewTopInset;
}

class MiniMap extends CustomPainter {
  MiniMap(this.game, this.colors) : super(repaint: game);
  final VenueWalkScene game;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 1774, size.height / 810);
    final origin = Offset((size.width - 1774 * scale) / 2, (size.height - 810 * scale) / 2);
    Offset project(MapPoint p) => origin + Offset(p.x * scale, p.y * scale);
    for (final hall in game.navigation.places.where((p) => p.type == 'hall')) {
      canvas.drawPath(
        Path()..addPolygon(hall.polygon.map(project).toList(), true),
        Paint()..color = colors.secondaryContainer,
      );
    }
    for (final (a, b) in game.navigation.walls) {
      canvas.drawLine(
        project(a),
        project(b),
        Paint()
          ..color = colors.outline
          ..strokeWidth = .7,
      );
    }
    if (game.path.isNotEmpty) {
      final path = Path()..addPolygon([project(game.position), ...game.path.map(project)], false);
      canvas.drawPath(
        path,
        Paint()
          ..color = colors.primary.withValues(alpha: .5)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
    }
    final at = project(game.position);
    canvas.drawCircle(at, 6, Paint()..color = colors.primary.withValues(alpha: .15));
    canvas.drawCircle(at, 3, Paint()..color = colors.primary);
    canvas.drawCircle(at, 1.2, Paint()..color = colors.onPrimary);
  }

  @override
  bool shouldRepaint(MiniMap oldDelegate) => oldDelegate.colors != colors || oldDelegate.game != game;
}
