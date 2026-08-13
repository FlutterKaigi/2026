import 'package:caption_protocol/caption_protocol.dart';
import 'package:flutter/material.dart';
import 'package:venue_screen/core/config/venue_screen_config.dart';
import 'package:venue_screen/feature/caption/provider/caption_overlay_controller.dart';
import 'package:venue_screen/feature/caption/ui/widget/caption_overlay.dart';

class VenueScreenApp extends StatefulWidget {
  const VenueScreenApp({required this.config, required this.controller, super.key});

  final VenueScreenConfig config;
  final CaptionOverlayController controller;

  @override
  State<VenueScreenApp> createState() => _VenueScreenAppState();
}

class _VenueScreenAppState extends State<VenueScreenApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.start();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterKaigi Venue Captions',
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Noto Sans JP',
      ),
      home: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) => widget.config.view == VenueScreenView.preview
            ? _PreviewPage(config: widget.config, controller: widget.controller)
            : ColoredBox(
                color: Colors.transparent,
                child: CaptionOverlay(caption: widget.controller.caption, config: widget.config),
              ),
      ),
    );
  }
}

class _PreviewPage extends StatelessWidget {
  const _PreviewPage({required this.config, required this.controller});

  final VenueScreenConfig config;
  final CaptionOverlayController controller;

  @override
  Widget build(BuildContext context) {
    final previewCaption =
        controller.caption ??
        CaptionEvent.caption(
          roomId: 'preview',
          sessionId: 'preview',
          sequence: 0,
          utteranceId: 'preview',
          utteranceSequence: 0,
          revision: 0,
          translatedText: 'Venue caption preview — 字幕のサイズと最後列からの見え方を確認します。',
          isFinal: true,
          sourceStartedAt: DateTime.utc(2026).subtract(const Duration(seconds: 1)),
          producedAt: DateTime.utc(2026),
          clearAt: DateTime.utc(2026).add(const Duration(minutes: 1)),
        );
    return Scaffold(
      backgroundColor: const Color(0xFF17151D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusHeader(config: config, controller: controller),
              const SizedBox(height: 20),
              Expanded(
                child: FittedBox(
                  child: SizedBox(
                    key: const ValueKey('preview-output-canvas'),
                    width: 1920,
                    height: 1080,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0FF),
                        border: Border.all(color: const Color(0xFF49454F)),
                      ),
                      child: Stack(
                        children: [
                          const Positioned(
                            left: 64,
                            top: 48,
                            child: Text(
                              'FlutterKaigi 2026',
                              style: TextStyle(color: Color(0xFF22005D), fontSize: 34, fontWeight: FontWeight.w700),
                            ),
                          ),
                          CaptionOverlay(
                            caption: previewCaption,
                            config: config,
                            showOverflowWarning: true,
                          ),
                        ],
                      ),
                    ),
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

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.config, required this.controller});

  final VenueScreenConfig config;
  final CaptionOverlayController controller;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (controller.status) {
      CaptionConnectionStatus.connected => const Color(0xFF55D187),
      CaptionConnectionStatus.connecting => const Color(0xFFFFC857),
      CaptionConnectionStatus.configurationError ||
      CaptionConnectionStatus.stale ||
      CaptionConnectionStatus.disconnected => const Color(0xFFFF6B6B),
    };
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Venue caption preview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        DecoratedBox(
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: statusColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              controller.status.name,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Text('${config.roomId} / ${config.sessionId}'),
        Text('${config.maxLines} line · ${config.fontSize.toStringAsFixed(0)} px'),
        const Text('preview canvas: 1920 × 1080 (provisional)'),
        Text('dropped: ${controller.droppedMessageCount}'),
        if (config.configurationError case final error?)
          Text(
            'Configuration error: $error',
            key: const ValueKey('configuration-error'),
            style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}
