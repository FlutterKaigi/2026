import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/news.dart';

abstract interface class NewsRepository {
  Future<List<News>> fetchNews();
  Stream<List<News>> watchAll();
  Future<void> save(News news);
  Future<void> delete(String id);
}

final class FirestoreNewsRepository implements NewsRepository {
  FirestoreNewsRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('news');

  @override
  Future<List<News>> fetchNews() async {
    final snapshot = await _collection.orderBy('publishedAt', descending: true).get();
    return [
      for (final doc in snapshot.docs) News.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
    ];
  }

  @override
  Stream<List<News>> watchAll() {
    return _collection
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) News.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }

  @override
  Future<void> save(News news) async {
    final data = news.toJson()
      ..remove('id')
      ..remove('createdAt')
      ..remove('updatedAt');
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (news.id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await _collection.add(data);
    } else {
      await _collection.doc(news.id).set(data, SetOptions(merge: true));
    }
  }

  @override
  Future<void> delete(String id) => _collection.doc(id).delete();
}
