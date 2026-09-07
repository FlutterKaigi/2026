import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips through JSON with Firestore-style values', () {
    final exchange = ProfileExchange.fromJson({
      'id': 'other-uid-1',
      'createdAt': '2026-08-02T00:00:00Z',
      'origin': 'scan',
      'token': 'v1.other-uid-1.9999999999.signature',
      'note': 'ロビーで交換',
    });

    expect(exchange.id, 'other-uid-1');
    expect(exchange.createdAt, DateTime.utc(2026, 8, 2));
    expect(exchange.origin, ProfileExchangeOrigin.scan);
    expect(exchange.token, 'v1.other-uid-1.9999999999.signature');
    expect(exchange.note, 'ロビーで交換');

    final json = exchange.toJson();
    expect(json['origin'], 'scan');
    expect(json['createdAt'], DateTime.utc(2026, 8, 2));
  });

  test('parses the mirror origin and defaults token/note to null when absent', () {
    final exchange = ProfileExchange.fromJson({
      'id': 'other-uid-2',
      'createdAt': '2026-08-02T00:00:00Z',
      'origin': 'mirror',
    });

    expect(exchange.origin, ProfileExchangeOrigin.mirror);
    expect(exchange.token, isNull);
    expect(exchange.note, isNull);
    expect(exchange.toJson()['origin'], 'mirror');
  });
}
