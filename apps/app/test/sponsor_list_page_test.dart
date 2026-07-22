import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/sponsor/data/provider/sponsor_repository.dart';
import 'package:app/feature/sponsor/ui/page/sponsor_list_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
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
}) {
  return Sponsor(
    id: id,
    name: LocaleMap(ja: name, en: name),
    description: const LocaleMap(ja: '', en: ''),
    tier: tier,
    slug: slug,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}
