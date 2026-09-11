import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../model/support_lt.dart';
import 'firestore_watch.dart';

abstract interface class SupportLtRepository {
  /// Emits the attendee's registration, or `null` if they have not registered.
  Stream<SupportLtRegistration?> watchRegistration(String uid);

  /// Emits an immutable list, most recently registered first, after the server
  /// confirms staff access for this subscription.
  Stream<List<SupportLtRegistration>> watchRegistrations();

  /// Emits the current code, or `null` before issuance.
  /// Waits for the server to confirm staff access for this subscription.
  Stream<SupportLtCode?> watchCode();

  /// Issues a code, reusing the current code unless [rotate] is requested.
  /// The issued code arrives through [watchCode].
  /// Requires staff access and preserves [FirebaseFunctionsException] failures.
  Future<void> issueCode({bool rotate = false});

  /// Verifies [code] and registers the authenticated attendee on the server.
  /// Repeated registration succeeds without adding another participant.
  /// Preserves [FirebaseFunctionsException] failures for the caller to display.
  Future<void> register(String code);
}

final class FirebaseSupportLtRepository implements SupportLtRepository {
  FirebaseSupportLtRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _registrations => _firestore.collection('supportLtRegistrations');

  @override
  Stream<SupportLtRegistration?> watchRegistration(String uid) =>
      watchFirestoreDocument(_registrations.doc(uid)).map((snapshot) {
        final data = snapshot.data();
        return data == null ? null : _registration(snapshot.id, data);
      });

  @override
  Stream<List<SupportLtRegistration>> watchRegistrations() =>
      waitForUsableInitialSnapshot(
        _registrations.orderBy('registeredAt', descending: true).snapshots(includeMetadataChanges: true),
        // Firestore's persistent cache can belong to a previously signed-in
        // staff member. Check this subscriber's server authorization first.
        isUsableInitialSnapshot: (snapshot) => !snapshot.metadata.isFromCache,
        shouldForwardAfterInitial: (snapshot) => snapshot.docChanges.isNotEmpty,
      ).map(
        (snapshot) => List<SupportLtRegistration>.unmodifiable(
          snapshot.docs.map((document) => _registration(document.id, document.data())),
        ),
      );

  @override
  Stream<SupportLtCode?> watchCode() =>
      waitForUsableInitialSnapshot(
        _firestore.collection('supportLtSettings').doc('current').snapshots(includeMetadataChanges: true),
        // A cached code must not be disclosed before staff access is checked.
        isUsableInitialSnapshot: (snapshot) => !snapshot.metadata.isFromCache,
      ).map((snapshot) {
        final data = snapshot.data();
        return data == null
            ? null
            : SupportLtCode(
                code: _string(data['code'], 'code'),
                issuedAt: _timestamp(data['issuedAt'], 'issuedAt'),
              );
      });

  @override
  Future<void> issueCode({bool rotate = false}) async {
    await _functions.httpsCallable('issueSupportLtCode').call<Object?>({'rotate': rotate});
  }

  @override
  Future<void> register(String code) async {
    await _functions.httpsCallable('registerSupportLt').call<Object?>({'code': code});
  }

  static SupportLtRegistration _registration(String uid, Map<String, dynamic> data) => SupportLtRegistration(
    uid: uid,
    displayName: _string(data['displayName'], 'displayName'),
    registeredAt: _timestamp(data['registeredAt'], 'registeredAt'),
  );

  static String _string(Object? value, String field) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw FormatException('Expected a non-empty string for $field.');
  }

  static DateTime _timestamp(Object? value, String field) {
    if (value is Timestamp) {
      return value.toDate();
    }
    throw FormatException('Expected a Firestore timestamp for $field.');
  }
}
