import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data/src/converter/firestore_converters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreDateTimeConverter', () {
    const converter = FirestoreDateTimeConverter();
    final dt = DateTime.utc(2026, 5, 1, 9);

    test('fromJson accepts a real Firestore Timestamp (duck-typed, no static cloud_firestore dependency)', () {
      expect(converter.fromJson(Timestamp.fromDate(dt)).isAtSameMomentAs(dt), isTrue);
    });

    test('fromJson accepts a DateTime as-is', () {
      expect(converter.fromJson(dt), dt);
    });

    test('fromJson accepts an ISO-8601 string (REST fetch / seed JSON)', () {
      expect(converter.fromJson(dt.toIso8601String()).isAtSameMomentAs(dt), isTrue);
    });

    test('fromJson throws on unsupported input', () {
      expect(() => converter.fromJson(42), throwsFormatException);
    });

    test('toJson returns the DateTime unchanged (cloud_firestore converts DateTime -> Timestamp on write)', () {
      // Not `Timestamp.fromDate(dt)`: this converter must not need a static
      // cloud_firestore import so it stays usable from plain `dart run`
      // scripts. cloud_firestore's own write path already accepts a
      // DateTime and converts it to a native Timestamp internally, so
      // returning the DateTime as-is is behaviorally equivalent on write.
      expect(converter.toJson(dt), same(dt));
    });

    test('fromJson(toJson(x)) round-trips to the same instant', () {
      expect(converter.fromJson(converter.toJson(dt)).isAtSameMomentAs(dt), isTrue);
    });
  });
}
