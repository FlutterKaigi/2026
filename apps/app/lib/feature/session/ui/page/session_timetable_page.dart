import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

/// Shows the conference session timetable.
class SessionTimetablePage extends ConsumerWidget {
  const SessionTimetablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final timetable = ref.watch(sessionTimetableProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.sessionTimetable.title)),
      body: switch (timetable) {
        AsyncData(:final value) when value.isEmpty => _TimetableEmptyState(data: value),
        AsyncData(:final value) => _TimetableList(data: value),
        AsyncError() => _TimetableErrorState(
          onRetry: () => _refresh(ref),
        ),
        AsyncLoading() => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      },
    );
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(sessionListProvider);
    ref.invalidate(sessionTimelineEventListProvider);
    ref.invalidate(sessionVenueListProvider);
    ref.invalidate(sessionSpeakerListProvider);
  }
}

class _TimetableList extends ConsumerWidget {
  const _TimetableList({required this.data});

  final SessionTimetableData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(ref),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (data.venues.isNotEmpty)
            SliverToBoxAdapter(
              child: _VenueFilterBar(
                venues: data.venues,
                selectedVenueId: data.selectedVenueId,
              ),
            ),
          for (final day in data.days) ...[
            SliverToBoxAdapter(child: _DayHeader(date: day.date)),
            SliverList.builder(
              itemCount: day.entries.length,
              itemBuilder: (context, index) => _TimetableEntryTile(
                entry: day.entries[index],
                isLast: index == day.entries.length - 1,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(sessionListProvider);
    ref.invalidate(sessionTimelineEventListProvider);
    ref.invalidate(sessionVenueListProvider);
    ref.invalidate(sessionSpeakerListProvider);
  }
}

class _VenueFilterBar extends ConsumerWidget {
  const _VenueFilterBar({
    required this.venues,
    required this.selectedVenueId,
  });

  final List<Venue> venues;
  final String? selectedVenueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(t.sessionTimetable.venue.all),
            selected: selectedVenueId == null,
            onSelected: (_) => ref.read(sessionTimetableVenueFilterProvider.notifier).select(null),
          ),
          for (final venue in venues) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(venue.name.resolve(locale)),
              selected: selectedVenueId == venue.id,
              onSelected: (_) => ref.read(sessionTimetableVenueFilterProvider.notifier).select(venue.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        DateFormat('yyyy/MM/dd').format(date),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TimetableEntryTile extends StatelessWidget {
  const _TimetableEntryTile({
    required this.entry,
    required this.isLast,
  });

  final SessionTimetableEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatTime(entry.startsAt),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  const SizedBox(height: 7),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.only(top: 4),
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 16),
                child: entry.isSession ? _SessionCard(entry: entry) : _TimelineEventCard(entry: entry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.entry});

  final SessionTimetableEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final session = entry.session!;
    final title = session.title.resolve(locale);
    final description = session.description.resolve(locale).trim();

    return _TimetableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.sell_outlined,
                label: _sessionTypeLabel(t, session),
              ),
              _InfoChip(
                icon: Icons.meeting_room_outlined,
                label: entry.venue?.name.resolve(locale) ?? t.sessionTimetable.venue.unknown,
              ),
              _InfoChip(
                icon: Icons.schedule,
                label: _formatTimeRange(entry.startsAt, entry.endsAt),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entry.speakers.isEmpty)
            _SpeakerPlaceholder(label: t.sessionTimetable.speaker.none)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final speaker in entry.speakers) _SpeakerChip(speaker: speaker),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimelineEventCard extends StatelessWidget {
  const _TimelineEventCard({required this.entry});

  final SessionTimetableEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final timelineEvent = entry.timelineEvent!;

    return _TimetableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_available_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timelineEvent.title.resolve(locale),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.sell_outlined,
                label: t.sessionTimetable.type.event,
              ),
              if (entry.venue != null)
                _InfoChip(
                  icon: Icons.meeting_room_outlined,
                  label: entry.venue!.name.resolve(locale),
                ),
              _InfoChip(
                icon: Icons.schedule,
                label: _formatTimeRange(entry.startsAt, entry.endsAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimetableCard extends StatelessWidget {
  const _TimetableCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      side: BorderSide(color: colorScheme.outlineVariant),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SpeakerChip extends StatelessWidget {
  const _SpeakerChip({required this.speaker});

  final Speaker speaker;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = speaker.avatarUrl;

    return Chip(
      avatar: CircleAvatar(
        backgroundImage: avatarUrl == null || avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
        child: avatarUrl == null || avatarUrl.isEmpty ? const Icon(Icons.person_outline, size: 16) : null,
      ),
      label: Text(speaker.name),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SpeakerPlaceholder extends StatelessWidget {
  const _SpeakerPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person_outline, size: 18),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _TimetableEmptyState extends ConsumerWidget {
  const _TimetableEmptyState({required this.data});

  final SessionTimetableData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final message = data.hasAnyEntries && data.selectedVenueId != null
        ? t.sessionTimetable.emptyFiltered
        : t.sessionTimetable.empty;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sessionListProvider);
        ref.invalidate(sessionTimelineEventListProvider);
        ref.invalidate(sessionVenueListProvider);
        ref.invalidate(sessionSpeakerListProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          if (data.venues.isNotEmpty)
            _VenueFilterBar(
              venues: data.venues,
              selectedVenueId: data.selectedVenueId,
            ),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
          Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _TimetableErrorState extends ConsumerWidget {
  const _TimetableErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              t.sessionTimetable.error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
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
    );
  }
}

String _sessionTypeLabel(Translations t, Session session) {
  if (session.isHandsOn) {
    return t.sessionTimetable.type.handsOn;
  }
  if (session.isBeginnersLightningTalk) {
    return t.sessionTimetable.type.beginnersLightningTalk;
  }
  if (session.isLightningTalk) {
    return t.sessionTimetable.type.lightningTalk;
  }
  return t.sessionTimetable.type.regular;
}

String _formatTimeRange(DateTime startsAt, DateTime? endsAt) {
  if (endsAt == null) {
    return _formatTime(startsAt);
  }
  return '${_formatTime(startsAt)}-${_formatTime(endsAt)}';
}

String _formatTime(DateTime value) {
  return DateFormat('HH:mm').format(toEventTime(value));
}
