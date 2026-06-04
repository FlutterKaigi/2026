import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('News.fromJson', () {
    test('decodes Firestore Timestamp fields into DateTime', () {
      final startsAt = DateTime.utc(2026, 5, 1, 9);
      final news = News.fromJson(<String, dynamic>{
        'id': 'sponsorship-guide',
        'title': 'Sample',
        'status': 'published',
        'startsAt': Timestamp.fromDate(startsAt),
        'createdAt': Timestamp.fromDate(startsAt),
        'updatedAt': Timestamp.fromDate(startsAt),
        'url': 'https://example.com',
        'endsAt': null,
      });

      expect(news.startsAt.isAtSameMomentAs(startsAt), isTrue);
      expect(news.url, Uri.parse('https://example.com'));
      expect(news.endsAt, isNull);
    });
  });

  group('News.isActiveAt', () {
    final base = DateTime.utc(2026, 5, 1);
    News build({NewsStatus status = NewsStatus.published, DateTime? endsAt}) {
      return News(
        id: 'x',
        title: 't',
        status: status,
        startsAt: base,
        createdAt: base,
        updatedAt: base,
        endsAt: endsAt,
      );
    }

    test('published item within range is active', () {
      expect(build().isActiveAt(base.add(const Duration(days: 1))), isTrue);
    });

    test('draft item is inactive', () {
      expect(build(status: NewsStatus.draft).isActiveAt(base), isFalse);
    });

    test('item past endsAt is inactive', () {
      final ended = build(endsAt: base.add(const Duration(days: 1)));
      expect(ended.isActiveAt(base.add(const Duration(days: 2))), isFalse);
    });
  });
}
