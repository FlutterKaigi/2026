import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/feature/venue_map/data/venue_walk_photo_save.dart';
import 'package:app/feature/venue_map/data/venue_walk_scene.dart';
import 'package:app/feature/venue_map/ui/widget/venue_scene_viewport.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class VenueWalkPhotoStudio extends StatefulWidget {
  const VenueWalkPhotoStudio({required this.game, required this.onClose, super.key});

  final VenueWalkScene game;
  final VoidCallback onClose;

  @override
  State<VenueWalkPhotoStudio> createState() => _VenueWalkPhotoStudioState();
}

class _VenueWalkPhotoStudioState extends State<VenueWalkPhotoStudio> {
  final _pictureKey = GlobalKey();
  bool _clean = false;
  bool _frame = true;
  bool _capturing = false;
  double _lastScale = 1;

  Future<void> _capture() async {
    setState(() => _capturing = true);
    ui.Image? image;
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      final boundary = _pictureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('The photo could not be encoded.');
      }
      final bytes = data.buffer.asUint8List();
      final filename = 'flutterkaigi-2026-${DateTime.now().millisecondsSinceEpoch}.png';
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('記念写真'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 700,
              maxHeight: math.max(
                80,
                math.min(MediaQuery.sizeOf(context).height * .60, MediaQuery.sizeOf(context).height - 220),
              ),
            ),
            child: Image.memory(bytes, fit: BoxFit.contain, semanticLabel: '撮影しただしゅまるの記念写真'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
            if (supportsVenuePhotoDownload)
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await saveVenuePhoto(bytes, filename);
                    if (mounted) {
                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(const SnackBar(content: Text('写真のダウンロードを開始しました')));
                    }
                  } on Object catch (error) {
                    debugPrint('Venue photo download failed: $error');
                    if (mounted) {
                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(const SnackBar(content: Text('写真を保存できませんでした。もう一度お試しください。')));
                    }
                  }
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('PNGを保存'),
              ),
          ],
        ),
      );
    } on Object catch (error, stack) {
      debugPrint('Venue photo failed: $error\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('撮影できませんでした。もう一度お試しください。')));
      }
    } finally {
      image?.dispose();
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  Widget _scene() {
    final game = widget.game;
    return RepaintBoundary(
      key: _pictureKey,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: LayoutBuilder(
          builder: (context, constraints) {
            game.viewAspect = constraints.maxWidth / constraints.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: [
                Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      GestureBinding.instance.pointerSignalResolver.register(
                        event,
                        (_) => game.zoom(math.exp(event.scrollDelta.dy * .0015)),
                      );
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _clean ? () => setState(() => _clean = false) : null,
                    onScaleStart: (_) => _lastScale = 1,
                    onScaleUpdate: (details) {
                      if (details.pointerCount > 1) {
                        game.zoom(_lastScale / details.scale);
                        _lastScale = details.scale;
                      } else {
                        game.orbit(details.focalPointDelta);
                      }
                    },
                    child: VenueSceneViewport(
                      game: game,
                      pixelRatio: math.min(MediaQuery.devicePixelRatioOf(context), 2),
                    ),
                  ),
                ),
                if (_frame) ...[
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHigh, width: 10),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0),
                              Theme.of(context).colorScheme.surfaceContainerHigh,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FlutterKaigi 2026',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              game.status.value.location == null
                                  ? 'だしゅまると、会場さんぽ。'
                                  : 'だしゅまると、${game.status.value.location}で。',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _poses({bool vertical = false}) => ListView(
    shrinkWrap: true,
    scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
    children: [
      for (final pose in VenuePhotoPose.values)
        Padding(
          padding: EdgeInsets.only(right: vertical ? 0 : 7, bottom: vertical ? 4 : 0),
          child: ChoiceChip(
            label: Text(pose.label, style: const TextStyle(fontSize: 12)),
            selected: widget.game.photoPose == pose,
            onSelected: (_) => setState(() => widget.game.selectPhotoPose(pose)),
          ),
        ),
    ],
  );

  Widget _shutter() => Tooltip(
    message: '写真を撮る',
    excludeFromSemantics: true,
    child: FilledButton(
      onPressed: _capturing ? null : () => unawaited(_capture()),
      style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(19)),
      child: _capturing
          ? const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: '撮影中'),
            )
          : const Icon(Icons.camera_alt_rounded, size: 28, semanticLabel: '写真を撮る'),
    ),
  );

  Widget _hideUi() => IconButton(
    tooltip: 'UIを隠す。画面をタップすると戻ります',
    onPressed: () => setState(() => _clean = true),
    icon: const Icon(Icons.visibility_off_outlined),
  );

  Widget _faceCamera() => IconButton(
    tooltip: 'こちらを向く',
    onPressed: () => setState(() => widget.game.selectPhotoPose(widget.game.photoPose)),
    icon: const Icon(Icons.face_retouching_natural),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_clean) {
            return _scene();
          }
          final landscape = constraints.maxHeight < 500 && constraints.maxWidth > constraints.maxHeight;
          final scene = ClipRRect(borderRadius: BorderRadius.circular(16), child: _scene());
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Row(
                  children: [
                    IconButton(tooltip: 'さんぽに戻る', onPressed: widget.onClose, icon: const Icon(Icons.close_rounded)),
                    const Expanded(
                      child: Text('だしゅまると記念撮影', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    IconButton(
                      tooltip: _frame ? 'フレームを外す' : 'フレームを付ける',
                      isSelected: _frame,
                      onPressed: () => setState(() => _frame = !_frame),
                      icon: const Icon(Icons.crop_free_rounded),
                      selectedIcon: const Icon(Icons.crop_square_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, landscape ? 12 : 0),
                  child: landscape
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: scene),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 128,
                              child: Column(
                                children: [
                                  Expanded(child: _poses(vertical: true)),
                                  const SizedBox(height: 6),
                                  _shutter(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [_hideUi(), _faceCamera()],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : scene,
                ),
              ),
              if (!landscape) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: SizedBox(height: 40, child: _poses()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_hideUi(), _shutter(), _faceCamera()],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}
