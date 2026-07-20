import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/live_captions/data/provider/live_caption_room_provider.dart';
import 'package:app/feature/live_captions/data/provider/live_caption_segments_provider.dart';
import 'package:app/feature/live_captions/data/provider/session_list_provider.dart';
import 'package:app/feature/live_captions/data/provider/venue_list_provider.dart';
import 'package:collection/collection.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Which text a caption segment is rendered with.
enum CaptionDisplayLanguage { ja, en, original }

/// Shows the live translated captions of one venue (= caption room).
class LiveCaptionRoomPage extends ConsumerStatefulWidget {
  const LiveCaptionRoomPage({required this.venueId, super.key});

  final String venueId;

  @override
  ConsumerState<LiveCaptionRoomPage> createState() => _LiveCaptionRoomPageState();
}

class _LiveCaptionRoomPageState extends ConsumerState<LiveCaptionRoomPage> {
  CaptionDisplayLanguage? _selectedLanguage;

  CaptionDisplayLanguage _effectiveLanguage(BuildContext context) {
    if (_selectedLanguage case final selected?) {
      return selected;
    }
    return Localizations.localeOf(context).languageCode == 'ja'
        ? CaptionDisplayLanguage.ja
        : CaptionDisplayLanguage.en;
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final locale = Localizations.localeOf(context);
    final room = ref.watch(liveCaptionRoomProvider(widget.venueId));
    final venueName = ref
        .watch(venueMapProvider)
        .value?[widget.venueId]
        ?.name
        .resolve(locale);
    return Scaffold(
      appBar: AppBar(title: Text(venueName ?? widget.venueId)),
      body: switch (room) {
        AsyncData(:final value) => _buildRoom(context, t, value),
        AsyncError() => Center(child: Text(t.liveCaptions.room.error)),
        AsyncLoading() => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      },
    );
  }

  Widget _buildRoom(BuildContext context, Translations t, LiveCaptionRoom? room) {
    if (room == null) {
      return Center(child: Text(t.liveCaptions.room.waiting));
    }
    if (!room.enabled) {
      return Center(child: Text(t.liveCaptions.room.disabled));
    }
    final language = _effectiveLanguage(context);
    return Column(
      children: [
        if (!room.isLive)
          MaterialBanner(
            content: Text(t.liveCaptions.room.notLive),
            leading: const Icon(Icons.pause_circle_outline),
            actions: const [SizedBox.shrink()],
          ),
        _CurrentSessionHeader(venueId: widget.venueId),
        Expanded(child: _SegmentList(venueId: widget.venueId, language: language)),
        if (room.isLive && (room.interim?.text.isNotEmpty ?? false))
          _InterimBar(text: room.interim!.text),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<CaptionDisplayLanguage>(
              segments: [
                const ButtonSegment(
                  value: CaptionDisplayLanguage.ja,
                  label: Text('日本語'),
                ),
                const ButtonSegment(
                  value: CaptionDisplayLanguage.en,
                  label: Text('English'),
                ),
                ButtonSegment(
                  value: CaptionDisplayLanguage.original,
                  label: Text(t.liveCaptions.room.original),
                ),
              ],
              selected: {language},
              onSelectionChanged: (selection) =>
                  setState(() => _selectedLanguage = selection.single),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows the session currently scheduled in this venue, when there is one.
class _CurrentSessionHeader extends ConsumerWidget {
  const _CurrentSessionHeader({required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();
    final session = ref
        .watch(sessionListProvider)
        .value
        ?.firstWhereOrNull(
          (session) =>
              session.venueId == venueId &&
              !now.isBefore(session.startsAt) &&
              !now.isAfter(session.endsAt),
        );
    if (session == null) {
      return const SizedBox.shrink();
    }
    return ListTile(
      dense: true,
      leading: const Icon(Icons.play_circle_outline),
      title: Text(
        session.title.resolve(locale),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

class _SegmentList extends ConsumerWidget {
  const _SegmentList({required this.venueId, required this.language});

  final String venueId;
  final CaptionDisplayLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final segments = ref.watch(liveCaptionSegmentsProvider(venueId));
    return switch (segments) {
      AsyncData(:final value) when value.isEmpty => Center(
        child: Text(t.liveCaptions.room.empty),
      ),
      AsyncData(:final value) => ListView.builder(
        // reverse + reversed items keep the view pinned to the newest caption.
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: value.length,
        itemBuilder: (context, index) {
          final segment = value[value.length - 1 - index];
          final text = switch (language) {
            CaptionDisplayLanguage.ja => segment.ja,
            CaptionDisplayLanguage.en => segment.en,
            CaptionDisplayLanguage.original => segment.srcText,
          };
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          );
        },
      ),
      AsyncError() => Center(child: Text(t.liveCaptions.room.error)),
      AsyncLoading() => const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    };
  }
}

/// The in-progress (not yet finalized) transcript line.
class _InterimBar extends StatelessWidget {
  const _InterimBar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
