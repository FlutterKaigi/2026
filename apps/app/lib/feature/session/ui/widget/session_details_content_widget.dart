import 'dart:async';

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/feature/session/data/provider/session_detail_provider.dart';
import 'package:app/feature/session/ui/widget/session_bookmark_button.dart';
import 'package:app/feature/session/ui/widget/session_speaker_widget.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:app/feature/session/util/session_language.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _sessionOrigin = 'https://2026.flutterkaigi.jp';
const _largeAppBarCollapsedHeight = 64.0;
const _largeAppBarTitleBottomPadding = 28.0;
const _largeAppBarMaxTitleScaleFactor = 1.34;
const _largeAppBarTitleHorizontalPadding = 32.0;
const _sessionDetailsMaxWidth = 760.0;

class SessionDetailsContentWidget extends StatelessWidget {
  const SessionDetailsContentWidget({
    required this.data,
    super.key,
  });

  final SessionDetailData data;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final session = data.session;
    final title = session.title.resolve(locale);
    final description = session.description.resolve(locale).trim();
    final languageLabel = sessionLanguageLabel(session.primaryLocale);
    const timeFormat = EventTimeFormat.twentyFourHour;
    final sessionizeUri = _externalUri(session.sessionizeUrl);

    return Scaffold(
      body: AppScrollbar(
        child: CustomScrollView(
          slivers: [
            SliverLayoutBuilder(
              builder: (context, constraints) => SliverAppBar.large(
                expandedHeight: _sessionTitleExpandedHeight(
                  context: context,
                  title: title,
                  maxWidth: constraints.crossAxisExtent,
                ),
                title: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                actions: [
                  SessionBookmarkButton(sessionId: session.id),
                  IconButton(
                    tooltip: t.sessionDetails.share,
                    onPressed: () => unawaited(
                      _shareSession(
                        context,
                        data,
                        locale,
                        t.links.openError,
                      ),
                    ),
                    icon: const Icon(Icons.share_outlined),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  key: const ValueKey('session-details-content'),
                  constraints: const BoxConstraints(
                    maxWidth: _sessionDetailsMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.sell_outlined,
                              label: _sessionTypeLabel(t, session),
                            ),
                            if (languageLabel != null)
                              _InfoChip(
                                icon: Icons.language,
                                label: languageLabel,
                              ),
                            _InfoChip(
                              icon: Icons.calendar_today_outlined,
                              label: DateFormat(
                                'yyyy/MM/dd',
                              ).format(toEventTime(session.startsAt)),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var index = 0; index < data.speakers.length; index++) ...[
                                _SpeakerDetailsWidget(
                                  speaker: data.speakers[index],
                                ),
                                if (index < data.speakers.length - 1) const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        _SectionHeader(title: t.sessionDetails.description),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                      _SectionHeader(title: t.sessionDetails.schedule),
                      _DetailListTile(
                        icon: Icons.event_outlined,
                        title: DateFormat(
                          'yyyy/MM/dd',
                        ).format(toEventTime(session.startsAt)),
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
                            launchExternalUrl(
                              context,
                              uri: sessionizeUri,
                              failureMessage: t.links.openError,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _sessionTitleExpandedHeight({
  required BuildContext context,
  required String title,
  required double maxWidth,
}) {
  final textPainter =
      TextPainter(
        text: TextSpan(
          text: title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(
          context,
        ).clamp(maxScaleFactor: _largeAppBarMaxTitleScaleFactor),
      )..layout(
        maxWidth: maxWidth - _largeAppBarTitleHorizontalPadding,
      );

  return _largeAppBarCollapsedHeight + _largeAppBarTitleBottomPadding + textPainter.height;
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
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SpeakerDetailsWidget extends StatelessWidget {
  const _SpeakerDetailsWidget({required this.speaker});

  final Speaker speaker;

  @override
  Widget build(BuildContext context) {
    final bio = speaker.bio?.trim();
    return Row(
      key: ValueKey('session-speaker-details-${speaker.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SessionSpeakerAvatarWidget(
          speaker: speaker,
          size: 56,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key: ValueKey('session-speaker-name-${speaker.id}'),
                speaker.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  bio,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ],
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
  const _InfoChip({required this.icon, required this.label});

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

Future<void> _shareSession(
  BuildContext context,
  SessionDetailData data,
  Locale locale,
  String failureMessage,
) async {
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

  await launchExternalUrl(
    context,
    uri: intentUri,
    failureMessage: failureMessage,
  );
}

Uri? _externalUri(String? rawUrl) {
  final trimmed = rawUrl?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    return null;
  }
  return uri;
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
