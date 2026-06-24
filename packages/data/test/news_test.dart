import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('News.fromJson', () {
    test('Timestamp フィールドを DateTime に変換する', () {
      final publishedAt = DateTime.utc(2026, 5, 1, 9);
      final news = News.fromJson(<String, dynamic>{
        'id': 'news-001',
        'title': {'ja': '日本語タイトル', 'en': 'English Title'},
        'publishedAt': Timestamp.fromDate(publishedAt),
        'createdAt': Timestamp.fromDate(publishedAt),
        'updatedAt': Timestamp.fromDate(publishedAt),
        'url': {'ja': '', 'en': ''},
      });

      expect(news.publishedAt.isAtSameMomentAs(publishedAt), isTrue);
      expect(news.title.ja, '日本語タイトル');
      expect(news.title.en, 'English Title');
      expect(news.url.ja, '');
    });

    test('url が LocaleMap として変換される', () {
      final publishedAt = DateTime.utc(2026, 5, 1, 9);
      final news = News.fromJson(<String, dynamic>{
        'id': 'news-002',
        'title': {'ja': 'タイトル', 'en': 'Title'},
        'publishedAt': Timestamp.fromDate(publishedAt),
        'createdAt': Timestamp.fromDate(publishedAt),
        'updatedAt': Timestamp.fromDate(publishedAt),
        'url': {'ja': 'https://example.com/ja', 'en': 'https://example.com/en'},
      });

      expect(news.url.ja, 'https://example.com/ja');
      expect(news.url.en, 'https://example.com/en');
    });
  });
}
