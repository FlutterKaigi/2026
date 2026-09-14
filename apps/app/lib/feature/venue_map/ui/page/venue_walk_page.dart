import 'dart:async';
import 'dart:math' as math;

import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';
import 'package:app/feature/venue_map/data/venue_walk_scene.dart';
import 'package:app/feature/venue_map/ui/widget/venue_walk_photo_studio.dart';
import 'package:app/feature/venue_map/ui/widget/venue_walk_run_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart' as fs;

const ink = Color(0xff163c35);
const green = Color(0xff257c67);
const muted = Color(0xff71827e);
const canvas = Color(0xfff4f7f3);

class VenueWalkPage extends StatefulWidget {
  const VenueWalkPage({this.showcase = false, super.key});
  final bool showcase;
  @override
  State<VenueWalkPage> createState() => _VenueWalkPageState();
}

class _VenueWalkPageState extends State<VenueWalkPage> {
  VenueWalkScene? game;
  Object? error;
  final focus = FocusNode(debugLabel: 'Venue walking controls');
  late final AppLifecycleListener lifecycle;
  bool ready = false;
  double lastScale = 1;

  @override
  void initState() {
    super.initState();
    lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (!ready) {
          return;
        }
        final paused = state != AppLifecycleState.resumed;
        if (paused) {
          game!.stop();
        }
        game!.paused = paused;
        if (mounted) {
          setState(() {});
        }
      },
    );
    unawaited(load());
  }

  Future<void> load() async {
    final next = VenueWalkScene(showcase: widget.showcase);
    game = next;
    try {
      await next.load();
      if (!mounted) {
        return;
      }
      setState(() {
        ready = true;
        error = null;
      });
      focus.requestFocus();
    } on Object catch (e, stack) {
      debugPrint('Venue walk failed: $e\n$stack');
      if (mounted) {
        setState(() => error = e);
      }
    }
  }

  @override
  void dispose() {
    lifecycle.dispose();
    focus.dispose();
    game?.dispose();
    super.dispose();
  }

  KeyEventResult onKey(FocusNode node, KeyEvent event) {
    if (!ready) {
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

  Future<void> chooseDestination(BuildContext context) async {
    final g = game!;
    g.stop();
    final place = await showModalBottomSheet<MapPlace>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('どこまで歩こう？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('訪れたホール ${g.visited.length} / 4', style: const TextStyle(color: green, fontSize: 12)),
                  ],
                ),
              ),
              for (final place in g.navigation.places.where((p) => p.type == 'hall'))
                ListTile(
                  leading: const Icon(Icons.directions_walk_rounded),
                  title: Text(place.name),
                  subtitle: g.visited.contains(place.id) ? const Text('訪問済み') : null,
                  trailing: Icon(g.visited.contains(place.id) ? Icons.check_circle_outline : Icons.chevron_right),
                  onTap: () => Navigator.pop(context, place),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    if (place != null) {
      g.goTo(place.anchor, name: place.name);
    }
    focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: green),
      scaffoldBackgroundColor: canvas,
      fontFamily: 'Noto Sans JP',
      useMaterial3: true,
    ),
    child: Focus(
      focusNode: focus,
      autofocus: true,
      onKeyEvent: onKey,
      onFocusChange: (value) {
        if (!value && ready) {
          game!.stop();
        }
      },
      child: ready && game!.photoMode
          ? VenueWalkPhotoStudio(game: game!, onClose: closePhoto)
          : Scaffold(
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final landscape = box.maxHeight < 500 && box.maxWidth > box.maxHeight;
                    final wide = box.maxWidth >= 900 && !landscape;
                    final compact = box.maxWidth < 600 || landscape;
                    return Padding(
                      padding: EdgeInsets.all(
                        landscape
                            ? 8
                            : wide
                            ? 24
                            : 12,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              if (Navigator.of(context).canPop()) ...[
                                const BackButton(),
                                const SizedBox(width: 4),
                              ],
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.explore_outlined, color: Color(0xffd4efc1)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'FlutterKaigi 2026  /  5F',
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 1.4,
                                        color: muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'だしゅまると、会場さんぽ。',
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: wide
                                              ? 25
                                              : compact
                                              ? 16
                                              : 18,
                                          fontWeight: FontWeight.w700,
                                          color: ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (wide) const _Tag('3D DEMO'),
                              const SizedBox(width: 6),
                              IconButton(
                                tooltip: '遊び方とこのデモについて',
                                onPressed: () => showAbout(context),
                                icon: const Icon(Icons.info_outline, size: 21),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: landscape
                                ? 8
                                : wide
                                ? 22
                                : 14,
                          ),
                          Expanded(
                            child: !ready
                                ? loading()
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (wide) ...[SizedBox(width: 246, child: sidebar()), const SizedBox(width: 22)],
                                      Expanded(
                                        child: viewport(wide: wide, compact: compact, landscape: landscape),
                                      ),
                                    ],
                                  ),
                          ),
                          if (ready && !wide && !compact)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: SizedBox(
                                height: 44,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    for (final place in game!.navigation.places.where((p) => p.type == 'hall'))
                                      Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: OutlinedButton(
                                          onPressed: () => action(() => game!.goTo(place.anchor, name: place.name)),
                                          child: Text(place.name, style: const TextStyle(fontSize: 11)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          if (!landscape) ...[
                            SizedBox(height: wide ? 14 : 9),
                            Text(
                              wide
                                  ? '床をクリックして移動  ·  ドラッグで視点を回転  ·  ホイールで拡大・縮小'
                                  : compact
                                  ? 'ドラッグで見回す  ·  ピンチで近づく'
                                  : '床をタップして移動  ·  ドラッグで視点を回転',
                              style: TextStyle(color: muted, fontSize: wide ? 11 : 10),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
    ),
  );

  Widget loading() => Center(
    child: error == null
        ? const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: green),
              SizedBox(height: 24),
              Text('会場とだしゅまるを準備しています', style: TextStyle(fontSize: 14)),
              SizedBox(height: 8),
              Text('はじめての読み込みには少し時間がかかります', style: TextStyle(color: muted, fontSize: 11)),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.view_in_ar_outlined, size: 40),
              const SizedBox(height: 16),
              const Text('会場さんぽを読み込めませんでした'),
              const SizedBox(height: 8),
              const Text('画面を再読み込みして、もう一度お試しください。', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  game?.dispose();
                  setState(() => error = null);
                  unawaited(load());
                },
                child: const Text('再試行'),
              ),
            ],
          ),
  );

  Widget sidebar() => ValueListenableBuilder<WalkStatus>(
    valueListenable: game!.status,
    builder: (context, state, _) {
      final g = game!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'だしゅまると歩いてみよう',
            style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text('会場をぐるっと、ひと足先に。\n気になるホールまで歩いてみましょう。', style: TextStyle(color: muted, fontSize: 12, height: 1.9)),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('ホールへ歩く', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const Spacer(),
              Text('${state.visited} / 4', style: const TextStyle(color: green, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                for (final (index, place) in g.navigation.places.where((p) => p.type == 'hall').indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Material(
                      color: state.destination == place.name ? const Color(0xffe0eee5) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xffe2e9e3)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => action(() => g.goTo(place.anchor, name: place.name)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 18),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: [
                                    const Color(0xff8061bd),
                                    const Color(0xff408fc3),
                                    const Color(0xff945838),
                                    const Color(0xff326e58),
                                  ][index],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  place.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Icon(
                                g.visited.contains(place.id) ? Icons.check_circle_outline : Icons.arrow_forward,
                                size: 18,
                                color: green,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xffe9eee7), borderRadius: BorderRadius.circular(16)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('自由に歩く', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                SizedBox(height: 12),
                _KeyHint('W A S D / ↑ ↓ ← →', '移動'),
                SizedBox(height: 9),
                _KeyHint('Shift', '走る'),
                SizedBox(height: 9),
                _KeyHint('Esc', '止まる'),
                SizedBox(height: 14),
                Text('画面のスティックでも操作できます。', style: TextStyle(color: muted, fontSize: 10)),
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget viewport({required bool wide, required bool compact, required bool landscape}) {
    final g = game!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(wide ? 24 : 20),
      child: ColoredBox(
        color: const Color(0xffe8f0e9),
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
                      child: fs.SceneView(
                        g.scene,
                        cameraBuilder: (_) => g.camera,
                        onTick: g.tick,
                        autoTick: !g.paused,
                        pixelRatio: math.min(MediaQuery.devicePixelRatioOf(context), 1.5),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: HallLabels(
                      g,
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
                          color: Colors.white.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xffdee7df)),
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
                                    decoration: const BoxDecoration(color: green, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('ただいま', style: TextStyle(fontSize: 10, color: muted)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(s.location!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                            if (s.destination != null)
                              Text('${s.destination}へ移動中', style: const TextStyle(fontSize: 10, color: green)),
                            if (s.notice != null)
                              Text(
                                s.notice!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: s.motion == 'そこへは移動できません' ? const Color(0xffa45138) : green,
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
                        color: Colors.white.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffdee7df)),
                      ),
                      child: CustomPaint(painter: MiniMap(g)),
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
                            tooltip: '行き先を選ぶ',
                            icon: Icons.signpost_outlined,
                            onPressed: () => chooseDestination(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (compact && !landscape)
                  Positioned(
                    right: 16,
                    top: 68,
                    child: _SurfaceButton(
                      tooltip: '行き先を選ぶ',
                      icon: Icons.signpost_outlined,
                      onPressed: () => chooseDestination(context),
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
                          const Text('スティックで歩く', style: TextStyle(color: muted, fontSize: 10)),
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

  void showAbout(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('会場さんぽの遊び方'),
      scrollable: true,
      content: Text(
        '左下のスティックで歩きます。右下の走るアイコンを押している間は走り、離すと歩く速さに戻ります。\n\n'
        '背景をドラッグして見回し、ピンチで近づいたり離れたりできます。床をタップすると、その場所まで自動で歩きます。\n\n'
        '道しるべから行き先を選んで、4つのホールを巡ってみましょう。地図アイコンで会場全体を見渡せます。\n\n'
        '${widget.showcase ? 'カメラで記念撮影。隣の写真アイコンを押すと、クリエイティブボードの前まで歩きます。ポーズやフレームを選んで撮影できます。\n\n' : ''}'
        'パソコンでは W A S D または矢印キーで移動、Shiftを押している間は走り、Escで止まります。\n\n'
        'このデモは5階の会場を散歩するサンプルです。実際の現在地や設営を示すものではなく、エスカレーターでの階移動はできません。\n\n'
        '3Dモデル: yakitama5 / flutter_deck_slides\nだしゅまる: FlutterKaigi',
        style: const TextStyle(fontSize: 13, height: 1.8),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
    ),
  );
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

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xffb7c9bc)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(color: green, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w600),
    ),
  );
}

class _KeyHint extends StatelessWidget {
  const _KeyHint(this.keys, this.label);
  final String keys;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(keys, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      ),
      Text(label, style: const TextStyle(color: muted, fontSize: 10)),
    ],
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
      color: Colors.white.withValues(alpha: .95),
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
                Icon(icon, size: 20, color: ink),
                if (label != null) ...[
                  const SizedBox(width: 7),
                  Text(
                    label!,
                    style: const TextStyle(fontSize: 11, color: ink, fontWeight: FontWeight.w600),
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
          color: Colors.white.withValues(alpha: .78),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xffbacfc0)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(top: 5, child: Icon(Icons.keyboard_arrow_up, size: 19, color: muted)),
            const Positioned(bottom: 5, child: Icon(Icons.keyboard_arrow_down, size: 19, color: muted)),
            const Positioned(left: 5, child: Icon(Icons.keyboard_arrow_left, size: 19, color: muted)),
            const Positioned(right: 5, child: Icon(Icons.keyboard_arrow_right, size: 19, color: muted)),
            Transform.translate(
              offset: widget.value * 34,
              child: Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: green.withValues(alpha: .18), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.pets_outlined, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class HallLabels extends CustomPainter {
  HallLabels(this.game, {required this.overviewTopInset}) : super(repaint: game);
  final VenueWalkScene game;
  final double overviewTopInset;
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
            color: ink,
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
            ..color = green.withValues(alpha: .5)
            ..strokeWidth = 1,
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        Paint()..color = Colors.white.withValues(alpha: .93),
      );
      tp.paint(canvas, Offset(r.left + 9, r.top + 6));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(HallLabels oldDelegate) =>
      oldDelegate.game != game || oldDelegate.overviewTopInset != overviewTopInset;
}

class MiniMap extends CustomPainter {
  MiniMap(this.game) : super(repaint: game);
  final VenueWalkScene game;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 1774, size.height / 810);
    final origin = Offset((size.width - 1774 * scale) / 2, (size.height - 810 * scale) / 2);
    Offset project(MapPoint p) => origin + Offset(p.x * scale, p.y * scale);
    for (final hall in game.navigation.places.where((p) => p.type == 'hall')) {
      canvas.drawPath(
        Path()..addPolygon(hall.polygon.map(project).toList(), true),
        Paint()..color = const Color(0xffe1e9df),
      );
    }
    for (final (a, b) in game.navigation.walls) {
      canvas.drawLine(
        project(a),
        project(b),
        Paint()
          ..color = const Color(0xff9cb1a2)
          ..strokeWidth = .7,
      );
    }
    if (game.path.isNotEmpty) {
      final path = Path()..addPolygon([project(game.position), ...game.path.map(project)], false);
      canvas.drawPath(
        path,
        Paint()
          ..color = green.withValues(alpha: .5)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
    }
    final at = project(game.position);
    canvas.drawCircle(at, 6, Paint()..color = green.withValues(alpha: .15));
    canvas.drawCircle(at, 3, Paint()..color = green);
    canvas.drawCircle(at, 1.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(MiniMap oldDelegate) => oldDelegate.game != game;
}
