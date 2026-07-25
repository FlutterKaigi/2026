import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/trademark_footer_widget.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_repository.dart';
import 'package:app/feature/sponsor/ui/page/sponsor_details_page.dart';
import 'package:app/feature/sponsor/ui/page/sponsor_list_page.dart';
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
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            sponsorRepositoryProvider.overrideWithValue(
              _FakeSponsorRepository([
                _sponsor(id: 'D2026-015', name: 'Flutter', slug: 'flutter'),
                _sponsor(
                  id: 'D2026-020',
                  name: 'Gold Sponsor',
                  tier: SponsorTier.gold,
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

    expect(find.text('スポンサー'), findsWidgets);
    expect(find.text('Platinum'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);

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
            sponsorRepositoryProvider.overrideWithValue(
              _FakeSponsorRepository([
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

  testWidgets('SponsorListPage centers an incomplete sponsor row', (tester) async {
    tester.view.physicalSize = const Size(800, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            sponsorRepositoryProvider.overrideWithValue(
              _FakeSponsorRepository([
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
            sponsorRepositoryProvider.overrideWithValue(
              _FakeSponsorRepository([sponsor]),
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
  const _FakeSponsorRepository(this._sponsors);

  final List<Sponsor> _sponsors;

  @override
  Stream<List<Sponsor>> watchAll() => Stream.value(_sponsors);

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
