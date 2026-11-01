import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/session/data/provider/session_detail_provider.dart';
import 'package:app/feature/session/ui/widget/session_details_content_widget.dart';
import 'package:app/feature/session/ui/widget/youtube_archive_player.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_youtube_archive_surface.dart';

void main() {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  const archiveUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=60';
  late List<Uri> launched;

  setUp(() {
    launched = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'launch');
      final arguments = call.arguments as Map;
      expect(arguments['useWebView'], isFalse);
      launched.add(Uri.parse(arguments['url'] as String));
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    LocaleSettings.setLocaleSync(AppLocale.ja);
  });

  for (final (locale, label) in [
    (AppLocale.ja, 'YouTubeで開く'),
    (AppLocale.en, 'Open in YouTube'),
  ]) {
    testWidgets('opens the YouTube archive from session details in $locale', (tester) async {
      await _showSession(tester, archiveUrl: '  $archiveUrl  ', locale: locale);

      expect(find.byType(YouTubeArchivePlayer), findsOneWidget);
      expect(
        find.byKey(ValueKey(Uri.parse('https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ?start=60'))),
        findsOneWidget,
      );
      expect(launched, isEmpty);
      expect(
        tester.getTopLeft(find.byType(YouTubeArchivePlayer)).dy,
        lessThan(tester.getTopLeft(find.byIcon(Icons.sell_outlined).first).dy),
      );
      expect(find.text(label), findsOneWidget);
      expect(find.text('Sessionize'), findsNothing);
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(launched, [Uri.parse(archiveUrl)]);
    });
  }

  testWidgets('hides missing and invalid archive URLs', (tester) async {
    for (final url in [null, '', '  ', 'javascript:alert(1)', 'https://youtube.com.example.com/watch?v=archive']) {
      await _showSession(tester, archiveUrl: url);
      expect(find.byType(YouTubeArchivePlayer), findsNothing, reason: '$url');
      expect(launched, isEmpty);
    }
  });
}

Future<void> _showSession(
  WidgetTester tester, {
  required String? archiveUrl,
  AppLocale locale = AppLocale.ja,
}) async {
  await tester.runAsync(() => LocaleSettings.setLocale(locale));
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final date = DateTime.utc(2026, 10, 29);
  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          youtubeArchiveSurfaceBuilderProvider.overrideWithValue(fakeYouTubeArchiveSurface),
        ],
        child: MaterialApp(
          locale: locale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: SessionDetailsContentWidget(
            data: SessionDetailData(
              session: Session(
                id: 'archive-session',
                title: const LocaleMap(ja: 'セッション名', en: 'Session title'),
                description: const LocaleMap(ja: '', en: ''),
                primaryLocale: 'en',
                startsAt: date,
                endsAt: date.add(const Duration(minutes: 45)),
                venueId: 'hall-a',
                archiveUrl: archiveUrl,
                createdAt: date,
                updatedAt: date,
              ),
              venue: null,
              speakers: const [],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
