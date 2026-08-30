import 'package:app/feature/exchange/data/exchange_scan_outcome.dart';
import 'package:data/data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_profile_exchange_repository.dart';

void main() {
  const currentUid = 'uid-me';
  const token = 'v1.uid-other.9999999999.sig';

  test('records a successful scan and returns the other uid', () async {
    final repository = FakeProfileExchangeRepository(uid: currentUid);

    final outcome = await handleScannedExchangeToken(
      raw: 'https://2026.flutterkaigi.jp/x/$token',
      currentUid: currentUid,
      repository: repository,
    );

    expect(outcome.kind, ExchangeScanOutcomeKind.success);
    expect(outcome.otherUid, 'uid-other');
    expect(repository.exchangesFor(currentUid).single.id, 'uid-other');
  });

  test('rejects scanning your own QR code without writing anything', () async {
    final repository = FakeProfileExchangeRepository(uid: currentUid);

    final outcome = await handleScannedExchangeToken(
      raw: 'https://2026.flutterkaigi.jp/x/v1.$currentUid.9999999999.sig',
      currentUid: currentUid,
      repository: repository,
    );

    expect(outcome.kind, ExchangeScanOutcomeKind.selfScan);
    expect(repository.exchangesFor(currentUid), isEmpty);
  });

  test('reports a malformed value without writing anything', () async {
    final repository = FakeProfileExchangeRepository(uid: currentUid);

    final outcome = await handleScannedExchangeToken(
      raw: 'not a qr code',
      currentUid: currentUid,
      repository: repository,
    );

    expect(outcome.kind, ExchangeScanOutcomeKind.malformed);
    expect(repository.exchangesFor(currentUid), isEmpty);
  });

  test('reports a duplicate when the pair already exchanged', () async {
    final repository = FakeProfileExchangeRepository(
      uid: currentUid,
      initialExchanges: [
        ProfileExchange(id: 'uid-other', createdAt: DateTime.now(), origin: ProfileExchangeOrigin.mirror),
      ],
    );

    final outcome = await handleScannedExchangeToken(
      raw: 'https://2026.flutterkaigi.jp/x/$token',
      currentUid: currentUid,
      repository: repository,
    );

    expect(outcome.kind, ExchangeScanOutcomeKind.duplicate);
    expect(outcome.otherUid, 'uid-other');
  });

  test('reports a generic error for unexpected Firestore failures', () async {
    final repository = FakeProfileExchangeRepository(uid: currentUid)
      ..nextCreateError = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');

    final outcome = await handleScannedExchangeToken(
      raw: 'https://2026.flutterkaigi.jp/x/$token',
      currentUid: currentUid,
      repository: repository,
    );

    expect(outcome.kind, ExchangeScanOutcomeKind.error);
  });

  test('rejects an expired token without writing anything', () async {
    final repository = FakeProfileExchangeRepository(uid: currentUid);

    final outcome = await handleScannedExchangeToken(
      // exp = 1 (1970-01-01T00:00:01Z), long past.
      raw: 'https://2026.flutterkaigi.jp/x/v1.uid-other.1.sig',
      currentUid: currentUid,
      repository: repository,
      now: DateTime.utc(2026),
    );

    expect(outcome.kind, ExchangeScanOutcomeKind.expired);
    expect(outcome.otherUid, 'uid-other');
    expect(repository.exchangesFor(currentUid), isEmpty);
  });

  test('accepts a token that expires later the same second it is checked', () async {
    final repository = FakeProfileExchangeRepository(uid: currentUid);
    final now = DateTime.utc(2026);
    final expSeconds = now.millisecondsSinceEpoch ~/ 1000 + 60;

    final outcome = await handleScannedExchangeToken(
      raw: 'https://2026.flutterkaigi.jp/x/v1.uid-other.$expSeconds.sig',
      currentUid: currentUid,
      repository: repository,
      now: now,
    );

    expect(outcome.kind, ExchangeScanOutcomeKind.success);
  });

  test('reports offlinePending when the write does not resolve before the timeout', () async {
    final repository = FakeProfileExchangeRepository(uid: currentUid)
      ..createFromScanDelay = const Duration(milliseconds: 50);

    final outcome = await handleScannedExchangeToken(
      raw: 'https://2026.flutterkaigi.jp/x/$token',
      currentUid: currentUid,
      repository: repository,
      timeout: const Duration(milliseconds: 10),
    );

    expect(outcome.kind, ExchangeScanOutcomeKind.offlinePending);
    expect(outcome.otherUid, 'uid-other');

    // 実際の書き込みは打ち切られておらず、タイムアウト後も裏で完了する
    // (ローカルキャッシュへの反映は即時であるという前提のドキュメント通り)。
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(repository.exchangesFor(currentUid), isNotEmpty);
  });
}
