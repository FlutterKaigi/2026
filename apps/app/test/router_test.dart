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
  });
}
