import 'dart:async';

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/session/data/provider/session_detail_provider.dart';
import 'package:app/feature/session/data/provider/session_time_format.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const _sessionOrigin = 'https://2026.flutterkaigi.jp';

class SessionDetailsContentWidget extends ConsumerWidget {
  const SessionDetailsContentWidget({
    required this.data,
    super.key,
  });

  final SessionDetailData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final session = data.session;
    final title = session.title.resolve(locale);
    final timeFormat = ref.watch(sessionTimeFormatProvider);
    final sessionizeUri = _externalUri(session.sessionizeUrl);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(title),
            actions: [
              IconButton(
                tooltip: t.sessionDetails.share,
                onPressed: () => unawaited(_shareSession(data, locale)),
                icon: const Icon(Icons.share_outlined),
              ),
            ],
          ),
          SliverList.list(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.sell_outlined,
                      label: _sessionTypeLabel(t, session),
                    ),
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: DateFormat('yyyy/MM/dd').format(toEventTime(session.startsAt)),
                    ),
                    _InfoChip(
                      icon: Icons.schedule,
                      label: formatEventTimeRange(
                        session.startsAt,
                        session.endsAt,
                        timeFormat,
                        locale: locale.toLanguageTag(),
                      ),
                    ),
                    _InfoChip(
                      icon: Icons.meeting_room_outlined,
                      label: data.venue?.name.resolve(locale) ?? t.sessionTimetable.venue.unknown,
                    ),
                  ],
                ),
              ),
              if (data.speakers.isNotEmpty) ...[
                _SectionHeader(title: t.sessionDetails.speakers),
                for (final speaker in data.speakers) _SpeakerTile(speaker: speaker),
              ],
              _SectionHeader(title: t.sessionDetails.description),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  session.description.resolve(locale).trim(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              _SectionHeader(title: t.sessionDetails.schedule),
              _DetailListTile(
                icon: Icons.event_outlined,
                title: DateFormat('yyyy/MM/dd').format(toEventTime(session.startsAt)),
              ),
              _DetailListTile(
                icon: Icons.schedule,
                title: formatEventTimeRange(
                  session.startsAt,
                  session.endsAt,
                  timeFormat,
                  locale: locale.toLanguageTag(),
                ),
              ),
              _DetailListTile(
                icon: Icons.room_outlined,
                title: data.venue?.name.resolve(locale) ?? t.sessionTimetable.venue.unknown,
              ),
              if (sessionizeUri != null) ...[
                _SectionHeader(title: t.sessionDetails.links),
                _DetailListTile(
                  icon: Icons.open_in_new,
                  title: t.sessionDetails.sessionize,
                  subtitle: sessionizeUri.toString(),
                  onTap: () => unawaited(
                    launchUrl(sessionizeUri, mode: LaunchMode.externalApplication),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SpeakerTile extends StatelessWidget {
  const _SpeakerTile({required this.speaker});

  final Speaker speaker;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = speaker.avatarUrl;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: avatarUrl == null || avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
        child: avatarUrl == null || avatarUrl.isEmpty ? const Icon(Icons.person_outline) : null,
      ),
      title: Text(speaker.name),
      subtitle: speaker.bio == null || speaker.bio!.trim().isEmpty ? null : Text(speaker.bio!.trim()),
    );
  }
}

class _DetailListTile extends StatelessWidget {
  const _DetailListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: onTap == null ? null : const Icon(Icons.open_in_new),
      onTap: onTap,
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
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      visualDensity: VisualDensity.compact,
    );
  }
}

Future<void> _shareSession(SessionDetailData data, Locale locale) async {
  final session = data.session;
  final sessionUrl = Uri.parse('$_sessionOrigin/sessions/${session.id}');
  final speakerNames = data.speakers.map((speaker) => speaker.name).join(', ');
  final text = [
    session.title.resolve(locale),
    if (speakerNames.isNotEmpty) speakerNames,
    sessionUrl.toString(),
  ].join('\n');
  final intentUri = Uri.https('x.com', '/intent/post', {
    'text': text,
    'hashtags': 'FlutterKaigi2026',
  });

  await launchUrl(intentUri, mode: LaunchMode.externalApplication);
}

Uri? _externalUri(String? rawUrl) {
  final trimmed = rawUrl?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) {
    return null;
  }
  return uri;
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
