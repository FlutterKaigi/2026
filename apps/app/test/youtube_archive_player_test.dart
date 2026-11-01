import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/session/ui/widget/youtube_archive_playback_controller.dart';
import 'package:app/feature/session/ui/widget/youtube_archive_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));

  testWidgets('shows an inline player at least 200px high without launching YouTube', (tester) async {
    final tracker = _SurfaceTracker();
    await _pumpPlayer(tester, tracker);

    expect(tracker.embeds.single.toString(), 'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ?start=60');
    expect(tester.getSize(find.byType(_TrackedSurface)).height, greaterThanOrEqualTo(200));
    expect(find.text('YouTubeで開く'), findsOneWidget);
  });

  testWidgets('destroys the player when covered and recreates it when returning', (tester) async {
    final tracker = _SurfaceTracker();
    await _pumpPlayer(tester, tracker);
    final context = tester.element(find.byType(YouTubeArchivePlayer));
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(content: Text('Covered')),
      ),
    );
    await tester.pumpAndSettle();

    expect(tracker.disposed, 1);
    expect(find.byType(_TrackedSurface), findsNothing);
    Navigator.of(context).pop();
    await tester.pumpAndSettle();

    expect(tracker.created, 2);
    expect(find.byType(_TrackedSurface), findsOneWidget);
  });

  testWidgets('keeps playback mounted when focusing the iframe makes the app inactive', (tester) async {
    final tracker = _SurfaceTracker();
    await _pumpPlayer(tester, tracker);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();

    expect(tracker.stopped, 0);
    expect(tracker.disposed, 0);
    expect(find.byType(_TrackedSurface), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(tracker.created, 1);
  });

  testWidgets('initializes the player while the visible window is inactive', (tester) async {
    final tracker = _SurfaceTracker();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await _pumpPlayer(tester, tracker);

    expect(tracker.created, 1);
    expect(tracker.stopped, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  });

  for (final state in [AppLifecycleState.hidden, AppLifecycleState.detached]) {
    testWidgets('stops playback immediately when the app becomes $state', (tester) async {
      final tracker = _SurfaceTracker();
      await _pumpPlayer(tester, tracker);
      tester.binding.handleAppLifecycleStateChanged(state);
      expect(tracker.stopped, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(tracker.created, 2);
    });
  }

  testWidgets('destroys the player in the background and on leaving the page', (tester) async {
    final tracker = _SurfaceTracker();
    await _pumpPlayer(tester, tracker);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(tracker.stopped, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(tracker.created, 2);

    await tester.pumpWidget(const SizedBox());
    expect(tracker.disposed, 2);
  });

  testWidgets('replaces and stops playback when the recording URL changes', (tester) async {
    final tracker = _SurfaceTracker();
    await _pumpPlayer(tester, tracker);
    await _pumpPlayer(tester, tracker, archiveUrl: 'https://youtu.be/M7lc1UVf-VE');

    expect(tracker.disposed, 1);
    expect(tracker.created, 2);
    expect(tracker.embeds.last.path, '/embed/M7lc1UVf-VE');
  });

  testWidgets('offers YouTube fallback when embedded playback fails', (tester) async {
    final tracker = _SurfaceTracker();
    await _pumpPlayer(tester, tracker);
    tracker.onError!();
    await tester.pumpAndSettle();

    expect(tracker.disposed, 1);
    expect(find.byType(_TrackedSurface), findsNothing);
    expect(find.text('アーカイブを再生できません。YouTubeで開いてください。'), findsOneWidget);
    expect(find.text('YouTubeで開く'), findsOneWidget);
  });

  testWidgets('keeps legacy non-video YouTube URLs available as fallback only', (tester) async {
    final tracker = _SurfaceTracker();
    await _pumpPlayer(tester, tracker, archiveUrl: 'https://www.youtube.com/@FlutterKaigi');

    expect(tracker.created, 0);
    expect(find.text('YouTubeで開く'), findsOneWidget);
    expect(find.text('アーカイブを再生できません。YouTubeで開いてください。'), findsOneWidget);
  });
}

Future<void> _pumpPlayer(
  WidgetTester tester,
  _SurfaceTracker tracker, {
  String archiveUrl = 'https://youtu.be/dQw4w9WgXcQ?t=60',
}) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [youtubeArchiveSurfaceBuilderProvider.overrideWithValue(tracker.build)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: YouTubeArchivePlayer(archiveUri: Uri.parse(archiveUrl), title: 'Session title'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _SurfaceTracker {
  int created = 0;
  int disposed = 0;
  int stopped = 0;
  final embeds = <Uri>[];
  VoidCallback? onError;

  Widget build({
    required Uri embedUri,
    required String title,
    required VoidCallback onError,
    required YouTubeArchivePlaybackController playbackController,
  }) {
    this.onError = onError;
    return _TrackedSurface(
      playbackController: playbackController,
      onStop: () => stopped++,
      onCreated: () {
        created++;
        embeds.add(embedUri);
      },
      onDisposed: () => disposed++,
    );
  }
}

class _TrackedSurface extends StatefulWidget {
  const _TrackedSurface({
    required this.onCreated,
    required this.onDisposed,
    required this.playbackController,
    required this.onStop,
  });

  final VoidCallback onCreated;
  final VoidCallback onDisposed;
  final VoidCallback onStop;
  final YouTubeArchivePlaybackController playbackController;

  @override
  State<_TrackedSurface> createState() => _TrackedSurfaceState();
}

class _TrackedSurfaceState extends State<_TrackedSurface> {
  @override
  void initState() {
    super.initState();
    widget.onCreated();
    widget.playbackController.addListener(widget.onStop);
  }

  @override
  void dispose() {
    widget.playbackController.removeListener(widget.onStop);
    widget.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.black);
}
