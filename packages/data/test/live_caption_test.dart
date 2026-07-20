import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveCaptionRoom.fromJson', () {
    test('サーバーが書く全フィールドを変換する', () {
      final updatedAt = DateTime.utc(2026, 11, 14, 1, 5, 30);
      final room = LiveCaptionRoom.fromJson(<String, dynamic>{
        'id': 'hall-a',
        'enabled': true,
        'isLive': true,
        'sourceLang': 'ja-JP',
        'interim': {
          'text': '続いて…',
          'srcLang': 'ja',
          'updatedAt': Timestamp.fromDate(updatedAt),
        },
        'updatedAt': Timestamp.fromDate(updatedAt),
      });

      expect(room.id, 'hall-a');
      expect(room.isShowable, isTrue);
      expect(room.sourceLang, 'ja-JP');
      expect(room.interim?.text, '続いて…');
      expect(room.interim?.updatedAt?.isAtSameMomentAs(updatedAt), isTrue);
    });

    test('欠落フィールドは既定値に倒れ、enabled=false で isShowable が消える', () {
      final room = LiveCaptionRoom.fromJson(<String, dynamic>{
        'id': 'hall-b',
        'enabled': false,
        'isLive': true,
      });

      expect(room.enabled, isFalse);
      expect(room.isShowable, isFalse);
      expect(room.interim, isNull);
      expect(room.updatedAt, isNull);
    });
  });

  group('LiveCaptionSegment.fromJson', () {
    test('セグメントの全フィールドを変換する', () {
      final createdAt = DateTime.utc(2026, 11, 14, 1, 5, 4);
      final segment = LiveCaptionSegment.fromJson(<String, dynamic>{
        'id': '1789000000000-000001',
        'seq': 1,
        'srcLang': 'ja',
        'srcText': 'ようこそ。',
        'ja': 'ようこそ。',
        'en': 'Welcome.',
        'startMs': 0,
        'endMs': 4200,
        'createdAt': Timestamp.fromDate(createdAt),
      });

      expect(segment.id, '1789000000000-000001');
      expect(segment.seq, 1);
      expect(segment.en, 'Welcome.');
      expect(segment.createdAt?.isAtSameMomentAs(createdAt), isTrue);
    });
  });
}
