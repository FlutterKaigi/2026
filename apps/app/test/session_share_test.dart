import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/environment.dart';
import 'package:app/core/provider/shared_preferences.dart';
import 'package:app/feature/session/data/provider/session_detail_provider.dart';
import 'package:app/feature/session/ui/widget/session_details_content_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');
  late List<Uri> launched;

  setUp(() {
    launched = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      launcherChannel,
      (call) async {
        expect(call.method, 'launch');
        final arguments = call.arguments as Map;
        launched.add(Uri.parse(arguments['url'] as String));
        expect(arguments['useWebView'], isFalse);
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(launcherChannel, null);
  });

  for (final (flavor, expectedOrigin) in [
    (Flavor.production, 'https://app-2026.flutterkaigi.jp'),
    (Flavor.staging, 'https://stg-flutterkaigi-2026-conference-app.flutterkaigi.workers.dev'),
  ]) {
    testWidgets('shares the $flavor app session URL in the X intent', (tester) async {
      await _showSession(tester, flavor: flavor);

      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.pumpAndSettle();

      final intent = launched.single;
      expect(intent.origin, 'https://x.com');
      expect(intent.path, '/intent/post');
      expect(intent.queryParameters['hashtags'], 'FlutterKaigi2026');
      expect(intent.queryParameters['text'], 'Session title\nSpeaker A\n$expectedOrigin/sessions/session-a');
      expect(intent.queryParameters['text'], isNot(contains('https://2026.flutterkaigi.jp')));
    });
  }

  testWidgets('does not offer session sharing for local emulator data', (tester) async {
    await _showSession(tester, flavor: Flavor.develop);

    expect(find.byIcon(Icons.share_outlined), findsNothing);
    expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
    expect(launched, isEmpty);
  });

  testWidgets('preserves reserved characters in a session ID as one URL path segment', (tester) async {
    const sessionId = 'session ?#%&日本語';
    await _showSession(tester, flavor: Flavor.production, sessionId: sessionId);

    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();

    final sharedUrl = Uri.parse(launched.single.queryParameters['text']!.split('\n').last);
    expect(sharedUrl.origin, 'https://app-2026.flutterkaigi.jp');
    expect(sharedUrl.pathSegments, ['sessions', sessionId]);
    expect(sharedUrl.hasQuery, isFalse);
    expect(sharedUrl.hasFragment, isFalse);
  });
}

Future<void> _showSession(
  WidgetTester tester, {
  required Flavor flavor,
  String sessionId = 'session-a',
}) async {
  LocaleSettings.setLocaleSync(AppLocale.ja);
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final date = DateTime.utc(2026, 10, 29);
  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          environmentProvider.overrideWithValue(
            Environment(
              appIdSuffix: '',
              appName: 'FlutterKaigi 2026',
              flavor: flavor,
              firebaseProjectId: 'test-project',
              firestoreEmulatorHost: '127.0.0.1:8080',
              androidFirestoreEmulatorHost: '10.0.2.2:8080',
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: SessionDetailsContentWidget(
            data: SessionDetailData(
              session: Session(
                id: sessionId,
                title: const LocaleMap(ja: 'セッション名', en: 'Session title'),
                description: const LocaleMap(ja: '', en: ''),
                primaryLocale: 'en',
                startsAt: date,
                endsAt: date.add(const Duration(minutes: 45)),
                venueId: 'hall-a',
                createdAt: date,
                updatedAt: date,
              ),
              venue: null,
              speakers: [Speaker(id: 'speaker-a', name: 'Speaker A', createdAt: date, updatedAt: date)],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
