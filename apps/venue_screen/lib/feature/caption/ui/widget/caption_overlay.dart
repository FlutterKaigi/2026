import 'package:caption_protocol/caption_protocol.dart';
import 'package:flutter/material.dart';
import 'package:venue_screen/core/config/venue_screen_config.dart';

class CaptionOverlay extends StatelessWidget {
  const CaptionOverlay({
    required this.caption,
    required this.config,
    this.showOverflowWarning = false,
    super.key,
  });

  final CaptionEvent? caption;
  final VenueScreenConfig config;
  final bool showOverflowWarning;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                config.horizontalMargin,
                0,
                config.horizontalMargin,
                config.bottomMargin,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                reverseDuration: const Duration(milliseconds: 80),
                child: caption == null
                    ? const SizedBox.shrink(key: ValueKey('caption-empty'))
                    : _CaptionCard(
                        key: ValueKey(caption!.sequence),
                        caption: caption!,
                        config: config,
                        showOverflowWarning: showOverflowWarning,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptionCard extends StatelessWidget {
  const _CaptionCard({
    required this.caption,
    required this.config,
    required this.showOverflowWarning,
    super.key,
  });

  final CaptionEvent caption;
  final VenueScreenConfig config;
  final bool showOverflowWarning;

  @override
  Widget build(BuildContext context) {
    final captionStyle = TextStyle(
      color: Colors.white,
      fontFamily: 'Noto Sans JP',
      fontSize: config.fontSize,
      fontWeight: FontWeight.w700,
      height: config.lineHeight,
      letterSpacing: 0.2,
      shadows: const [Shadow(blurRadius: 3, offset: Offset(0, 2))],
    );
    return Semantics(
      liveRegion: true,
      label: caption.translatedText,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 1776),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF080614).withValues(alpha: config.backgroundOpacity),
          border: const Border(top: BorderSide(color: Color(0xFFB180F5), width: 6)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x99000000), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 32,
            vertical: config.maxLines == 1 ? 18 : 16,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final painter = TextPainter(
                text: TextSpan(text: caption.translatedText, style: captionStyle),
                maxLines: config.maxLines,
                textDirection: Directionality.of(context),
                textScaler: TextScaler.noScaling,
              )..layout(maxWidth: constraints.maxWidth);
              final willOverflow = painter.didExceedMaxLines;
              painter.dispose();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showOverflowWarning && willOverflow) ...[
                    const _OverflowWarning(),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    caption.translatedText!,
                    maxLines: config.maxLines,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: captionStyle,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OverflowWarning extends StatelessWidget {
  const _OverflowWarning();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Preview warning: caption text will be truncated',
      child: DecoratedBox(
        key: const ValueKey('caption-overflow-warning'),
        decoration: BoxDecoration(
          color: const Color(0xFFFFC857).withValues(alpha: 0.2),
          border: Border.all(color: const Color(0xFFFFC857)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            'PREVIEW: CAPTION WILL BE TRUNCATED',
            style: TextStyle(
              color: Color(0xFFFFE3A3),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
