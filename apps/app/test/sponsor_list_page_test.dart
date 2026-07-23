import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
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
    expect(find.text('Gold'), findsOneWidget);
    expect(find.byTooltip('Flutter'), findsOneWidget);
    expect(find.byTooltip('Gold Sponsor'), findsOneWidget);
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
                initialSponsor: state.extra as Sponsor?,
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

    await tester.tap(find.byTooltip('株式会社サイバーエージェント'));
    await tester.pumpAndSettle();

    expect(find.text('Gold スポンサー'), findsOneWidget);
    expect(find.text('株式会社サイバーエージェント'), findsWidgets);
    expect(find.text('Job Boards'), findsOneWidget);
    expect(find.text('採用情報'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('https://www.cyberagent.co.jp/'), findsOneWidget);
    expect(find.text('https://x.com/ca_developers'), findsOneWidget);
    expect(find.text('サイバーエージェントはFlutterを活用しています。'), findsOneWidget);
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
