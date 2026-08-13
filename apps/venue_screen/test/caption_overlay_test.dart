import 'package:caption_protocol/caption_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:venue_screen/core/config/venue_screen_config.dart';
import 'package:venue_screen/feature/caption/data/caption_socket.dart';
import 'package:venue_screen/feature/caption/provider/caption_overlay_controller.dart';
import 'package:venue_screen/feature/caption/ui/page/venue_screen_app.dart';
import 'package:venue_screen/feature/caption/ui/widget/caption_overlay.dart';

void main() {
  testWidgets('renders a one-line translated caption at 1920x1080 without overflow', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.utc(2026, 11, 7, 1);

    await tester.pumpWidget(
      MaterialApp(
        color: Colors.transparent,
        home: CaptionOverlay(
          config: _config,
          caption: CaptionEvent.caption(
            roomId: 'main',
            sessionId: 'opening',
            sequence: 1,
            utteranceId: 'test-utterance',
            utteranceSequence: 0,
            revision: 0,
            translatedText: 'This caption remains readable from the back of the venue.',
            isFinal: true,
            sourceStartedAt: now.subtract(const Duration(seconds: 1)),
            producedAt: now,
            clearAt: now.add(const Duration(seconds: 8)),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('This caption remains readable from the back of the venue.'));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders nothing audience-visible while no caption is available', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        color: Colors.transparent,
        home: CaptionOverlay(caption: null, config: _config),
      ),
    );

    expect(find.byType(Text), findsNothing);
    expect(find.textContaining('disconnect'), findsNothing);
    expect(find.textContaining('error'), findsNothing);
  });

  for (final testCase in <({String language, int maxLines, String text})>[
    (
      language: 'English',
      maxLines: 1,
      text:
          'This deliberately long English caption cannot fit into the configured audience-safe line and must be noticed during rehearsal before it reaches the projector output.',
    ),
    (
      language: 'English',
      maxLines: 2,
      text:
          'This deliberately long English caption cannot fit into two configured lines even on a full HD canvas, so the preview must explicitly flag truncation instead of silently accepting unreadable production output. The producer should split this translation into shorter display units before the event begins.',
    ),
    (
      language: 'Japanese',
      maxLines: 1,
      text: 'この日本語字幕は一行に収まらない長さであり、会場リハーサル中に省略されることを必ず検知しなければなりません。',
    ),
    (
      language: 'Japanese',
      maxLines: 2,
      text:
          'この日本語字幕は二行にも収まらない長さであり、実際のプロジェクターへ出力する前にプレビュー画面で省略を明確に警告しなければなりません。翻訳生成側では文章をより短い表示単位に分割し、最後列から読める文字サイズを維持する必要があります。',
    ),
  ]) {
    testWidgets('warns when ${testCase.language} exceeds ${testCase.maxLines} preview line(s)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: CaptionOverlay(
            config: _configWithLines(testCase.maxLines),
            caption: _caption(testCase.text),
            showOverflowWarning: true,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('caption-overflow-warning')), findsOneWidget);
    });
  }

  testWidgets('keeps overflow diagnostics off the audience surface', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: CaptionOverlay(
          config: _config,
          caption: _caption(
            'This deliberately long audience caption will be ellipsized, but operational diagnostics must never be composited onto the venue screen.',
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('caption-overflow-warning')), findsNothing);
    expect(find.textContaining('PREVIEW:'), findsNothing);
  });

  testWidgets('does not warn when preview text fits its configured line', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: CaptionOverlay(
          config: _config,
          caption: _caption('Welcome to FlutterKaigi.'),
          showOverflowWarning: true,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('caption-overflow-warning')), findsNothing);
  });

  testWidgets('diagnoses invalid stream configuration only in preview', (tester) async {
    final config = _invalidConfig(VenueScreenView.preview);
    await tester.pumpWidget(
      VenueScreenApp(
        config: config,
        controller: CaptionOverlayController(config: config, connector: const _NeverConnector()),
      ),
    );

    expect(find.byKey(const ValueKey('configuration-error')), findsOneWidget);
    expect(find.textContaining('room must be a safe identifier'), findsOneWidget);
  });

  testWidgets('measures preview captions on a fixed 1920x1080 output canvas', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final config = _invalidConfig(VenueScreenView.preview);

    await tester.pumpWidget(
      VenueScreenApp(
        config: config,
        controller: CaptionOverlayController(config: config, connector: const _NeverConnector()),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('preview-output-canvas'))), const Size(1920, 1080));
  });

  testWidgets('keeps the audience surface blank for invalid stream configuration', (tester) async {
    final config = _invalidConfig(VenueScreenView.overlay);
    await tester.pumpWidget(
      VenueScreenApp(
        config: config,
        controller: CaptionOverlayController(config: config, connector: const _NeverConnector()),
      ),
    );

    expect(find.byType(Text), findsNothing);
    expect(find.byKey(const ValueKey('configuration-error')), findsNothing);
  });
}

CaptionEvent _caption(String text) {
  final now = DateTime.utc(2026, 11, 7, 1);
  return CaptionEvent.caption(
    roomId: 'main',
    sessionId: 'opening',
    sequence: 1,
    utteranceId: 'test-utterance',
    utteranceSequence: 0,
    revision: 0,
    translatedText: text,
    isFinal: true,
    sourceStartedAt: now.subtract(const Duration(seconds: 1)),
    producedAt: now,
    clearAt: now.add(const Duration(seconds: 8)),
  );
}

VenueScreenConfig _configWithLines(int maxLines) => VenueScreenConfig(
  webSocketUri: _config.webSocketUri,
  roomId: _config.roomId,
  sessionId: _config.sessionId,
  view: _config.view,
  maxLines: maxLines,
  fontSize: _config.fontSize,
  lineHeight: _config.lineHeight,
  horizontalMargin: _config.horizontalMargin,
  bottomMargin: _config.bottomMargin,
  backgroundOpacity: _config.backgroundOpacity,
  staleAfter: _config.staleAfter,
);

VenueScreenConfig _invalidConfig(VenueScreenView view) => VenueScreenConfig(
  webSocketUri: _config.webSocketUri,
  roomId: '../../invalid',
  sessionId: _config.sessionId,
  view: view,
  maxLines: _config.maxLines,
  fontSize: _config.fontSize,
  lineHeight: _config.lineHeight,
  horizontalMargin: _config.horizontalMargin,
  bottomMargin: _config.bottomMargin,
  backgroundOpacity: _config.backgroundOpacity,
  staleAfter: _config.staleAfter,
  configurationError: 'room must be a safe identifier',
);

final class _NeverConnector implements CaptionSocketConnector {
  const _NeverConnector();

  @override
  CaptionSocket connect(Uri uri) => throw StateError('invalid configuration must not connect');
}

final _config = VenueScreenConfig(
  webSocketUri: Uri.parse('ws://127.0.0.1:8088/ws?room=main&session=opening'),
  roomId: 'main',
  sessionId: 'opening',
  view: VenueScreenView.overlay,
  maxLines: 1,
  fontSize: 64,
  lineHeight: 1.25,
  horizontalMargin: 72,
  bottomMargin: 54,
  backgroundOpacity: 0.88,
  staleAfter: const Duration(seconds: 12),
);
