import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production generates and accepts links on its canonical app domain', () {
    const configuration = AppLinkConfiguration.production();
    expect(configuration.origin, 'https://2026-app.flutterkaigi.jp');
    expect(configuration.allowedOrigins, {
      'https://2026-app.flutterkaigi.jp',
    });
    expect(configuration.allowedOrigins, isNot(contains(officialWebsiteOrigin)));
    expect(configuration.allowedOrigins, isNot(contains(stagingAppOrigin)));
    expect(() => configuration.allowedOrigins.add('https://example.com'), throwsUnsupportedError);
  });

  test('staging only accepts its fixed deployed app domain', () {
    const configuration = AppLinkConfiguration.staging();
    expect(configuration.origin, stagingAppOrigin);
    expect(configuration.allowedOrigins, {stagingAppOrigin});
  });

  test('development produces bare payloads with no deployed app domain', () {
    const configuration = AppLinkConfiguration.develop();
    expect(configuration.origin, isNull);
    expect(configuration.allowedOrigins, isEmpty);
  });
}
