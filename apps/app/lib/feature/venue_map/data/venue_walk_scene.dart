import 'dart:convert';
import 'dart:math' as math;

import 'package:app/feature/venue_map/data/venue_escalator_layout.dart';
import 'package:app/feature/venue_map/data/venue_localized_signs.dart';
import 'package:app/feature/venue_map/data/venue_walk_architecture.dart';
import 'package:app/feature/venue_map/data/venue_walk_decorations.dart';
import 'package:app/feature/venue_map/data/venue_walk_navigation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart' as fs;
import 'package:vector_math/vector_math.dart' as vm;

typedef WalkStatus = ({
  String? location,
  String? destination,
  WalkNotice? notice,
  String? arrivedAt,
  int visited,
  bool running,
  bool overview,
});

enum WalkNotice { unreachable, arrived }

enum VenuePhotoPose {
  standing('Idle'),
  wave('Wave'),
  sitting('Sit', holdAt: 3.2, focusHeight: .58, turn: .22),
  jumping('Jump', holdAt: 1.15, focusHeight: 1.02);

  const VenuePhotoPose(this.clip, {this.holdAt, this.focusHeight = .8, this.turn = 0});
  final String clip;
  final double? holdAt;
  final double focusHeight;
  final double turn;
}

/// Owns the retained scene graph and simulation; the page owns input and layout.
class VenueWalkScene extends ChangeNotifier {
  VenueWalkScene({this.showcase = false});

  final bool showcase;
  late final scene = fs.Scene();
  final _resources = fs.ResourceGroup();
  final _localizedSigns = VenueLocalizedSigns('ja');
  String _languageCode = 'ja';
  late final VenueNavigation navigation;
  final camera = fs.PerspectiveCamera(position: vm.Vector3(0, 12, -16), target: vm.Vector3.zero());
  final status = ValueNotifier<WalkStatus>((
    location: null,
    destination: null,
    notice: null,
    arrivedAt: null,
    visited: 0,
    running: false,
    overview: false,
  ));
  final keys = <LogicalKeyboardKey>{};
  final visited = <String>{};
  final _clips = <String, fs.AnimationClip>{};
  final _actor = fs.Node(name: 'Dashumaru movement');
  final _routeRoot = fs.Node(name: 'Walking route');
  late fs.Node _target;
  late fs.Node _footRing;
  late fs.Node _faceNormal;
  late fs.Node _faceSmile;
  final _photoShadow = fs.Node(name: 'Photo ground contact')..visible = false;
  VenueWalkArchitecture? architecture;
  VenueWalkDecorations? decorations;
  bool photoMode = false;
  VenuePhotoPose photoPose = VenuePhotoPose.standing;
  ({double yaw, double elevation, double distance, double heading, bool overview})? _beforePhoto;
  MapPoint position = VenueNavigation.spawn;
  List<MapPoint> path = [];
  final stickInput = ValueNotifier<Offset>(Offset.zero);
  Offset get stick => stickInput.value;
  set stick(Offset value) => stickInput.value = value;
  double yaw = 0;
  double elevation = .67;
  double distance = 14;
  double _overviewZoom = 1;
  double viewAspect = 1.6;
  bool compactView = false;
  double _heading = 0;
  double _waveTime = 0;
  double _statusTime = 0;
  String? _destination;
  WalkNotice? _notice;
  String? _arrivedAt;
  double _noticeTime = 0;
  bool _sprintHeld = false;
  bool overview = false;
  bool paused = false;
  bool _disposed = false;
  bool _dark = false;
  void Function()? _applyAppearance;
  final _surfaceColors = <(fs.PhysicallyBasedMaterial, int, int)>[];
  static const unit = .04;
  static const _compactElevationOffset = .43;

  double get _cameraYaw => yaw + (overview && viewAspect < .85 ? math.pi / 2 : 0);

  bool get _sprinting =>
      _sprintHeld || keys.contains(LogicalKeyboardKey.shiftLeft) || keys.contains(LogicalKeyboardKey.shiftRight);

  vm.Vector3 world(MapPoint p, [double height = 0]) => vm.Vector3((p.x - 885) * unit, height, (420 - p.y) * unit);
  MapPoint map(vm.Vector3 p) => MapPoint(p.x / unit + 885, 420 - p.z / unit);

  Future<void> load() async {
    await fs.Scene.initializeStaticResources();
    if (_disposed) {
      return;
    }
    final data = jsonDecode(await rootBundle.loadString('assets/venue_map/floor_plan.json')) as Map<String, Object?>;
    if (_disposed) {
      return;
    }
    navigation = VenueNavigation(data);
    final escalators = (data['escalators']! as List)
        .cast<Map<String, Object?>>()
        .map(VenueEscalatorLayout.new)
        .toList();
    final model = await _resources.track(
      fs.loadScene('assets/models/dashmaru.glb'),
      release: () => fs.releaseScene('assets/models/dashmaru.glb'),
    );
    if (_disposed) {
      return;
    }
    final texture = await _resources.track(
      fs.loadTexture('assets/venue_map/floor_map_base.png'),
      release: () => fs.releaseTexture('assets/venue_map/floor_map_base.png'),
    );
    final darkTexture = await _resources.track(
      fs.loadTexture('assets/venue_map/floor_map_base_dark.png'),
      release: () => fs.releaseTexture('assets/venue_map/floor_map_base_dark.png'),
    );
    if (_disposed) {
      return;
    }
    scene.environmentIntensity = .85;
    scene.directionalLight = fs.DirectionalLight(
      direction: vm.Vector3(-.4, -1, .3),
      intensity: 1.6,
      castsShadow: true,
      shadowCascadeCount: 1,
      shadowMaxDistance: 95,
      shadowSoftness: .10,
    );
    scene.antiAliasingMode = fs.AntiAliasingMode.fxaa;
    final floorMaterial = fs.UnlitMaterial(colorTexture: texture)
      ..baseColorTextureTransform = fs.TextureTransform(offset: vm.Vector2(0, 1), scale: vm.Vector2(1, -1));
    final cleanFloor = _unlit(0xfcfdfe);
    _applyAppearance = () {
      floorMaterial.baseColorTexture = _dark ? darkTexture : texture;
      cleanFloor.baseColorFactor = _color(_dark ? 0x18232e : 0xfcfdfe);
      for (final (material, light, dark) in _surfaceColors) {
        material.baseColorFactor = _color(_dark ? dark : light);
      }
    };
    final openings = showcase ? escalators.map((layout) => layout.floorOpening).whereType<Rect>().toList() : <Rect>[];
    final artwork = showcase ? escalators.map((layout) => layout.floorArtworkBounds).toList() : <Rect>[];
    _addFloor(
      venueFloorPatches(const Rect.fromLTWH(0, 0, 1774, 810), [...openings, ...artwork]),
      floorMaterial,
    );
    if (artwork.isNotEmpty) {
      // Replace the flat escalator artwork with clean floor. Descending shafts
      // remain open, and the shared 2D map texture stays intact for map views.
      _addFloor(
        artwork.expand((bounds) => venueFloorPatches(bounds, openings)),
        cleanFloor,
      );
    }
    for (final patch in venueFloorPatches(const Rect.fromLTWH(26, 77, 1718, 686), openings)) {
      _box(
        MapPoint(patch.center.dx, patch.center.dy),
        patch.width * unit,
        .32,
        patch.height * unit,
        0xdce7e5,
        darkColor: 0x17232c,
        height: -.17,
      );
    }
    for (final (a, b) in navigation.walls) {
      final dx = (b.x - a.x) * unit;
      final dz = (a.y - b.y) * unit;
      final node = _box(
        MapPoint((a.x + b.x) / 2, (a.y + b.y) / 2),
        math.sqrt(dx * dx + dz * dz),
        .85,
        .10,
        0xd6e3df,
        darkColor: 0x536574,
        height: .44,
      );
      node.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), -math.atan2(dz, dx));
    }
    for (final booth in (data['booths']! as List).cast<Map<String, Object?>>()) {
      final r = (booth['rect']! as List).cast<num>();
      _box(
        MapPoint(r[0] + r[2] / 2, r[1] + r[3] / 2),
        r[2] * unit,
        .52,
        r[3] * unit,
        0x54788a,
        darkColor: 0x3b5968,
        height: .28,
      );
    }
    if (showcase) {
      architecture = VenueWalkArchitecture(
        navigation: navigation,
        world: world,
        escalators: escalators,
        localizedSigns: _localizedSigns,
      );
      await architecture!.build();
      if (_disposed) {
        return;
      }
      scene.add(architecture!.root);
      decorations = VenueWalkDecorations(navigation: navigation, world: world, localizedSigns: _localizedSigns);
      await decorations!.build();
      if (_disposed) {
        return;
      }
      scene.add(decorations!.root);
    }
    // Use a parent for translation so authored bone animation never overrides it.
    model.scale = vm.Vector3.all(.52);
    _faceNormal = model.getChildByName('FaceNormal')!;
    _faceSmile = model.getChildByName('FaceSmile')!
      ..scale = vm.Vector3.all(1)
      ..visible = false;
    _bindPhotoRotations(model);
    _actor.add(model);
    _actor.position = world(position, .025);
    scene.add(_actor);
    for (final name in ['Idle', 'Walk', 'Run', 'Wave', 'Sit', 'Jump']) {
      final animation = model.findAnimationByName(name);
      if (animation == null) {
        throw StateError('Required model animation is missing: $name');
      }
      _clips[name] = model.createAnimationClip(animation)
        ..loop = ['Idle', 'Walk', 'Run'].contains(name)
        ..playing = true
        ..weight = name == 'Idle' ? 1 : 0;
    }
    _footRing = fs.Node(mesh: fs.Mesh(fs.RingGeometry(innerRadius: .54, outerRadius: .60), _unlit(0x1f937d)));
    _actor.add(_footRing..position = vm.Vector3(0, .014, 0));
    for (var i = 0; i < 12; i++) {
      _photoShadow.add(
        fs.Node(
          mesh: fs.Mesh(
            fs.DiscGeometry(radius: .52 - i * .026, segments: 48),
            fs.UnlitMaterial()
              ..alphaMode = fs.AlphaMode.blend
              ..baseColorFactor = vm.Vector4(0, 0, 0, .035),
          ),
        )..position = vm.Vector3(0, .012 + i * .0003, 0),
      );
    }
    _actor.add(_photoShadow);
    _target = fs.Node(mesh: fs.Mesh(fs.RingGeometry(innerRadius: .24, outerRadius: .34), _unlit(0x1f937d)))
      ..visible = false;
    scene.add(_routeRoot);
    scene.add(_target);
    _updateCamera(1, snap: true);
    _applyAppearance!();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_languageCode == languageCode || _disposed) {
      return;
    }
    _languageCode = languageCode;
    await _localizedSigns.setLanguage(languageCode);
  }

  void setDarkMode({required bool dark}) {
    _dark = dark;
    _applyAppearance?.call();
  }

  void _bindPhotoRotations(fs.Node model) {
    final rotations = {
      VenuePhotoPose.sitting: {
        'Head': vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), -.16) * vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), .10),
      },
      VenuePhotoPose.jumping: {
        'LeftWing': vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), -2.15),
        'RightWing': vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), 2.15),
        'LeftWingBend': vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), .25),
        'RightWingBend': vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), -.25),
        'LeftWingTip': vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), .10),
        'RightWingTip': vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), -.10),
      },
    };
    for (final pose in rotations.entries) {
      for (final bone in pose.value.entries) {
        model.getChildByName(bone.key)!.addComponent(_PhotoRotation(this, pose.key, bone.value));
      }
    }
  }

  void _addFloor(Iterable<Rect> patches, fs.Material material) {
    final floor = fs.GeometryBuilder(deduplicate: false)..normal(vm.Vector3(0, 1, 0));
    for (final patch in patches) {
      final indices = <int>[];
      for (final p in [patch.topLeft, patch.topRight, patch.bottomRight, patch.bottomLeft]) {
        // Preserve the source UVs as the floor is split into separate patches.
        floor.texCoord(vm.Vector2(p.dx / 1774, 1 - p.dy / 810));
        indices.add(floor.addVertex(world(MapPoint(p.dx, p.dy), .015)));
      }
      floor
        ..addTriangle(indices[0], indices[1], indices[2])
        ..addTriangle(indices[0], indices[2], indices[3]);
    }
    scene.add(fs.Node(mesh: fs.Mesh(floor.build(retainCpuData: false), material)));
  }

  vm.Vector4 _color(int rgb) {
    double linear(int c) {
      final v = c / 255;
      return v <= .04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
    }

    return vm.Vector4(linear((rgb >> 16) & 255), linear((rgb >> 8) & 255), linear(rgb & 255), 1);
  }

  fs.UnlitMaterial _unlit(int color) => fs.UnlitMaterial()..baseColorFactor = _color(color);

  fs.Node _box(MapPoint p, double w, double h, double d, int color, {required double height, int? darkColor}) {
    final material = fs.PhysicallyBasedMaterial()
      ..baseColorFactor = _color(color)
      ..roughnessFactor = .86;
    if (darkColor != null) {
      _surfaceColors.add((material, color, darkColor));
    }
    final node = fs.Node(
      mesh: fs.Mesh(
        fs.CuboidGeometry(vm.Vector3(w, h, d)),
        material,
      ),
    )..position = world(p, height);
    scene.add(node);
    return node;
  }

  void _clearPath() {
    path = [];
    _destination = null;
    _routeRoot.children.toList().forEach(_routeRoot.remove);
    _target.visible = false;
  }

  void releaseInput() {
    keys.clear();
    stick = Offset.zero;
    _sprintHeld = false;
    _publish();
  }

  void stop() {
    releaseInput();
    _waveTime = 0;
    _notice = null;
    _clearPath();
    _publish();
  }

  void reset() {
    stop();
    position = VenueNavigation.spawn;
    _heading = 0;
    overview = false;
    yaw = 0;
    elevation = .67;
    distance = 14;
    _overviewZoom = 1;
    _actor.position = world(position, .025);
    _actor.rotation = vm.Quaternion.identity();
    _notice = null;
    _updateCamera(1, snap: true);
    _publish();
    notifyListeners();
  }

  void setSprintHeld({required bool pressed}) {
    _sprintHeld = pressed;
    _publish();
  }

  void toggleOverview() {
    stop();
    overview = !overview;
    _publish();
  }

  void orbit(Offset delta) {
    yaw -= delta.dx * .006;
    final offset = compactView && !photoMode ? _compactElevationOffset : 0.0;
    final minimum = photoMode
        ? .08
        : compactView
        ? .18
        : .30;
    final visibleElevation = (elevation - offset).clamp(minimum, 1.35);
    elevation = (visibleElevation + delta.dy * .005).clamp(minimum, 1.35) + offset;
  }

  void zoom(double factor) {
    if (overview) {
      _overviewZoom = (_overviewZoom * factor).clamp(.45, 2);
    } else {
      distance = (distance * factor).clamp(photoMode ? 4 : 9, photoMode ? 16 : 40);
    }
  }

  void wave() {
    stop();
    _waveTime = 3.2;
    _clips['Wave']!.replay();
    // Turn toward the viewer before waving.
    _heading = cameraFacingHeading;
  }

  double get cameraFacingHeading {
    final toCamera = camera.position - world(position);
    return math.atan2(-toCamera.x, -toCamera.z);
  }

  void enterPhotoMode() {
    if (photoMode) {
      return;
    }
    stop();
    _beforePhoto = (yaw: yaw, elevation: elevation, distance: distance, heading: _heading, overview: overview);
    yaw = cameraFacingHeading;
    overview = false;
    elevation = .24;
    distance = 5;
    photoMode = true;
    _footRing.visible = false;
    _photoShadow.visible = true;
    _updateCamera(1, snap: true);
    selectPhotoPose(VenuePhotoPose.wave);
  }

  void selectPhotoPose(VenuePhotoPose pose) {
    photoPose = pose;
    _heading = cameraFacingHeading + pose.turn;
    final smiling = pose != VenuePhotoPose.standing;
    _faceNormal.visible = !smiling;
    _faceSmile.visible = smiling;
    final shadowScale = pose == VenuePhotoPose.jumping ? .75 : 1.0;
    _photoShadow.scale = vm.Vector3(shadowScale, 1, shadowScale * .72);
    final clip = _clips[pose.clip]!;
    final time = pose.holdAt;
    if (time == null) {
      clip.loop = true;
      clip.replay();
    } else {
      clip.pause();
      clip.seek(time);
    }
    // A shutter press immediately after choosing a pose should capture that
    // pose, rather than a partial blend from the previous selection.
    for (final entry in _clips.entries) {
      entry.value.weight = entry.key == pose.clip ? 1 : 0;
    }
  }

  void exitPhotoMode() {
    final previous = _beforePhoto;
    if (previous == null) {
      return;
    }
    stop();
    photoMode = false;
    _footRing.visible = true;
    _photoShadow.visible = false;
    _faceNormal.visible = true;
    _faceSmile.visible = false;
    _clips['Wave']!.loop = false;
    yaw = previous.yaw;
    elevation = previous.elevation;
    distance = previous.distance;
    overview = previous.overview;
    _heading = previous.heading;
    _beforePhoto = null;
    _updateCamera(1, snap: true);
    _publish();
  }

  void goToPlace(String id) {
    for (final place in navigation.places) {
      if (place.id == id) {
        final target = navigation.approach(position, place);
        goTo(target ?? place.anchor, placeId: place.id);
        return;
      }
    }
  }

  void goTo(MapPoint target, {String? placeId}) {
    _clearPath();
    keys.clear();
    stick = Offset.zero;
    _waveTime = 0;
    final route = navigation.route(position, target);
    if (route.isEmpty) {
      _notice = WalkNotice.unreachable;
      _noticeTime = 2.5;
      _publish();
      return;
    }
    overview = false;
    path = route;
    _destination = placeId ?? 'selected_point';
    _notice = null;
    var from = position;
    for (final to in route) {
      final count = (from.distanceTo(to) / 14).ceil();
      for (var i = 1; i <= count; i++) {
        final t = i / count;
        _routeRoot.add(
          fs.Node(mesh: fs.Mesh(fs.DiscGeometry(radius: .065, segments: 8), _unlit(0x339883)))
            ..position = world(MapPoint(from.x + (to.x - from.x) * t, from.y + (to.y - from.y) * t), .032),
        );
      }
      from = to;
    }
    _target
      ..visible = true
      ..position = world(target, .04);
    _publish();
  }

  void tapFloor(Offset local, Size size) {
    final ray = camera.screenPointToRay(local, size);
    if (ray.direction.y.abs() < .0001) {
      return;
    }
    final t = (.03 - ray.origin.y) / ray.direction.y;
    if (t <= 0) {
      return;
    }
    goTo(map(ray.origin + ray.direction * t));
  }

  /// Converts a screen-space stick direction to the floor plan's coordinates.
  MapPoint movementFor(Offset input) {
    // Use the camera that is actually rendered, including easing and resize.
    // The actor's facing direction never changes the meaning of the stick.
    final forward = (camera.target - camera.position)..y = 0;
    if (forward.length2 < .000001) {
      return const MapPoint(0, 0);
    }
    forward.normalize();
    final right = vm.Vector3(0, 1, 0).cross(forward);
    final movement = right * input.dx - forward * input.dy;
    return MapPoint(movement.x, -movement.z);
  }

  void tick(Duration elapsed, double delta) {
    if (paused || _disposed) {
      return;
    }
    // A resumed tab or slow frame cannot advance the character across the map.
    final dt = delta.clamp(0.0, .05);
    final fast = _sprinting;
    var x = stick.dx;
    var y = -stick.dy;
    if (keys.contains(LogicalKeyboardKey.keyW) || keys.contains(LogicalKeyboardKey.arrowUp)) {
      y += 1;
    }
    if (keys.contains(LogicalKeyboardKey.keyS) || keys.contains(LogicalKeyboardKey.arrowDown)) {
      y -= 1;
    }
    if (keys.contains(LogicalKeyboardKey.keyA) || keys.contains(LogicalKeyboardKey.arrowLeft)) {
      x -= 1;
    }
    if (keys.contains(LogicalKeyboardKey.keyD) || keys.contains(LogicalKeyboardKey.arrowRight)) {
      x += 1;
    }
    final before = position;
    final manual = math.sqrt(x * x + y * y);
    final speed = (fast ? 120.0 : 64.0) * dt;
    if (!photoMode && manual > .08) {
      if (path.isNotEmpty) {
        _clearPath();
      }
      _waveTime = 0;
      _notice = null;
      final norm = math.max(1, manual);
      x /= norm;
      y /= norm;
      // Match screen-space input after orbiting; map Y increases downwards.
      final direction = movementFor(Offset(x, -y));
      position = navigation.move(position, MapPoint(direction.x * speed, direction.y * speed));
    } else if (!photoMode && path.isNotEmpty) {
      var remaining = speed;
      while (path.isNotEmpty && remaining > 0) {
        final target = path.first;
        final length = position.distanceTo(target);
        if (length <= remaining) {
          position = target;
          path.removeAt(0);
          remaining -= length;
        } else {
          position = MapPoint(
            position.x + (target.x - position.x) * remaining / length,
            position.y + (target.y - position.y) * remaining / length,
          );
          remaining = 0;
        }
      }
      if (path.isEmpty) {
        _notice = WalkNotice.arrived;
        _arrivedAt = _destination;
        _noticeTime = 4;
        _clearPath();
      }
    }
    final moved = before.distanceTo(position) > .001;
    if (moved) {
      final heading = math.atan2(before.x - position.x, position.y - before.y);
      final difference = math.atan2(math.sin(heading - _heading), math.cos(heading - _heading));
      _heading += difference * math.min(1, dt * 15);
    }
    _actor.position = world(position, .025);
    _actor.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), _heading);
    _waveTime = math.max(0, _waveTime - dt);
    final animation = photoMode
        ? photoPose.clip
        : moved
        ? (fast ? 'Run' : 'Walk')
        : _waveTime > 0
        ? 'Wave'
        : 'Idle';
    for (final entry in _clips.entries) {
      entry.value.weight += ((entry.key == animation ? 1 : 0) - entry.value.weight) * math.min(1, dt * 12);
    }
    final hall = navigation.hallAt(position);
    if (hall != null) {
      visited.add(hall.id);
    }
    _noticeTime -= dt;
    if (_noticeTime <= 0) {
      _notice = null;
    }
    _updateCamera(dt);
    scene.update(dt);
    _statusTime += dt;
    if (_statusTime >= .12) {
      _statusTime = 0;
      _publish();
    }
    notifyListeners();
  }

  void _updateCamera(double dt, {bool snap = false}) {
    final cameraYaw = _cameraYaw;
    final closeFollow = compactView && !overview && !photoMode;
    final focus = overview
        ? vm.Vector3(0, 0, 0)
        : world(position, photoMode ? photoPose.focusHeight : (closeFollow ? 1.1 : .8));
    if (closeFollow) {
      // Leave room ahead of the character, without rotating with its heading.
      focus.add(vm.Vector3(math.sin(cameraYaw), 0, math.cos(cameraYaw)) * .8);
    }
    final floorWidth = 68.72 * math.cos(cameraYaw).abs() + 27.44 * math.sin(cameraYaw).abs();
    final floorDepth = 68.72 * math.sin(cameraYaw).abs() + 27.44 * math.cos(cameraYaw).abs();
    final d = overview
        ? (math.max(floorWidth / (.72 * viewAspect), floorDepth / .72) + 12) * _overviewZoom
        : distance * (closeFollow ? .5 : 1);
    final angle = overview
        ? 1.1
        : closeFollow
        ? (elevation - _compactElevationOffset).clamp(.18, 1.35)
        : elevation;
    final desired =
        focus +
        vm.Vector3(
          -math.sin(cameraYaw) * math.cos(angle) * d,
          math.sin(angle) * d,
          -math.cos(cameraYaw) * math.cos(angle) * d,
        );
    final factor = snap ? 1.0 : 1 - math.exp(-dt * 8);
    camera.position = camera.position + (desired - camera.position) * factor;
    camera.target = camera.target + (focus - camera.target) * factor;
    architecture?.updateView(camera, focus: focus, dt: dt, overview: overview, snap: snap);
  }

  void _publish() {
    final hall = navigation.hallAt(position);
    status.value = (
      location: hall?.id ?? (position.y > 587 ? 'entrance' : null),
      destination: _destination,
      notice: _notice,
      arrivedAt: _notice == WalkNotice.arrived ? _arrivedAt : null,
      visited: visited.length,
      running: _sprinting,
      overview: overview,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    keys.clear();
    stickInput.dispose();
    _resources.dispose();
    _localizedSigns.dispose();
    status.dispose();
    super.dispose();
  }
}

/// The root animation runs before child components. Adjust only photo bones
/// after that animation, retaining the authored legs and body motion.
class _PhotoRotation extends fs.Component {
  _PhotoRotation(this.game, this.pose, this.rotation);

  final VenueWalkScene game;
  final VenuePhotoPose pose;
  final vm.Quaternion rotation;

  @override
  void update(double deltaSeconds) {
    if (game.photoMode && game.photoPose == pose) {
      node.rotation = rotation;
    }
  }
}
