import 'package:app/core/provider/environment.dart';
import 'package:app/feature/news/provider/news_provider.dart';
import 'package:app/main.dart';
import 'package:data/data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows news fetched from repository', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          environmentProvider.overrideWithValue(
            const Environment(
              appIdSuffix: '.dev',
              appName: '[DEV] FlutterKaigi 2026',
              flavor: Flavor.develop,
              firebaseProjectId: 'dev-flutterkaigi-2026',
              firestoreEmulatorHost: 'localhost:8080',
              androidFirestoreEmulatorHost: '10.0.2.2:8080',
            ),
          ),
          newsRepositoryProvider.overrideWithValue(
            _FakeNewsRepository([
              News(
                id: 'sample',
                title: 'FlutterKaigi 2026 スポンサー募集について',
                status: NewsStatus.published,
                startsAt: DateTime.parse('2026-05-01T09:00:00+09:00'),
                createdAt: DateTime.parse('2026-06-02T00:00:00+09:00'),
                updatedAt: DateTime.parse('2026-06-02T00:00:00+09:00'),
                url: Uri.parse(
                  'https://medium.com/flutterkaigi/flutterkaigi-2026-opportunities-guide-ja-0e8cdb0a4acb',
                ),
              ),
            ]),
          ),
        ],
        child: const NewsSampleApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('FlutterKaigi 2026 スポンサー募集について'), findsOneWidget);
    expect(find.textContaining('medium.com/flutterkaigi'), findsOneWidget);
  });
}

final class _FakeNewsRepository implements NewsRepository {
  const _FakeNewsRepository(this._news);

  final List<News> _news;

  @override
  Future<List<News>> fetchNews() async => _news;
}
