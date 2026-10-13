import 'package:app/core/provider/app_link_configuration.dart';
import 'package:app/core/provider/environment.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  for (final (flavor, expectedOrigin, expectedOrigins) in [
    (Flavor.production, productionAppOrigin, {productionAppOrigin, legacyProductionAppOrigin}),
    (Flavor.staging, stagingAppOrigin, {stagingAppOrigin}),
    (Flavor.develop, null, <String>{}),
  ]) {
    test('${flavor.shortName} uses only its backend app domains', () {
      final container = ProviderContainer(
        overrides: [
          environmentProvider.overrideWithValue(Environment.fromEnvironment().copyWith(flavor: flavor)),
        ],
      );
      addTearDown(container.dispose);
      final configuration = container.read(appLinkConfigurationProvider);
      expect(configuration.origin, expectedOrigin);
      expect(configuration.allowedOrigins, expectedOrigins);
      expect(configuration.allowedOrigins, isNot(contains(officialWebsiteOrigin)));
    });
  }
}
