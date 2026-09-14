import 'package:app/core/router/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  test('application router reflects pushed deep links in the web URL', () {
    GoRouter.optionURLReflectsImperativeAPIs = false;
    final container = ProviderContainer();
    addTearDown(() {
      container.dispose();
      GoRouter.optionURLReflectsImperativeAPIs = false;
    });

    final router = container.read(routerProvider);
    addTearDown(router.dispose);

    expect(GoRouter.optionURLReflectsImperativeAPIs, isTrue);
    expect(router.routeInformationProvider.value.uri.path, '/info');
    expect(const LicenseRoute().location, '/licenses');
    expect(
      const LicenseDetailRoute(packageName: 'foo bar').location,
      '/licenses/foo%20bar',
    );
    expect(const AccountRoute().location, '/account');
    expect(const EmailSignInRoute().location, '/account/email');
    expect(const ExchangeHomeRoute().location, '/account/exchange');
    expect(const ExchangeScanRoute().location, '/account/exchange/scan');
    expect(const ExchangeListRoute().location, '/account/exchange/list');
  });
}
