import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/venue_map/data/venue_floor_plan.dart';
import 'package:flutter/material.dart';

class VenuePlaceSearch extends StatefulWidget {
  const VenuePlaceSearch({required this.plan, required this.selected, required this.onSelected, super.key});
  final VenueFloorPlan plan;
  final VenuePlace? selected;
  final ValueChanged<VenuePlace> onSelected;
  @override
  State<VenuePlaceSearch> createState() => _VenuePlaceSearchState();
}

class _VenuePlaceSearchState extends State<VenuePlaceSearch> {
  final _controller = TextEditingController();
  String _query = '';
  VenuePlaceType? _type;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.venueMap;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final places = widget.plan.places
        .where(
          (p) =>
              (_type == null || p.type == _type || (_type == VenuePlaceType.hall && p.type == VenuePlaceType.foyer)) &&
              p.matches(_query),
        )
        .toList();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                labelText: t.search,
                hintText: t.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: t.clearSearch,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                for (final (type, label) in [
                  (null, t.all),
                  (VenuePlaceType.hall, t.halls),
                  (VenuePlaceType.sponsor, '${t.booths} 22'),
                  (VenuePlaceType.facility, t.facilities),
                ])
                  FilterChip(
                    label: Text(label),
                    selected: _type == type,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
          ),
        ),
        if (places.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('${places.length} ${t.placesCount}', style: theme.textTheme.labelMedium),
            ),
          ),
        if (places.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(t.noResults, style: theme.textTheme.bodyMedium)),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            sliver: SliverList.list(
              children: [
                for (final place in places)
                  ListTile(
                    leading: VenuePlaceBadge(place: place),
                    title: Semantics(
                      label: place.semanticsLabel(language),
                      child: ExcludeSemantics(child: Text(place.name(language))),
                    ),
                    subtitle: Text(place.subtitle(language)),
                    selected: place.id == widget.selected?.id,
                    selectedTileColor: theme.colorScheme.primaryContainer,
                    onTap: () => widget.onSelected(place),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class VenuePlaceSummary extends StatelessWidget {
  const VenuePlaceSummary({
    required this.place,
    required this.onClear,
    this.onFocus,
    this.related,
    this.onRelated,
    super.key,
  });
  final VenuePlace place;
  final VoidCallback onClear;
  final VoidCallback? onFocus;
  final VenuePlace? related;
  final ValueChanged<VenuePlace>? onRelated;
  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.only(left: 16, right: 8),
            leading: VenuePlaceBadge(place: place),
            title: Text(place.name(language), style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(place.subtitle(language)),
            trailing: IconButton(
              tooltip: context.t.venueMap.clearSelection,
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Wrap(
              spacing: 8,
              children: [
                if (onFocus != null)
                  TextButton.icon(
                    onPressed: onFocus,
                    icon: const Icon(Icons.center_focus_strong, size: 18),
                    label: Text(context.t.venueMap.showOnMap),
                  ),
                if (related case final destination?)
                  TextButton.icon(
                    onPressed: () => onRelated?.call(destination),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(destination.name(language)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VenuePlaceBadge extends StatelessWidget {
  const VenuePlaceBadge({required this.place, super.key});
  final VenuePlace place;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CircleAvatar(
      radius: 18,
      backgroundColor: place.boothNumber == null
          ? place.color(Theme.of(context).colorScheme).withValues(alpha: .12)
          : place.markerColor,
      child: place.boothNumber != null
          ? Text(
              '${place.boothNumber}',
              style: TextStyle(color: place.markerTextColor, fontSize: 15, fontWeight: FontWeight.w700),
            )
          : Icon(place.iconData, size: 21, color: place.color(Theme.of(context).colorScheme)),
    ),
  );
}
