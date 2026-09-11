import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/widget/settings_icon_button.dart';
import 'package:app/feature/venue_map/data/venue_floor_plan.dart';
import 'package:app/feature/venue_map/provider/venue_map_view_mode.dart';
import 'package:app/feature/venue_map/ui/widget/venue_map_2d_controller.dart';
import 'package:app/feature/venue_map/ui/widget/venue_map_2d_view.dart';
import 'package:app/feature/venue_map/ui/widget/venue_map_3d_view.dart';
import 'package:app/feature/venue_map/ui/widget/venue_place_search.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class VenueMapPage extends ConsumerStatefulWidget {
  const VenueMapPage({super.key});
  @override
  ConsumerState<VenueMapPage> createState() => _VenueMapPageState();
}

class _VenueMapPageState extends ConsumerState<VenueMapPage> {
  final _mapKey = GlobalKey();
  final _twoD = VenueMap2DController();
  final _threeD = VenueMap3DController();
  VenuePlace? _selected;
  bool _hasOpenedThreeD = false;
  bool _searchOpen = false;
  bool _savingMode = false;

  @override
  void dispose() {
    _twoD.dispose();
    _threeD.disconnect();
    super.dispose();
  }

  Future<void> _setMode(VenueMapViewMode mode) async {
    if (_savingMode) {
      return;
    }
    setState(() => _savingMode = true);
    try {
      await ref.read(venueMapViewModeProvider.notifier).set(mode);
      if (_selected case final selected? when mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          if (mode == VenueMapViewMode.twoD) {
            _twoD.focus(selected);
          } else {
            _threeD.focus(selected.id);
          }
        });
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t.venueMap.saveFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _savingMode = false);
      }
    }
  }

  void _select(VenuePlace place) {
    setState(() => _selected = place);
    // Let the summary take its space, then move the active camera once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selected != place) {
        return;
      }
      switch (ref.read(venueMapViewModeProvider)) {
        case VenueMapViewMode.twoD:
          _twoD.focus(place);
        case VenueMapViewMode.threeD:
          _threeD.focus(place.id);
      }
    });
  }

  Future<void> _search(VenueFloorPlan plan) async {
    setState(() => _searchOpen = true);
    final place = await showModalBottomSheet<VenuePlace>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(context.t.venueMap.search, style: Theme.of(context).textTheme.titleLarge)),
                    CloseButton(onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              Expanded(
                child: VenuePlaceSearch(
                  plan: plan,
                  selected: _selected,
                  onSelected: (place) => Navigator.of(context).pop(place),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => _searchOpen = false);
    if (place != null) {
      _select(place);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.venueMap;
    final theme = Theme.of(context);
    final mode = ref.watch(venueMapViewModeProvider);
    final plan = ref.watch(venueFloorPlanProvider);
    _hasOpenedThreeD = _hasOpenedThreeD || mode == VenueMapViewMode.threeD;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(t.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        actions: const [SettingsIconButton()],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _ViewModeHeader(
              mode: mode,
              onChanged: _savingMode ? null : (value) => unawaited(_setMode(value)),
            ),
            Expanded(
              child: plan.when(
                loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.loadError),
                      TextButton(
                        onPressed: () => ref.invalidate(venueFloorPlanProvider),
                        child: Text(context.t.error.retry),
                      ),
                    ],
                  ),
                ),
                data: (plan) => LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 840;
                    final map = KeyedSubtree(
                      key: _mapKey,
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Offstage(
                                  offstage: mode != VenueMapViewMode.twoD,
                                  child: VenueMap2DView(
                                    plan: plan,
                                    controller: _twoD,
                                    selected: _selected,
                                    onSelected: _select,
                                  ),
                                ),
                                if (_hasOpenedThreeD)
                                  Offstage(
                                    offstage: mode != VenueMapViewMode.threeD,
                                    child: VenueMap3DView(
                                      controller: _threeD,
                                      active:
                                          mode == VenueMapViewMode.threeD &&
                                          !_searchOpen &&
                                          TickerMode.valuesOf(context).enabled,
                                      selected: _selected,
                                      onSelected: (id) {
                                        final place = plan.find(id);
                                        if (place != null) {
                                          _select(place);
                                        }
                                      },
                                      onUseTwoD: () => unawaited(_setMode(VenueMapViewMode.twoD)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Material(
                            color: theme.colorScheme.surfaceContainerLow,
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Text('5F', style: theme.textTheme.titleMedium),
                                const Spacer(),
                                IconButton(
                                  tooltip: t.rotate,
                                  onPressed: mode == VenueMapViewMode.twoD ? _twoD.rotate : _threeD.rotate,
                                  icon: const Icon(Icons.screen_rotation_alt),
                                ),
                                IconButton(
                                  tooltip: t.zoomOut,
                                  onPressed: () =>
                                      mode == VenueMapViewMode.twoD ? _twoD.zoom(1 / 1.25) : _threeD.zoom(1 / 1.25),
                                  icon: const Icon(Icons.remove),
                                ),
                                IconButton(
                                  tooltip: t.zoomIn,
                                  onPressed: () =>
                                      mode == VenueMapViewMode.twoD ? _twoD.zoom(1.25) : _threeD.zoom(1.25),
                                  icon: const Icon(Icons.add),
                                ),
                                IconButton(
                                  tooltip: t.fit,
                                  onPressed: mode == VenueMapViewMode.twoD ? _twoD.fit : _threeD.fit,
                                  icon: const Icon(Icons.fit_screen),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                    VenuePlace? related;
                    if (_selected?.relatedHallId case final id?) {
                      related = plan.find(id);
                    } else if (_selected?.type == VenuePlaceType.hall) {
                      for (final p in plan.places) {
                        if (p.relatedHallId == _selected!.id) {
                          related = p;
                        }
                      }
                    }
                    final summary = _selected == null
                        ? const SizedBox.shrink()
                        : VenuePlaceSummary(
                            place: _selected!,
                            onClear: () => setState(() => _selected = null),
                            onFocus: () => _select(_selected!),
                            related: related,
                            onRelated: _select,
                          );
                    if (wide) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 320,
                            child: Column(
                              children: [
                                Expanded(
                                  child: VenuePlaceSearch(plan: plan, selected: _selected, onSelected: _select),
                                ),
                                summary,
                              ],
                            ),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(child: map),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Expanded(child: map),
                        const Divider(height: 1),
                        summary,
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.tonalIcon(
                              onPressed: () => unawaited(_search(plan)),
                              icon: const Icon(Icons.search),
                              label: Text(t.search),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewModeHeader extends StatelessWidget {
  const _ViewModeHeader({required this.mode, required this.onChanged});
  final VenueMapViewMode mode;
  final ValueChanged<VenueMapViewMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t.venueMap;
    final floor = Text(t.floor, style: Theme.of(context).textTheme.bodySmall);
    final toggle = Semantics(
      label: t.viewMode,
      child: SegmentedButton<VenueMapViewMode>(
        showSelectedIcon: false,
        style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 48))),
        segments: [
          ButtonSegment(value: VenueMapViewMode.twoD, label: Text(t.twoD), icon: const Icon(Icons.map_outlined)),
          ButtonSegment(value: VenueMapViewMode.threeD, label: Text(t.threeD), icon: const Icon(Icons.view_in_ar)),
        ],
        selected: {mode},
        onSelectionChanged: onChanged == null ? null : (values) => onChanged!(values.single),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600 && MediaQuery.textScalerOf(context).scale(12) > 16) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                floor,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: toggle),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: floor),
              const SizedBox(width: 12),
              toggle,
            ],
          );
        },
      ),
    );
  }
}
