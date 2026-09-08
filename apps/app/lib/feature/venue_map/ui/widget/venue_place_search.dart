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
  String _query = '';
  VenuePlaceType? _type;
  @override
  Widget build(BuildContext context) {
    final t = context.t.venueMap;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final places = widget.plan.places.where((p) => (_type == null || p.type == _type) && p.matches(_query));
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: t.searchHint,
                prefixIcon: const Icon(Icons.search),
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
                  (VenuePlaceType.foyer, t.booths),
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
                    leading: Icon(place.iconData, color: place.color(theme.colorScheme)),
                    title: Text(place.name(language)),
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
  const VenuePlaceSummary({required this.place, required this.onClear, super.key});
  final VenuePlace place;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return Semantics(
      liveRegion: true,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 8),
        title: Text(place.name(language), style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(place.subtitle(language)),
        trailing: IconButton(
          tooltip: context.t.venueMap.clearSelection,
          onPressed: onClear,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}
