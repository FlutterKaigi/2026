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
}
