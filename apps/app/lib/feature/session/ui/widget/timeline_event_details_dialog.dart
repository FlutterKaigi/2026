import 'dart:async';

import 'package:app/core/extension/locale_map_extension.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/feature/session/data/provider/session_timetable_provider.dart';
import 'package:app/feature/session/util/event_time.dart';
import 'package:data/data.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension TimelineEventDetailsX on TimelineEvent {
  /// The description in [locale], or null when it is blank in both locales.
  String? resolveDescription(Locale locale) {
    final description = this.description?.resolve(locale).trim();
    return description == null || description.isEmpty ? null : description;
  }
}

Future<void> showTimelineEventDetailsDialog(
  BuildContext context, {
  required SessionTimetableEntry entry,
  required String? description,
  ExternalUrlLauncher? launcher,
}) {
  final locale = Localizations.localeOf(context);
  final venue = entry.venue;
  final theme = Theme.of(context);

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('timeline-event-details-dialog'),
      scrollable: true,
      title: Text(entry.timelineEvent!.title.resolve(locale)),
      contentTextStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRowWidget(
            icon: Icons.calendar_today_outlined,
            label: DateFormat('yyyy/MM/dd').format(toEventTime(entry.startsAt)),
          ),
          const SizedBox(height: 10),
          _InfoRowWidget(
            icon: Icons.schedule,
            label: formatEventTimeRange(
              entry.startsAt,
              entry.endsAt,
              EventTimeFormat.twentyFourHour,
              locale: locale.toLanguageTag(),
            ),
          ),
          if (venue != null) ...[
            const SizedBox(height: 10),
            _InfoRowWidget(
              icon: Icons.meeting_room_outlined,
              label: venue.name.resolve(locale),
            ),
          ],
          if (description != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _DescriptionText(description: description, launcher: launcher),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    ),
  );
}

class _InfoRowWidget extends StatelessWidget {
  const _InfoRowWidget({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    );
  }
}

/// An http(s) URL, ending at whitespace or the first non-ASCII character so
/// that a URL followed directly by Japanese text (e.g. `。`) stops there.
final _urlPattern = RegExp('https?://[!-~]+');

/// Sentence punctuation that follows a URL rather than belonging to it.
final _trailingPunctuation = RegExp(r'''[.,;:!?'")\]}>]+$''');

/// [description] with each http(s) URL in it tappable to open it.
class _DescriptionText extends StatefulWidget {
  const _DescriptionText({required this.description, this.launcher});

  final String description;
  final ExternalUrlLauncher? launcher;

  @override
  State<_DescriptionText> createState() => _DescriptionTextState();
}

class _DescriptionTextState extends State<_DescriptionText> {
  late List<(String, TapGestureRecognizer?)> _segments = _linkify(widget.description);

  @override
  void didUpdateWidget(_DescriptionText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.description != widget.description) {
      _disposeRecognizers();
      _segments = _linkify(widget.description);
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final (_, recognizer) in _segments) {
      recognizer?.dispose();
    }
  }

  List<(String, TapGestureRecognizer?)> _linkify(String text) {
    final segments = <(String, TapGestureRecognizer?)>[];
    var start = 0;
    for (final match in _urlPattern.allMatches(text)) {
      final url = match[0]!.replaceFirst(_trailingPunctuation, '');
      final uri = Uri.tryParse(url);
      if (uri == null || uri.host.isEmpty) {
        continue;
      }
      segments
        ..add((text.substring(start, match.start), null))
        ..add((url, TapGestureRecognizer()..onTap = () => _open(uri)));
      start = match.start + url.length;
    }
    return segments..add((text.substring(start), null));
  }

  void _open(Uri uri) => unawaited(
    launchExternalUrl(
      context,
      uri: uri,
      failureMessage: Translations.of(context).links.openError,
      launcher: widget.launcher,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final linkColor = Theme.of(context).colorScheme.primary;
    final linkStyle = TextStyle(
      color: linkColor,
      decoration: TextDecoration.underline,
      decorationColor: linkColor,
    );

    return Text.rich(
      TextSpan(
        children: [
          for (final (text, recognizer) in _segments)
            TextSpan(text: text, recognizer: recognizer, style: recognizer == null ? null : linkStyle),
        ],
      ),
    );
  }
}
