import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/root_navigation.dart';
import 'package:app/feature/session/data/provider/session_time_format.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

const _entryContentGap = 12.0;
const _entryBottomSpacing = 16.0;
const _parallelEntryGap = 12.0;
const _parallelScrollbarExtent = 10.0;
const _timeLabelTopPadding = 4.0;
const _timelineGapAfterTimeLabel = 6.0;

double _measureTextHeight({
  required BuildContext context,
  required String text,
  required TextStyle? style,
  required double maxWidth,
  required TextDirection textDirection,
}) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: style ?? DefaultTextStyle.of(context).style,
    ),
    textAlign: TextAlign.center,
    textDirection: textDirection,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: maxWidth);

  return textPainter.height;
}

/// Shows the conference session timetable.
class SessionTimetablePage extends HookConsumerWidget {
  const SessionTimetablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final timetable = ref.watch(sessionTimetableProvider);
    final scrollController = useScrollController();

    ref.listen(rootDestinationOpenProvider, (_, next) {
      if (next.index == RootDestinationIndex.sessions) {
        _jumpToFirst(scrollController);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(t.sessionTimetable.title)),
      body: switch (timetable) {
        AsyncData(:final value) when value.isEmpty => _TimetableEmptyState(
          data: value,
          scrollController: scrollController,
        ),
        AsyncData(:final value) => _TimetableList(
          data: value,
          scrollController: scrollController,
        ),
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
  const _TimetableList({
    required this.data,
    required this.scrollController,
  });

  final SessionTimetableData data;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = data.selectedDay;

    return RefreshIndicator(
      onRefresh: () async => _refresh(ref),
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (data.availableDates.isNotEmpty)
            SliverToBoxAdapter(
              child: _DaySelectorBar(
                dates: data.availableDates,
                selectedDate: data.selectedDate,
              ),
            ),
          if (data.venues.isNotEmpty)
            SliverToBoxAdapter(
              child: _VenueFilterBar(
                venues: data.venues,
                selectedVenueId: data.selectedVenueId,
              ),
            ),
          const SliverToBoxAdapter(child: _TimeFormatSelector()),
          if (selectedDay != null) SliverToBoxAdapter(child: _FadingDaySection(day: selectedDay)),
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

class _DaySelectorBar extends ConsumerWidget {
  const _DaySelectorBar({
    required this.dates,
    required this.selectedDate,
  });

  final List<DateTime> dates;
  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < dates.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            _AutoScrollingChoiceChip(
              label: Text(_formatDayButtonLabel(index)),
              selected: selectedDate != null && _isSameDate(dates[index], selectedDate!),
              onSelected: (_) => ref.read(sessionTimetableDayFilterProvider.notifier).select(dates[index]),
            ),
          ],
        ],
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AutoScrollingChoiceChip(
            label: Text(t.sessionTimetable.venue.all),
            selected: selectedVenueId == null,
            onSelected: (_) => ref.read(sessionTimetableVenueFilterProvider.notifier).select(null),
          ),
          for (final venue in venues) ...[
            const SizedBox(width: 8),
            _AutoScrollingChoiceChip(
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

class _TimeFormatSelector extends ConsumerWidget {
  const _TimeFormatSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final timeFormat = ref.watch(sessionTimeFormatProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AutoScrollingChoiceChip(
            label: Text(t.sessionTimetable.timeFormat.twentyFourHour),
            selected: timeFormat == EventTimeFormat.twentyFourHour,
            onSelected: (_) => unawaited(
              ref.read(sessionTimeFormatProvider.notifier).set(EventTimeFormat.twentyFourHour),
            ),
          ),
          const SizedBox(width: 8),
          _AutoScrollingChoiceChip(
            label: Text(t.sessionTimetable.timeFormat.amPm),
            selected: timeFormat == EventTimeFormat.amPm,
            onSelected: (_) => unawaited(
              ref.read(sessionTimeFormatProvider.notifier).set(EventTimeFormat.amPm),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoScrollingChoiceChip extends StatefulWidget {
  const _AutoScrollingChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  State<_AutoScrollingChoiceChip> createState() => _AutoScrollingChoiceChipState();
}

class _AutoScrollingChoiceChipState extends State<_AutoScrollingChoiceChip> {
  final _chipKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _chipKey,
      child: ChoiceChip(
        label: widget.label,
        selected: widget.selected,
        onSelected: (selected) {
          widget.onSelected(selected);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }

            final context = _chipKey.currentContext;
            if (context == null) {
              return;
            }

            unawaited(_scrollChipIntoView(context));
          });
        },
      ),
    );
  }
}

class _FadingDaySection extends HookWidget {
  const _FadingDaySection({required this.day});

  final SessionTimetableDay day;

  @override
  Widget build(BuildContext context) {
    final fadeController = useAnimationController(
      duration: const Duration(milliseconds: 700),
    );
    final fadeAnimation = fadeController.drive(
      CurveTween(curve: Curves.easeInOutCubic),
    );

    useEffect(
      () {
        unawaited(fadeController.forward(from: 0));
        return null;
      },
      [day.date],
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: _TimetableDayContent(
          day: day,
          key: ValueKey(day.date),
        ),
      ),
    );
  }
}

class _TimetableDayContent extends ConsumerWidget {
  const _TimetableDayContent({
    required this.day,
    super.key,
  });

  final SessionTimetableDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryGroups = day.entryGroups;
    final timeFormat = ref.watch(sessionTimeFormatProvider);
    final timeColumnWidth = MediaQuery.sizeOf(context).width * .1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: Theme.of(context).colorScheme.outlineVariant,
          thickness: 1,
          height: 8,
          indent: 0,
        ),
        _DayHeader(date: day.date),
        for (var index = 0; index < entryGroups.length; index++)
          _TimetableEntryGroupTile(
            entries: entryGroups[index],
            isLast: index == entryGroups.length - 1,
            timeFormat: timeFormat,
            timeColumnWidth: timeColumnWidth,
          ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    bottomLeft: Radius.circular(3),
                  ),
                ),
                child: const SizedBox(width: 4),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  DateFormat('yyyy/MM/dd').format(date),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimetableEntryGroupTile extends StatelessWidget {
  const _TimetableEntryGroupTile({
    required this.entries,
    required this.isLast,
    required this.timeFormat,
    required this.timeColumnWidth,
  });

  final List<SessionTimetableEntry> entries;
  final bool isLast;
  final EventTimeFormat timeFormat;
  final double timeColumnWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final firstEntry = entries.first;
    final textDirection = Directionality.of(context);
    final timeLabel = formatEventTime(
      firstEntry.startsAt,
      timeFormat,
      locale: locale,
    );
    final timeLabelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final lineStartY =
        _timeLabelTopPadding +
        _measureTextHeight(
          context: context,
          text: timeLabel,
          style: timeLabelStyle,
          maxWidth: timeColumnWidth,
          textDirection: textDirection,
        ) +
        _timelineGapAfterTimeLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomPaint(
        painter: _TimelineConnectorPainter(
          color: colorScheme.outlineVariant,
          showConnector: !isLast,
          textDirection: textDirection,
          timeColumnWidth: timeColumnWidth,
          lineStartY: lineStartY,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: timeColumnWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: _timeLabelTopPadding),
                child: Text(
                  timeLabel,
                  textAlign: TextAlign.center,
                  style: timeLabelStyle,
                ),
              ),
            ),
            const SizedBox(width: _entryContentGap),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: _entryBottomSpacing),
                child: entries.length == 1
                    ? _TimetableEntryCard(
                        entry: firstEntry,
                        timeFormat: timeFormat,
                      )
                    : _ParallelTimetableEntriesScroller(
                        entries: entries,
                        timeFormat: timeFormat,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineConnectorPainter extends CustomPainter {
  const _TimelineConnectorPainter({
    required this.color,
    required this.showConnector,
    required this.textDirection,
    required this.timeColumnWidth,
    required this.lineStartY,
  });

  final Color color;
  final bool showConnector;
  final TextDirection textDirection;
  final double timeColumnWidth;
  final double lineStartY;

  @override
  void paint(Canvas canvas, Size size) {
    if (!showConnector) {
      return;
    }

    final x = switch (textDirection) {
      TextDirection.ltr => timeColumnWidth / 2,
      TextDirection.rtl => size.width - (timeColumnWidth / 2),
    };

    if (size.height <= lineStartY) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(x, lineStartY),
      Offset(x, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TimelineConnectorPainter oldDelegate) {
    return color != oldDelegate.color ||
        showConnector != oldDelegate.showConnector ||
        textDirection != oldDelegate.textDirection ||
        timeColumnWidth != oldDelegate.timeColumnWidth ||
        lineStartY != oldDelegate.lineStartY;
  }
}

class _TimetableEntryCard extends StatelessWidget {
  const _TimetableEntryCard({
    required this.entry,
    required this.timeFormat,
  });

  final SessionTimetableEntry entry;
  final EventTimeFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    return entry.isSession
        ? _SessionCard(
            entry: entry,
            timeFormat: timeFormat,
          )
        : _TimelineEventCard(
            entry: entry,
            timeFormat: timeFormat,
          );
  }
}

class _ParallelTimetableEntriesScroller extends HookWidget {
  const _ParallelTimetableEntriesScroller({
    required this.entries,
    required this.timeFormat,
  });

  final List<SessionTimetableEntry> entries;
  final EventTimeFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    useListenable(scrollController);

    final colorScheme = Theme.of(context).colorScheme;
    final position = scrollController.hasClients ? scrollController.position : null;
    final showStartFade = position != null && position.extentBefore > 1;
    final showEndFade = position == null || position.extentAfter > 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final peekWidth = math.min<double>(36, viewportWidth * 0.14);
        final cardWidth = math.min<double>(
          320,
          math.max<double>(184, viewportWidth - _parallelEntryGap - peekWidth),
        );

        return Stack(
          children: [
            Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: _parallelScrollbarExtent),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < entries.length; index++) ...[
                        SizedBox(
                          width: cardWidth,
                          child: _TimetableEntryCard(
                            entry: entries[index],
                            timeFormat: timeFormat,
                          ),
                        ),
                        if (index < entries.length - 1) const SizedBox(width: _parallelEntryGap),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (showStartFade)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: _parallelScrollbarExtent,
                child: _ScrollEdgeFade(
                  color: colorScheme.surface,
                  alignment: AlignmentDirectional.centerStart,
                ),
              ),
            if (showEndFade)
              PositionedDirectional(
                end: 0,
                top: 0,
                bottom: _parallelScrollbarExtent,
                child: _ScrollEdgeFade(
                  color: colorScheme.surface,
                  alignment: AlignmentDirectional.centerEnd,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ScrollEdgeFade extends StatelessWidget {
  const _ScrollEdgeFade({
    required this.color,
    required this.alignment,
  });

  final Color color;
  final AlignmentDirectional alignment;

  @override
  Widget build(BuildContext context) {
    final isStart = alignment == AlignmentDirectional.centerStart;

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isStart ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
            end: isStart ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
        child: const SizedBox(width: 32),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.entry,
    required this.timeFormat,
  });

  final SessionTimetableEntry entry;
  final EventTimeFormat timeFormat;

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
                label: formatEventTimeRange(
                  entry.startsAt,
                  entry.endsAt,
                  timeFormat,
                  locale: locale.toLanguageTag(),
                ),
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
  const _TimelineEventCard({
    required this.entry,
    required this.timeFormat,
  });

  final SessionTimetableEntry entry;
  final EventTimeFormat timeFormat;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.event_available_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                label: formatEventTimeRange(
                  entry.startsAt,
                  entry.endsAt,
                  timeFormat,
                  locale: locale.toLanguageTag(),
                ),
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
  const _TimetableEmptyState({
    required this.data,
    required this.scrollController,
  });

  final SessionTimetableData data;
  final ScrollController scrollController;

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
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (data.availableDates.isNotEmpty)
            _DaySelectorBar(
              dates: data.availableDates,
              selectedDate: data.selectedDate,
            ),
          if (data.venues.isNotEmpty)
            _VenueFilterBar(
              venues: data.venues,
              selectedVenueId: data.selectedVenueId,
            ),
          const _TimeFormatSelector(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

String _formatDayButtonLabel(int dayIndex) {
  return 'Day ${dayIndex + 1}';
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

Future<void> _scrollChipIntoView(BuildContext context) async {
  final scrollable = Scrollable.maybeOf(context);
  if (scrollable == null) {
    return;
  }

  final position = scrollable.position;
  if (position.axisDirection != AxisDirection.left && position.axisDirection != AxisDirection.right) {
    return;
  }

  final chipRenderObject = context.findRenderObject();
  final viewportRenderObject = scrollable.context.findRenderObject();
  if (chipRenderObject is! RenderBox || viewportRenderObject is! RenderBox) {
    return;
  }

  final chipOffset = chipRenderObject.localToGlobal(Offset.zero);
  final viewportOffset = viewportRenderObject.localToGlobal(Offset.zero);
  final chipStart = chipOffset.dx - viewportOffset.dx;
  final chipEnd = chipStart + chipRenderObject.size.width;
  final viewportWidth = viewportRenderObject.size.width;

  var targetOffset = position.pixels;
  if (chipStart < 0) {
    targetOffset += chipStart;
  } else if (chipEnd > viewportWidth) {
    targetOffset += chipEnd - viewportWidth;
  } else {
    return;
  }

  final clampedOffset = targetOffset.clamp(position.minScrollExtent, position.maxScrollExtent);
  if ((clampedOffset - position.pixels).abs() < 0.5) {
    return;
  }

  await position.animateTo(
    clampedOffset,
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
  );
}

void _jumpToFirst(ScrollController controller) {
  if (!controller.hasClients) {
    return;
  }

  controller.jumpTo(controller.position.minScrollExtent);
}
