import 'package:app/core/i18n/strings.g.dart';
import 'package:app/feature/news/data/provider/news_list_repository.dart';
import 'package:app/feature/news/ui/page/news_list_page.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('NewsListPage renders news from the repository', (tester) async {
    final news = News(
      id: 'sample',
      title: const LocaleMap(ja: 'お知らせサンプル', en: 'Sample news'),
      url: const LocaleMap(ja: '', en: ''),
      publishedAt: DateTime.utc(2026, 5),
      createdAt: DateTime.utc(2026, 5),
      updatedAt: DateTime.utc(2026, 5),
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            newsListRepositoryProvider.overrideWithValue(
              _FakeNewsRepository([news]),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const NewsListPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('お知らせサンプル'), findsOneWidget);
  });
}

final class _FakeNewsRepository implements NewsRepository {
  const _FakeNewsRepository(this._news);

  final List<News> _news;

  @override
  Future<List<News>> fetchNews() async => _news;

  @override
  Stream<List<News>> watchAll() => Stream.value(_news);

  @override
  Future<void> save(News news) async {}

  @override
  Future<void> delete(String id) async {}
}
