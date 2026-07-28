import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/feature/session/data/provider/session_search_provider.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/session_card_widget.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SessionSearchPage extends HookConsumerWidget {
  const SessionSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final queryController = useTextEditingController();
    final query = useState('');
    final selectedDate = useState<DateTime?>(null);
    final selectedType = useState(SessionSearchTypeFilter.all);
    final selectedLanguage = useState(SessionSearchLanguageFilter.all);
    final timetable = ref.watch(sessionTimetableProvider);

    void clearSearch() {
      queryController.clear();
      query.value = '';
      selectedDate.value = null;
      selectedType.value = SessionSearchTypeFilter.all;
      selectedLanguage.value = SessionSearchLanguageFilter.all;
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: queryController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (value) => query.value = value,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: t.sessionSearch.hint,
          ),
        ),
        actions: [
          if (query.value.isNotEmpty ||
              selectedDate.value != null ||
              selectedType.value != SessionSearchTypeFilter.all ||
              selectedLanguage.value != SessionSearchLanguageFilter.all)
            IconButton(
              tooltip: t.sessionSearch.clear,
              onPressed: clearSearch,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: switch (timetable) {
        AsyncData(:final value) => _SessionSearchContentWidget(
          data: value,
          criteria: SessionSearchCriteria(
            query: query.value,
            date: selectedDate.value,
            type: selectedType.value,
            language: selectedLanguage.value,
          ),
          onDateChanged: (value) => selectedDate.value = value,
          onTypeChanged: (value) => selectedType.value = value,
          onLanguageChanged: (value) => selectedLanguage.value = value,
          onClear: clearSearch,
        ),
        AsyncError(:final error) => AppErrorView(
          error: error,
          onRetry: () => _retry(ref),
        ),
        AsyncLoading() => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      },
    );
  }

  void _retry(WidgetRef ref) {
    ref.invalidate(sessionListProvider);
    ref.invalidate(sessionTimelineEventListProvider);
    ref.invalidate(sessionVenueListProvider);
    ref.invalidate(sessionSpeakerListProvider);
  }
}

class _SessionSearchContentWidget extends StatelessWidget {
  const _SessionSearchContentWidget({
    required this.data,
    required this.criteria,
    required this.onDateChanged,
    required this.onTypeChanged,
    required this.onLanguageChanged,
    required this.onClear,
  });

  final SessionTimetableData data;
  final SessionSearchCriteria criteria;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<SessionSearchTypeFilter> onTypeChanged;
  final ValueChanged<SessionSearchLanguageFilter> onLanguageChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final results = buildSessionSearchResults(
      data: data,
      criteria: criteria,
    );

    return Column(
      children: [
        _SessionSearchFilterBarWidget(
          dates: data.availableDates,
          selectedDate: criteria.date,
          selectedType: criteria.type,
          selectedLanguage: criteria.language,
          onDateChanged: onDateChanged,
          onTypeChanged: onTypeChanged,
          onLanguageChanged: onLanguageChanged,
        ),
        const Divider(height: 1),
        Expanded(
          child: !criteria.hasCriteria
              ? _SearchMessageWidget(
                  icon: Icons.manage_search,
                  title: t.sessionSearch.promptTitle,
                  body: t.sessionSearch.promptBody,
                )
              : results.isEmpty
              ? _SearchMessageWidget(
                  icon: Icons.search_off,
                  title: t.sessionSearch.emptyTitle,
                  body: t.sessionSearch.emptyBody,
                  action: OutlinedButton(
                    onPressed: onClear,
                    child: Text(t.sessionSearch.clear),
                  ),
                )
              : _SessionSearchResultsWidget(
                  entries: results,
                  availableDates: data.availableDates,
                ),
        ),
      ],
    );
  }
}

class _SessionSearchFilterBarWidget extends StatelessWidget {
  const _SessionSearchFilterBarWidget({
    required this.dates,
    required this.selectedDate,
    required this.selectedType,
    required this.selectedLanguage,
    required this.onDateChanged,
    required this.onTypeChanged,
    required this.onLanguageChanged,
  });

  final List<DateTime> dates;
  final DateTime? selectedDate;
  final SessionSearchTypeFilter selectedType;
  final SessionSearchLanguageFilter selectedLanguage;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<SessionSearchTypeFilter> onTypeChanged;
  final ValueChanged<SessionSearchLanguageFilter> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final selectedDateIndex = selectedDate == null ? -1 : dates.indexWhere((date) => _isSameDate(date, selectedDate!));
    final dateLabel = selectedDateIndex < 0
        ? t.sessionSearch.dateChip
        : t.sessionTimetable.dayButtonLabel(
            day: selectedDateIndex + 1,
            date: '${dates[selectedDateIndex].month}/${dates[selectedDateIndex].day}',
          );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          PopupMenuButton<int>(
            tooltip: t.sessionSearch.dateFilter,
            initialValue: selectedDateIndex,
            onSelected: (index) => onDateChanged(index < 0 ? null : dates[index]),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: -1,
                child: Text(t.sessionSearch.allDates),
              ),
              for (var index = 0; index < dates.length; index++)
                PopupMenuItem(
                  value: index,
                  child: Text(
                    t.sessionTimetable.dayButtonLabel(
                      day: index + 1,
                      date: '${dates[index].month}/${dates[index].day}',
                    ),
                  ),
                ),
            ],
            child: _FilterPillWidget(
              icon: Icons.calendar_today_outlined,
              label: dateLabel,
              selected: selectedDateIndex >= 0,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<SessionSearchTypeFilter>(
            tooltip: t.sessionSearch.typeFilter,
            initialValue: selectedType,
            onSelected: onTypeChanged,
            itemBuilder: (context) => [
              for (final type in SessionSearchTypeFilter.values)
                PopupMenuItem(
                  value: type,
                  child: Text(_typeLabel(t, type)),
                ),
            ],
            child: _FilterPillWidget(
              icon: Icons.sell_outlined,
              label: selectedType == SessionSearchTypeFilter.all
                  ? t.sessionSearch.typeChip
                  : _typeLabel(t, selectedType),
              selected: selectedType != SessionSearchTypeFilter.all,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<SessionSearchLanguageFilter>(
            tooltip: t.sessionSearch.languageFilter,
            initialValue: selectedLanguage,
            onSelected: onLanguageChanged,
            itemBuilder: (context) => [
              for (final language in SessionSearchLanguageFilter.values)
                PopupMenuItem(
                  value: language,
                  child: Text(_languageLabel(t, language)),
                ),
            ],
            child: _FilterPillWidget(
              icon: Icons.language,
              label: selectedLanguage == SessionSearchLanguageFilter.all
                  ? t.sessionSearch.languageChip
                  : _languageLabel(t, selectedLanguage),
              selected: selectedLanguage != SessionSearchLanguageFilter.all,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPillWidget extends StatelessWidget {
  const _FilterPillWidget({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? colorScheme.secondaryContainer : colorScheme.surface,
        border: Border.all(
          color: selected ? colorScheme.secondary : colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SessionSearchResultsWidget extends StatelessWidget {
  const _SessionSearchResultsWidget({
    required this.entries,
    required this.availableDates,
  });

  final List<SessionTimetableEntry> entries;
  final List<DateTime> availableDates;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final groupedEntries = _groupByDate(entries);

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              t.sessionSearch.resultCount(n: entries.length),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        for (final group in groupedEntries) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                _dayLabel(t, availableDates, group.date),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: group.entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = group.entries[index];
                return SessionCardWidget(
                  entry: entry,
                  timeFormat: EventTimeFormat.twentyFourHour,
                  onTap: () => SessionDetailsRoute(sessionId: entry.id).push<void>(context),
                );
              },
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _SearchMessageWidget extends StatelessWidget {
  const _SearchMessageWidget({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

String _typeLabel(Translations t, SessionSearchTypeFilter type) {
  return switch (type) {
    SessionSearchTypeFilter.all => t.sessionSearch.allTypes,
    SessionSearchTypeFilter.regular => t.sessionTimetable.type.regular,
    SessionSearchTypeFilter.lightningTalk => t.sessionTimetable.type.lightningTalk,
    SessionSearchTypeFilter.beginnersLightningTalk => t.sessionTimetable.type.beginnersLightningTalk,
    SessionSearchTypeFilter.handsOn => t.sessionTimetable.type.handsOn,
  };
}

String _languageLabel(
  Translations t,
  SessionSearchLanguageFilter language,
) {
  return switch (language) {
    SessionSearchLanguageFilter.all => t.sessionSearch.allLanguages,
    SessionSearchLanguageFilter.ja => 'JA',
    SessionSearchLanguageFilter.en => 'EN',
  };
}

String _dayLabel(
  Translations t,
  List<DateTime> availableDates,
  DateTime date,
) {
  final index = availableDates.indexWhere((candidate) => _isSameDate(candidate, date));
  if (index < 0) {
    return '${date.month}/${date.day}';
  }
  return t.sessionTimetable.dayButtonLabel(
    day: index + 1,
    date: '${date.month}/${date.day}',
  );
}

List<({DateTime date, List<SessionTimetableEntry> entries})> _groupByDate(
  List<SessionTimetableEntry> entries,
) {
  final groups = <({DateTime date, List<SessionTimetableEntry> entries})>[];
  for (final entry in entries) {
    final date = eventDateOnly(entry.startsAt);
    if (groups.isEmpty || !_isSameDate(groups.last.date, date)) {
      groups.add((date: date, entries: [entry]));
    } else {
      groups.last.entries.add(entry);
    }
  }
  return groups;
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
