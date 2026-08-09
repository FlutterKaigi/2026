import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/sponsor/ui/widget/sponsor_logo_card_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('individual sponsor card opens a GitHub URL', (tester) async {
    Uri? openedUri;
    final sponsor = _sponsor(websiteUrl: 'https://github.com/flutterkaigi');

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: SponsorLogoCardWidget(
              sponsor: sponsor,
              side: 96,
              externalUrlLauncher: (uri) async {
                openedUri = uri;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final name = find.text('個人スポンサー').last;
    expect(name, findsOneWidget);
    await tester.tap(name);
    await tester.pumpAndSettle();

    expect(openedUri, Uri.parse('https://github.com/flutterkaigi'));
  });

  testWidgets('individual sponsor card uses an X marker for an X URL', (tester) async {
    Uri? openedUri;
    final sponsor = _sponsor(xUrl: 'https://x.com/flutterkaigi');

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: SponsorLogoCardWidget(
              sponsor: sponsor,
              side: 96,
              externalUrlLauncher: (uri) async {
                openedUri = uri;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final name = find.text('個人スポンサー').last;
    expect(name, findsOneWidget);
    expect(find.text('X'), findsOneWidget);
    await tester.tap(name);
    await tester.pumpAndSettle();

    expect(openedUri, Uri.parse('https://x.com/flutterkaigi'));
  });

  testWidgets('individual sponsor card uses a generic marker for other URLs', (tester) async {
    Uri? openedUri;
    final sponsor = _sponsor(websiteUrl: 'https://example.com/profile');

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: SponsorLogoCardWidget(
              sponsor: sponsor,
              side: 96,
              externalUrlLauncher: (uri) async {
                openedUri = uri;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final name = find.text('個人スポンサー').last;
    expect(name, findsOneWidget);
    expect(find.byIcon(Icons.public), findsOneWidget);
    await tester.tap(name);
    await tester.pumpAndSettle();

    expect(openedUri, Uri.parse('https://example.com/profile'));
  });

  testWidgets('individual sponsor card without a URL is inert', (tester) async {
    Uri? openedUri;
    final sponsor = _sponsor();

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: SponsorLogoCardWidget(
              sponsor: sponsor,
              side: 96,
              externalUrlLauncher: (uri) async {
                openedUri = uri;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final name = find.text('個人スポンサー').last;
    expect(name, findsOneWidget);
    expect(find.byIcon(Icons.public), findsNothing);
    expect(find.text('X'), findsNothing);
    await tester.tap(name);
    await tester.pumpAndSettle();

    expect(openedUri, isNull);
  });
}

Sponsor _sponsor({String? websiteUrl, String? xUrl}) {
  return Sponsor(
    id: 'individual-sponsor',
    name: const LocaleMap(ja: '個人スポンサー', en: 'Individual Sponsor'),
    description: const LocaleMap(ja: '', en: ''),
    tier: SponsorTier.individual,
    websiteUrl: websiteUrl,
    xUrl: xUrl,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}
