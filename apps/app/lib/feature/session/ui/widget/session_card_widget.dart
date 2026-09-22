import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/ui/widget/session_bookmark_button.dart';
import 'package:app/feature/session/ui/widget/session_speaker_widget.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:app/feature/session/util/session_language.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';

class SessionCardWidget extends StatelessWidget {
  const SessionCardWidget({
    required this.entry,
    required this.timeFormat,
    this.compact = false,
    this.onTap,
    super.key,
  });

  final SessionTimetableEntry entry;
  final EventTimeFormat timeFormat;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final session = entry.session!;
    final title = session.title.resolve(locale);
    final description = session.description.resolve(locale).trim();
    final languageLabel = sessionLanguageLabel(session.primaryLocale);

    return _SessionCardSurfaceWidget(
      onTap: onTap ?? () => SessionDetailsRoute(sessionId: session.id).push<void>(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MetadataTagWidget(
                      icon: Icons.sell_outlined,
                      label: _sessionTypeLabel(t, session),
                    ),
                    _MetadataTagWidget(
                      icon: Icons.meeting_room_outlined,
                      label: entry.venue?.name.resolve(locale) ?? t.sessionTimetable.venue.unknown,
                    ),
                    if (languageLabel != null)
                      _MetadataTagWidget(
                        label: languageLabel,
                      ),
                    if (!compact)
                      _MetadataTagWidget(
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
              ),
              const SizedBox(width: 4),
              SessionBookmarkButton(sessionId: session.id),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            key: ValueKey('session-title-${session.id}'),
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!compact && description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (entry.speakers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final speaker in entry.speakers) SessionSpeakerChipWidget(speaker: speaker),
              ],
            ),
          ] else if (!compact) ...[
            const SizedBox(height: 10),
            _SpeakerPlaceholderWidget(label: t.sessionTimetable.speaker.none),
          ],
        ],
      ),
    );
  }
}

class _MetadataTagWidget extends StatelessWidget {
  const _MetadataTagWidget({
    required this.label,
    this.icon,
  });

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCardSurfaceWidget extends StatelessWidget {
  const _SessionCardSurfaceWidget({required this.child, this.onTap});

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
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
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
  if (session.isBeginnersLightningTalk) {
    return t.sessionTimetable.type.beginnersLightningTalk;
  }
  if (session.isLightningTalk) {
    return t.sessionTimetable.type.lightningTalk;
  }
  return t.sessionTimetable.type.regular;
}
