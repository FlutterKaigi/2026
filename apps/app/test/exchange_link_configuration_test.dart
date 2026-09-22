import 'package:app/core/provider/environment.dart';
import 'package:app/feature/exchange/data/exchange_token.dart';
import 'package:app/feature/exchange/data/provider/exchange_link_configuration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  const tokenValue = 'v1.other-uid.9999999999.deadbeef';
  final token = ExchangeToken(value: tokenValue, expiresAt: DateTime.utc(2100));

  ExchangeLinkConfiguration configuration(Flavor flavor) {
    final container = ProviderContainer(
      overrides: [
        environmentProvider.overrideWithValue(Environment.fromEnvironment().copyWith(flavor: flavor)),
      ],
    );
    addTearDown(container.dispose);
    return container.read(exchangeLinkConfigurationProvider);
  }

  test('production issues the app URL and accepts both production URL generations', () {
    final config = configuration(Flavor.production);
    expect(token.qrPayload(origin: config.origin), 'https://2026-app.flutterkaigi.jp/x/$tokenValue');
    for (final origin in [productionExchangeOrigin, legacyExchangeOrigin]) {
      expect(parseScannedExchangeToken('$origin/x/$tokenValue', allowedOrigins: config.allowedOrigins), isNotNull);
    }
    expect(
      parseScannedExchangeToken('$stagingExchangeOrigin/x/$tokenValue', allowedOrigins: config.allowedOrigins),
      isNull,
    );
  });

  test('staging issues its fixed alias and rejects production URLs', () {
    final config = configuration(Flavor.staging);
    expect(
      token.qrPayload(origin: config.origin),
      'https://stg-flutterkaigi-2026-conference-app.flutterkaigi.workers.dev/x/$tokenValue',
    );
    expect(
      parseScannedExchangeToken('$stagingExchangeOrigin/x/$tokenValue', allowedOrigins: config.allowedOrigins),
      isNotNull,
    );
    for (final origin in [productionExchangeOrigin, legacyExchangeOrigin]) {
      expect(parseScannedExchangeToken('$origin/x/$tokenValue', allowedOrigins: config.allowedOrigins), isNull);
    }
  });

  test('emulator builds use bare QR tokens and never link into a deployed backend', () {
    final config = configuration(Flavor.develop);
    expect(token.qrPayload(origin: config.origin), tokenValue);
    expect(parseScannedExchangeToken(tokenValue, allowedOrigins: config.allowedOrigins), isNotNull);
    for (final origin in [productionExchangeOrigin, legacyExchangeOrigin, stagingExchangeOrigin]) {
      expect(parseScannedExchangeToken('$origin/x/$tokenValue', allowedOrigins: config.allowedOrigins), isNull);
    }
  });
}
