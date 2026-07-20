import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/live_captions/data/provider/live_caption_rooms_provider.dart';
import 'package:app/feature/live_captions/data/provider/session_list_provider.dart';
import 'package:app/feature/live_captions/data/provider/venue_list_provider.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

/// Lists sessions to open their venue's live captions, with a QR shortcut.
class LiveCaptionsPage extends ConsumerWidget {
  const LiveCaptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final sessions = ref.watch(sessionListProvider);
    final venues = ref.watch(venueMapProvider).value ?? const {};
    final rooms = ref.watch(liveCaptionRoomsProvider).value ?? const {};
    return Scaffold(
      appBar: AppBar(
        title: Text(t.liveCaptions.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: t.liveCaptions.scanQr,
            onPressed: () => const LiveCaptionScanRoute().push<void>(context),
          ),
        ],
      ),
      body: switch (sessions) {
        AsyncData(:final value) when value.isEmpty => Center(
          child: Text(t.liveCaptions.sessionsEmpty),
        ),
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(sessionListProvider),
          child: ListView.separated(
            itemCount: value.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    t.liveCaptions.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              final session = value[index - 1];
              return _SessionTile(
                session: session,
                venue: venues[session.venueId],
                room: rooms[session.venueId],
              );
            },
          ),
        ),
        AsyncError() => Center(child: Text(t.liveCaptions.sessionsError)),
        AsyncLoading() => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, this.venue, this.room});

  final Session session;
  final Venue? venue;
  final LiveCaptionRoom? room;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final timeRange =
        '${DateFormat('MM/dd HH:mm').format(session.startsAt.toLocal())}'
        ' - ${DateFormat('HH:mm').format(session.endsAt.toLocal())}';
    final venueName = venue?.name.resolve(locale) ?? session.venueId;
    return ListTile(
      title: Text(session.title.resolve(locale)),
      subtitle: Text('$timeRange ・ $venueName'),
      trailing: (room?.isShowable ?? false)
          ? Chip(
              label: Text(t.liveCaptions.live),
              labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
            )
          : null,
      onTap: () =>
          LiveCaptionRoomRoute(venueId: session.venueId).push<void>(context),
    );
  }
}
