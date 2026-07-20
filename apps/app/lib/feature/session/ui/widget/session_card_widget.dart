import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/session_bookmark_button.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';

class SessionCardWidget extends StatelessWidget {
  const SessionCardWidget({
    required this.entry,
    required this.timeFormat,
    this.onTap,
    super.key,
  });

  final SessionTimetableEntry entry;
  final EventTimeFormat timeFormat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final session = entry.session!;
    final title = session.title.resolve(locale);
    final description = session.description.resolve(locale).trim();

    return _SessionCardSurfaceWidget(
      onTap: onTap ?? () => SessionDetailsRoute(sessionId: session.id).push<void>(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SessionBookmarkButton(sessionId: session.id),
            ],
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

class _SessionCardSurfaceWidget extends StatelessWidget {
  const _SessionCardSurfaceWidget({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
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
