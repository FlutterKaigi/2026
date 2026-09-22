import 'package:app/core/router/legacy_hash_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migrateLegacyHashRoute', () {
    test('keeps old bookmarked screens reachable as path URLs', () {
      for (final path in ['/sessions/session-1', '/account', '/x/v1.uid.9999999999.deadbeef']) {
        expect(
          migrateLegacyHashRoute(Uri.parse('https://2026-app.flutterkaigi.jp/#$path')),
          Uri.parse('https://2026-app.flutterkaigi.jp$path'),
        );
      }
    });

    test('preserves encoded paths and the legacy route query without decoding delimiters', () {
      const route = '/licenses/foo%20bar?value=a%26b&value=c%2Fd&next=%2Fsessions%2Fone';
      expect(
        migrateLegacyHashRoute(Uri.parse('https://2026-app.flutterkaigi.jp/#$route')).toString(),
        'https://2026-app.flutterkaigi.jp$route',
      );
    });

    test('keeps the fragment route query instead of the outer document query', () {
      expect(
        migrateLegacyHashRoute(Uri.parse('https://2026-app.flutterkaigi.jp/?ignored=outer#/sessions?search=Flutter')),
        Uri.parse('https://2026-app.flutterkaigi.jp/sessions?search=Flutter'),
      );
    });

    test('retains the current preview or local origin including its port', () {
      for (final origin in ['https://pr-42.example.pages.dev', 'http://localhost:8080']) {
        expect(migrateLegacyHashRoute(Uri.parse('$origin/#/account')), Uri.parse('$origin/account'));
      }
    });

    test('leaves path URLs, page anchors, and OAuth callback fragments alone', () {
      for (final url in [
        'https://2026-app.flutterkaigi.jp/sessions',
        'https://2026-app.flutterkaigi.jp/#overview',
        'https://2026-app.flutterkaigi.jp/#access_token=token',
        'https://2026-app.flutterkaigi.jp/sessions#/account',
      ]) {
        expect(migrateLegacyHashRoute(Uri.parse(url)), isNull, reason: url);
      }
    });

    test('does not accept an external origin or scheme from a fragment', () {
      for (final fragment in [
        '//example.com/account',
        '///example.com/account',
        r'/\example.com/account',
        'https://example.com/account',
        'javascript:alert(1)',
      ]) {
        expect(
          migrateLegacyHashRoute(Uri.parse('https://2026-app.flutterkaigi.jp/#$fragment')),
          isNull,
          reason: fragment,
        );
      }
    });

    test('does not reinterpret a relative URL or a native custom scheme', () {
      expect(migrateLegacyHashRoute(Uri.parse('/#/account')), isNull);
      expect(migrateLegacyHashRoute(Uri.parse('flutterkaigi://app/#/account')), isNull);
    });
  });
}
