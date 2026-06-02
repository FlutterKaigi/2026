import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/news.dart';

abstract interface class NewsRepository {
  Future<List<News>> fetchNews();
}

final class FirestoreNewsRepository implements NewsRepository {
  FirestoreNewsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<News>> fetchNews({DateTime? activeAt}) async {
    final snapshot = await _firestore
        .collection('news')
        .orderBy('startsAt', descending: true)
        .get();
    final now = activeAt ?? DateTime.now();
    final news = [
      for (final document in snapshot.docs)
        News.fromJson(<String, dynamic>{...document.data(), 'id': document.id}),
    ]..sort((a, b) => b.startsAt.compareTo(a.startsAt));

    return news.where((item) => item.isActiveAt(now)).toList(growable: false);
  }
}
