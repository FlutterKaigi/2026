import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips through JSON with Firestore-style values', () {
    final exchange = ProfileExchange.fromJson({
      'id': 'other-uid',
      'createdAt': '2026-08-30T09:00:00Z',
      'origin': 'scan',
      'token': 'v1.uid.exp.sig',
      'note': 'Met at the venue lobby.',
    });

    expect(exchange.id, 'other-uid');
    expect(exchange.createdAt, DateTime.utc(2026, 8, 30, 9));
    expect(exchange.origin, ProfileExchangeOrigin.scan);
    expect(exchange.token, 'v1.uid.exp.sig');
    expect(exchange.note, 'Met at the venue lobby.');

    final json = exchange.toJson();
    expect(json['origin'], 'scan');
    expect(json['createdAt'], DateTime.utc(2026, 8, 30, 9));
  });

  test('defaults token and note to null when absent', () {
    final exchange = ProfileExchange.fromJson({
      'id': 'other-uid',
      'createdAt': '2026-08-30T09:00:00Z',
      'origin': 'mirror',
    });

    expect(exchange.origin, ProfileExchangeOrigin.mirror);
    expect(exchange.token, isNull);
    expect(exchange.note, isNull);
  });

  test('serializes origin as the plain string Firestore rules compare against', () {
    final exchange = ProfileExchange(
      id: 'other-uid',
      createdAt: DateTime.utc(2026, 8, 30),
      origin: ProfileExchangeOrigin.mirror,
    );

    expect(exchange.toJson()['origin'], 'mirror');
  });
}
