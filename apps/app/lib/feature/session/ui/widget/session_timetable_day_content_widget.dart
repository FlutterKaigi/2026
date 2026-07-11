import 'dart:math' as math;

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
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

class SessionTimetableDayContentWidget extends ConsumerWidget {
  const SessionTimetableDayContentWidget({
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
        _DayHeaderWidget(date: day.date),
        for (var index = 0; index < entryGroups.length; index++)
          _TimetableEntryGroupTileWidget(
            entries: entryGroups[index],
            isLast: index == entryGroups.length - 1,
            timeFormat: timeFormat,
            timeColumnWidth: timeColumnWidth,
          ),
      ],
    );
  }
}

class _DayHeaderWidget extends StatelessWidget {
  const _DayHeaderWidget({required this.date});

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
          borderRadius: const BorderRadius.all(
            Radius.circular(8),
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

class _TimetableEntryGroupTileWidget extends StatelessWidget {
  const _TimetableEntryGroupTileWidget({
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
        painter: _TimelineConnectorPainterWidget(
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
                    ? _TimetableEntryCardWidget(
                        entry: firstEntry,
                        timeFormat: timeFormat,
                      )
                    : _ParallelTimetableEntriesScrollerWidget(
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

class _TimelineConnectorPainterWidget extends CustomPainter {
  const _TimelineConnectorPainterWidget({
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
  bool shouldRepaint(_TimelineConnectorPainterWidget oldDelegate) {
    return color != oldDelegate.color ||
        showConnector != oldDelegate.showConnector ||
        textDirection != oldDelegate.textDirection ||
        timeColumnWidth != oldDelegate.timeColumnWidth ||
        lineStartY != oldDelegate.lineStartY;
  }
}

class _TimetableEntryCardWidget extends StatelessWidget {
  const _TimetableEntryCardWidget({
    required this.entry,
    required this.timeFormat,
  });

  final SessionTimetableEntry entry;
  final EventTimeFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    return entry.isSession
        ? _SessionCardWidget(
            entry: entry,
            timeFormat: timeFormat,
          )
        : _TimelineEventCardWidget(
            entry: entry,
            timeFormat: timeFormat,
          );
  }
}

class _ParallelTimetableEntriesScrollerWidget extends HookWidget {
  const _ParallelTimetableEntriesScrollerWidget({
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
                          child: _TimetableEntryCardWidget(
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
                child: _ScrollEdgeFadeWidget(
                  color: colorScheme.surface,
                  alignment: AlignmentDirectional.centerStart,
                ),
              ),
            if (showEndFade)
              PositionedDirectional(
                end: 0,
                top: 0,
                bottom: _parallelScrollbarExtent,
                child: _ScrollEdgeFadeWidget(
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

class _ScrollEdgeFadeWidget extends StatelessWidget {
  const _ScrollEdgeFadeWidget({
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

class _SessionCardWidget extends StatelessWidget {
  const _SessionCardWidget({
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

    return _TimetableCardWidget(
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
              _InfoChipWidget(
                icon: Icons.sell_outlined,
                label: _sessionTypeLabel(t, session),
              ),
              _InfoChipWidget(
                icon: Icons.meeting_room_outlined,
                label: entry.venue?.name.resolve(locale) ?? t.sessionTimetable.venue.unknown,
              ),
              _InfoChipWidget(
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
            _SpeakerPlaceholderWidget(label: t.sessionTimetable.speaker.none)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final speaker in entry.speakers) _SpeakerChipWidget(speaker: speaker),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimelineEventCardWidget extends StatelessWidget {
  const _TimelineEventCardWidget({
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

    return _TimetableCardWidget(
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
              _InfoChipWidget(
                icon: Icons.sell_outlined,
                label: t.sessionTimetable.type.event,
              ),
              if (entry.venue != null)
                _InfoChipWidget(
                  icon: Icons.meeting_room_outlined,
                  label: entry.venue!.name.resolve(locale),
                ),
              _InfoChipWidget(
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

class _TimetableCardWidget extends StatelessWidget {
  const _TimetableCardWidget({required this.child});

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

class _InfoChipWidget extends StatelessWidget {
  const _InfoChipWidget({
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

class _SpeakerChipWidget extends StatelessWidget {
  const _SpeakerChipWidget({required this.speaker});

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

class _SpeakerPlaceholderWidget extends StatelessWidget {
  const _SpeakerPlaceholderWidget({required this.label});

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
