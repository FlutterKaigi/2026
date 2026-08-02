import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/feature/contributor/data/contributor_provider.dart';
import 'package:app/feature/contributor/data/contributor_repository.dart';
import 'package:app/feature/contributor/data/model/contributor.dart';
import 'package:app/feature/contributor/ui/page/contributor_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('builds the typed contributors route location', () {
    expect(const ContributorsRoute().location, '/contributors');
  });

  testWidgets('renders contributors returned by the repository', (
    tester,
  ) async {
    await _pumpContributorListPage(
      tester,
      repository: _FakeContributorRepository([
        _contributor(login: 'alice', contributions: 115),
        _contributor(login: 'bob', contributions: 1),
      ]),
    );

    expect(find.text('コントリビューター'), findsOneWidget);
    expect(
      find.text('FlutterKaigi 2026 の開発にコントリビュートしてくださった皆様'),
      findsOneWidget,
    );
    expect(find.text('alice'), findsOneWidget);
    expect(find.text('115 contributions'), findsOneWidget);
    expect(find.text('bob'), findsOneWidget);
    expect(find.text('1 contributions'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsNWidgets(2));
  });

  testWidgets('shows the empty message when there are no contributors', (
    tester,
  ) async {
    await _pumpContributorListPage(
      tester,
      repository: const _FakeContributorRepository([]),
    );

    expect(find.text('コントリビューターが見つかりませんでした'), findsOneWidget);
  });

  testWidgets('shows the error view when fetching contributors fails', (
    tester,
  ) async {
    await _pumpContributorListPage(
      tester,
      repository: const _FakeContributorRepository.failing(),
    );

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
  });
}

Contributor _contributor({
  required String login,
  required int contributions,
}) => Contributor(
  login: login,
  // Empty on purpose: keeps widget tests off the network by rendering the
  // fallback icon instead of the GitHub avatar.
  avatarUrl: '',
  htmlUrl: 'https://github.com/$login',
  contributions: contributions,
  type: 'User',
);

class _FakeContributorRepository extends ContributorRepository {
  const _FakeContributorRepository(this._contributors) : _fails = false;

  const _FakeContributorRepository.failing() : _contributors = const [], _fails = true;

  final List<Contributor> _contributors;
  final bool _fails;

  @override
  Future<List<Contributor>> fetchContributors() async {
    if (_fails) {
      throw Exception('network error');
    }
    return _contributors;
  }
}

Future<void> _pumpContributorListPage(
  WidgetTester tester, {
  required ContributorRepository repository,
}) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          contributorRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const ContributorListPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
