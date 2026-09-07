import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/profile/ui/widget/country_flag_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Localized label for a [CountryRegion] group header.
String countryRegionLabel(Translations t, CountryRegion region) => switch (region) {
  CountryRegion.asia => t.countryRegion.asia,
  CountryRegion.oceania => t.countryRegion.oceania,
  CountryRegion.americas => t.countryRegion.americas,
  CountryRegion.europe => t.countryRegion.europe,
  CountryRegion.africa => t.countryRegion.africa,
};

/// Filters [countries] by a case-insensitive match on either localized name or
/// an exact ISO code match. An empty [query] keeps every country.
List<Country> filterCountries(String query, {List<Country> source = countries}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return source;
  }
  return [
    for (final country in source)
      if (country.name.ja.toLowerCase().contains(normalized) ||
          country.name.en.toLowerCase().contains(normalized) ||
          country.code.toLowerCase() == normalized)
        country,
  ];
}

/// Opens the country picker as a modal bottom sheet and returns the chosen
/// [Country], or `null` when dismissed.
Future<Country?> showCountryPickerSheet(BuildContext context, {Country? selected}) => showModalBottomSheet<Country>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.9,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (context, scrollController) => CountryPickerSheet(
      selected: selected,
      scrollController: scrollController,
      onSelected: (country) => Navigator.of(context).pop(country),
    ),
  ),
);

/// Searchable list of every selectable country, grouped by region.
///
/// Asia is listed first with Japan at the top of it so the majority of
/// attendees can pick their country with one tap; everyone else can search by
/// Japanese name, English name or ISO code.
class CountryPickerSheet extends HookWidget {
  const CountryPickerSheet({
    required this.onSelected,
    this.selected,
    this.scrollController,
    super.key,
  });

  final ValueChanged<Country> onSelected;
  final Country? selected;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final query = useState('');
    final searchController = useTextEditingController();
    final filtered = useMemoized(() => filterCountries(query.value), [query.value]);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.profile.countryLabel,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              // SearchBar はオートコレクトを切れず、ISO コード("tw" など)が
              // 入力候補に置き換えられてしまうため TextField で組む。
              // 見た目はリスト行と同じ平面・密度(48px, elevation なし)に揃える。
              TextField(
                controller: searchController,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.search,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: t.profile.countrySearchHint,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.search, size: 22, color: theme.colorScheme.onSurfaceVariant),
                  suffixIcon: query.value.isEmpty
                      ? null
                      : IconButton(
                          tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                          onPressed: () {
                            searchController.clear();
                            query.value = '';
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: (value) => query.value = value,
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyResults(query: query.value)
              : _CountryList(
                  countries: filtered,
                  selected: selected,
                  scrollController: scrollController,
                  onSelected: onSelected,
                ),
        ),
      ],
    );
  }
}

class _CountryList extends StatelessWidget {
  const _CountryList({
    required this.countries,
    required this.selected,
    required this.scrollController,
    required this.onSelected,
  });

  final List<Country> countries;
  final Country? selected;
  final ScrollController? scrollController;
  final ValueChanged<Country> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final isJapanese = locale.languageCode == 'ja';

    // 地域ヘッダーと国の行を1つのリストに並べる。
    final rows = <Widget>[];
    CountryRegion? currentRegion;
    for (final country in countries) {
      if (country.region != currentRegion) {
        currentRegion = country.region;
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              countryRegionLabel(t, country.region),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
      final isSelected = country.code == selected?.code;
      rows.add(
        ListTile(
          key: ValueKey(country.code),
          selected: isSelected,
          selectedTileColor: theme.colorScheme.primaryContainer,
          leading: CountryFlagIcon(country: country, height: 22),
          title: Text(country.name.resolve(locale)),
          // もう一方の言語の名前を添えて、どちらの言語で探している人にも分かるようにする。
          subtitle: Text(isJapanese ? country.name.en : country.name.ja),
          trailing: isSelected
              ? Icon(Icons.check, color: theme.colorScheme.primary)
              : Text(
                  country.code,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
          onTap: () => onSelected(country),
        ),
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      children: rows,
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            t.profile.countryNoResults(query: query),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            t.profile.countryNoResultsHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
