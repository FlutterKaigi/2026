import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/sns_post.dart';
import 'firestore_watch.dart';

abstract interface class SnsPostRepository {
  Stream<SnsPostRegistration?> watch(String uid);

  /// Replaces this attendee's one registration. Completion waits for the
  /// server acknowledgement; a pending local write must not award a stamp.
  Future<void> save({required String uid, required String url, required SnsPostCompanion companion});
}

final class FirestoreSnsPostRepository implements SnsPostRepository {
  FirestoreSnsPostRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      _firestore.collection('snsPostRegistrations').doc(uid);

  @override
  Stream<SnsPostRegistration?> watch(String uid) =>
      watchFirestoreDocument(_document(uid)).where((snapshot) => !snapshot.metadata.hasPendingWrites).map((snapshot) {
        final data = snapshot.data();
        if (data == null) {
          return null;
        }
        final url = data['url'];
        final companion = data['companion'];
        final updatedAt = data['updatedAt'];
        if (url is! String ||
            !SnsPostRegistration.isValidUrl(url) ||
            !SnsPostCompanion.values.any((value) => value.name == companion) ||
            updatedAt is! Timestamp) {
          throw const FormatException('Invalid SNS post registration.');
        }
        return SnsPostRegistration(
          url: url,
          companion: SnsPostCompanion.values.byName(companion as String),
          updatedAt: updatedAt.toDate(),
        );
      });

  @override
  Future<void> save({required String uid, required String url, required SnsPostCompanion companion}) {
    final trimmed = url.trim();
    if (!SnsPostRegistration.isValidUrl(trimmed)) {
      throw const FormatException('Invalid SNS post URL.');
    }
    return _document(uid).set({
      'url': trimmed,
      'companion': companion.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
