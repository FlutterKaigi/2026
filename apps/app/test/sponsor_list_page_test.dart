import 'package:app/core/designsystem/theme/app_theme.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/trademark_footer_widget.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_list_provider.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_repository.dart';
import 'package:app/feature/sponsor/ui/page/sponsor_details_page.dart';
import 'package:app/feature/sponsor/ui/page/sponsor_list_page.dart';
import 'package:app/feature/sponsor/ui/widget/sponsor_logo_card_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('builds the typed sponsor details route location', () {
    expect(
      const SponsorDetailsRoute(sponsorKey: 'cyberagent').location,
      '/sponsors/cyberagent',
    );
  });

  testWidgets('SponsorListPage renders sponsors from the repository', (tester) async {
    final repository = _FakeSponsorRepository([
      _sponsor(id: 'D2026-015', name: 'Flutter', slug: 'flutter'),
      _sponsor(
        id: 'D2026-020',
        name: 'Gold Sponsor',
        tier: SponsorTier.gold,
      ),
    ]);
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            sponsorRepositoryProvider.overrideWithValue(
              repository,
            ),
          ],
          child: MaterialApp(
            theme: lightTheme(),
            locale: const Locale('en'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const SponsorListPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('スポンサー'), findsWidgets);
    expect(find.text('Platinum'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(repository.excludeUnsupportedTiers, isTrue);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final appBarTitle = appBar.title! as Text;
    expect(appBar.toolbarHeight, 52);
    expect(appBarTitle.style?.fontSize, 16);
    expect(appBarTitle.style?.fontWeight, FontWeight.w700);

    await tester.scrollUntilVisible(find.text('Gold Sponsor'), 300);
    await tester.pumpAndSettle();

    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('Gold Sponsor'), findsOneWidget);
    final footer = find.byType(TrademarkFooterWidget);

    await tester.scrollUntilVisible(footer, 300);
    await tester.pumpAndSettle();

    expect(footer, findsOneWidget);
    expect(
      find.ancestor(of: footer, matching: find.byType(CustomScrollView)),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Flutter および関連するロゴは Google LLC の商標です。',
      ),
      findsOneWidget,
    );
  });

  testWidgets('SponsorListPage releases offscreen sponsor cards', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            sponsorListProvider.overrideWithValue(
              AsyncData([
                for (var index = 1; index <= 50; index++)
                  _sponsor(
                    id: 'D2026-$index',
                    name: 'Platinum Sponsor $index',
                  ),
              ]),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const SponsorListPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Platinum Sponsor 50', skipOffstage: false),
      findsNothing,
    );

    await tester.scrollUntilVisible(find.text('Platinum Sponsor 50'), 500);
    await tester.pumpAndSettle();

    expect(find.text('Platinum Sponsor 50'), findsOneWidget);
    expect(
      find.text('Platinum Sponsor 1', skipOffstage: false),
      findsNothing,
    );
  });

  for (final locale in AppLocale.values) {
    for (final width in [320.0, 390.0]) {
      testWidgets('amusement layout and details work at $width px in ${locale.languageCode}', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final previousLocale = LocaleSettings.currentLocale;
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        addTearDown(() => LocaleSettings.setLocaleSync(previousLocale));

        final router = GoRouter(
          initialLocation: '/sponsors',
          routes: [
            GoRoute(
              path: '/sponsors',
              builder: (context, state) => const SponsorListPage(),
              routes: [
                GoRoute(
                  path: ':sponsorKey',
                  builder: (context, state) => SponsorDetailsPage(
                    sponsorKey: state.pathParameters['sponsorKey']!,
                  ),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          TranslationProvider(
            child: ProviderScope(
              overrides: [
                sponsorListProvider.overrideWithValue(
                  AsyncData([
                    _sponsor(id: 'gold', name: 'Gold Company', tier: SponsorTier.gold),
                    _sponsor(id: 'tool', name: 'Tool Company', tier: SponsorTier.tool),
                    _sponsor(
                      id: 'entertainment',
                      name: 'Lumen Arcade',
                      tier: SponsorTier.entertainment,
                      slug: 'lumen-arcade',
                    ),
                  ]),
                ),
              ],
              child: MaterialApp.router(
                theme: lightTheme(),
                locale: locale.flutterLocale,
                routerConfig: router,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final goldCard = find.ancestor(of: find.text('Gold Company'), matching: find.byType(SponsorLogoCardWidget));
        expect(tester.getSize(goldCard), const Size(192, 192));

        await tester.scrollUntilVisible(find.text('Lumen Arcade'), 200);
        await tester.pumpAndSettle();

        final heading = tester.widget<Text>(find.text('Amusement Sponsor'));
        expect(heading.style?.fontSize, 28);
        expect(heading.style?.fontWeight, FontWeight.w500);
        final amusementCard = find.ancestor(
          of: find.text('Lumen Arcade'),
          matching: find.byType(SponsorLogoCardWidget),
        );
        expect(tester.getSize(amusementCard), const Size(192, 192));
        expect(tester.getCenter(amusementCard).dx, closeTo(width / 2, 0.1));
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Lumen Arcade'));
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, '/sponsors/lumen-arcade');
        expect(find.text(locale.translations.sponsors.tierBadge(tier: 'Amusement')), findsOneWidget);
        expect(find.textContaining('Entertainment'), findsNothing);
        expect(find.textContaining('Sponsor Sponsor'), findsNothing);
        expect(find.textContaining('Sponsor スポンサー'), findsNothing);
        expect(tester.takeException(), isNull);

        router.pop();
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, '/sponsors');
        expect(find.text('Amusement Sponsor'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('SponsorListPage centers an incomplete sponsor row', (tester) async {
    tester.view.physicalSize = const Size(800, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            sponsorListProvider.overrideWithValue(
              AsyncData([
                _sponsor(id: 'D2026-001', name: 'Platinum Sponsor 1'),
                _sponsor(id: 'D2026-002', name: 'Platinum Sponsor 2'),
                _sponsor(id: 'D2026-003', name: 'Platinum Sponsor 3'),
              ]),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const SponsorListPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Platinum Sponsor 3'), 300);
    await tester.pumpAndSettle();

    expect(
      tester.getCenter(find.text('Platinum Sponsor 3')).dx,
      closeTo(400, 0.1),
    );
  });

  testWidgets('opens sponsor details from a sponsor card', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sponsor = _sponsor(
      id: 'D2026-020',
      name: '株式会社サイバーエージェント',
      tier: SponsorTier.gold,
      slug: 'cyberagent',
      description: 'サイバーエージェントはFlutterを活用しています。',
      websiteUrl: 'https://www.cyberagent.co.jp/',
      xUrl: 'https://x.com/ca_developers',
      jobBoardUrl: 'https://hrmos.co/pages/cyberagent-group',
    );
    final router = GoRouter(
      initialLocation: '/sponsors',
      routes: [
        GoRoute(
          path: '/sponsors',
          builder: (context, state) => const SponsorListPage(),
          routes: [
            GoRoute(
              path: ':sponsorKey',
              builder: (context, state) => SponsorDetailsPage(
                sponsorKey: state.pathParameters['sponsorKey']!,
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            sponsorListProvider.overrideWithValue(
              AsyncData([sponsor]),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('株式会社サイバーエージェント'));
    await tester.pumpAndSettle();

    expect(find.text('Gold スポンサー'), findsOneWidget);
    expect(find.text('株式会社サイバーエージェント'), findsWidgets);
    expect(find.text('Job Boards'), findsOneWidget);
    expect(find.text('採用情報'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('https://www.cyberagent.co.jp/'), findsOneWidget);
    expect(find.text('https://x.com/ca_developers'), findsOneWidget);
    expect(find.text('サイバーエージェントはFlutterを活用しています。'), findsOneWidget);
    final footer = find.byType(TrademarkFooterWidget);
    expect(footer, findsOneWidget);
    expect(
      find.ancestor(of: footer, matching: find.byType(CustomScrollView)),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(footer, 300);
    await tester.pumpAndSettle();

    expect(
      find.text('RevCommは、株式会社 RevComm の登録商標または商標です。'),
      findsOneWidget,
    );
  });
}

final class _FakeSponsorRepository implements SponsorRepository {
  _FakeSponsorRepository(this.sponsors);

  final List<Sponsor> sponsors;
  bool? excludeUnsupportedTiers;

  @override
  Stream<List<Sponsor>> watchAll({bool excludeUnsupportedTiers = false}) {
    this.excludeUnsupportedTiers = excludeUnsupportedTiers;
    return Stream.value(sponsors);
  }

  @override
  Future<void> save(Sponsor sponsor) async {}

  @override
  Future<void> delete(String id) async {}
}

Sponsor _sponsor({
  required String id,
  required String name,
  SponsorTier tier = SponsorTier.platinum,
  String? slug,
  String description = '',
  String? websiteUrl,
  String? xUrl,
  String? jobBoardUrl,
}) {
  return Sponsor(
    id: id,
    name: LocaleMap(ja: name, en: name),
    description: LocaleMap(ja: description, en: description),
    tier: tier,
    slug: slug,
    websiteUrl: websiteUrl,
    xUrl: xUrl,
    jobBoardUrl: jobBoardUrl,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}
