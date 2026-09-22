import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/core/ui/widget/app_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';

/// Displays one session speaker as an avatar and name pair.
class SessionSpeakerLabelWidget extends StatelessWidget {
  const SessionSpeakerLabelWidget({
    required this.speaker,
    this.avatarSize = 24,
    this.gap = 6,
    this.maxNameLines,
    this.textStyle,
    this.launcher,
    super.key,
  });

  final Speaker speaker;
  final double avatarSize;
  final double gap;
  final int? maxNameLines;
  final TextStyle? textStyle;
  final ExternalUrlLauncher? launcher;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SessionSpeakerAvatarWidget(
          speaker: speaker,
          size: avatarSize,
          launcher: launcher,
        ),
        SizedBox(width: gap),
        Flexible(
          child: Text(
            key: ValueKey('session-speaker-name-${speaker.id}'),
            speaker.name,
            maxLines: maxNameLines,
            overflow: maxNameLines == null ? null : TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ],
    );
  }
}

/// Displays a speaker avatar as a true circle and links it to X when possible.
class SessionSpeakerAvatarWidget extends StatelessWidget {
  const SessionSpeakerAvatarWidget({
    required this.speaker,
    this.size = 24,
    this.launcher,
    super.key,
  });

  final Speaker speaker;
  final double size;
  final ExternalUrlLauncher? launcher;

  @override
  Widget build(BuildContext context) {
    final xProfileUri = speakerXProfileUri(speaker.xId);
    final avatar = SizedBox.square(
      key: ValueKey('session-speaker-avatar-${speaker.id}'),
      dimension: size,
      child: AppNetworkAvatar(
        radius: size / 2,
        imageUrl: speaker.avatarUrl,
        // Speaker photos are repeated throughout the room table. Fetch bytes
        // first so CORS-enabled images stay in Flutter's canvas instead of
        // creating one HTML platform view per avatar. Keep the HTML fallback
        // for any future image origin that does not support CORS.
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        fallback: Icon(
          Icons.person_outline,
          size: size * 0.6,
        ),
      ),
    );

    if (xProfileUri == null) {
      return avatar;
    }

    return Tooltip(
      message: 'X: @${_normalizeXId(speaker.xId)!}',
      child: Semantics(
        link: true,
        label: '${speaker.name} X',
        child: InkResponse(
          key: ValueKey('session-speaker-x-link-${speaker.id}'),
          onTap: () => unawaited(
            launchExternalUrl(
              context,
              uri: xProfileUri,
              failureMessage: Translations.of(context).links.openError,
              launcher: launcher,
            ),
          ),
          containedInkWell: true,
          customBorder: const CircleBorder(),
          child: avatar,
        ),
      ),
    );
  }
}

/// Compact capsule used by session cards to enumerate every speaker.
class SessionSpeakerChipWidget extends StatelessWidget {
  const SessionSpeakerChipWidget({
    required this.speaker,
    this.launcher,
    super.key,
  });

  final Speaker speaker;
  final ExternalUrlLauncher? launcher;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
        child: SessionSpeakerLabelWidget(
          speaker: speaker,
          textStyle: theme.textTheme.labelLarge,
          launcher: launcher,
        ),
      ),
    );
  }
}

/// Builds the public X profile URI represented by a speaker's `xId`.
Uri? speakerXProfileUri(String? xId) {
  final normalizedXId = _normalizeXId(xId);
  if (normalizedXId == null) {
    return null;
  }
  return Uri.https('x.com', '/$normalizedXId');
}

String? _normalizeXId(String? xId) {
  final trimmed = xId?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  final normalized = trimmed.replaceFirst(RegExp('^@+'), '');
  return normalized.isEmpty ? null : normalized;
}
