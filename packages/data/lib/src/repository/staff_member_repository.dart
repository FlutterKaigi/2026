import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/staff_member.dart';

abstract interface class StaffMemberRepository {
  Stream<List<StaffMember>> watchAll();
  Future<void> save(StaffMember staffMember);
  Future<void> delete(String id);
}

final class FirestoreStaffMemberRepository implements StaffMemberRepository {
  FirestoreStaffMemberRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('staffMembers');

  @override
  Stream<List<StaffMember>> watchAll() {
    return _collection
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) StaffMember.fromJson(<String, dynamic>{...doc.data(), 'id': doc.id}),
          ],
        );
  }

  @override
  Future<void> save(StaffMember staffMember) async {
    final data = staffMember.toJson()
      ..remove('id')
      ..remove('createdAt')
      ..remove('updatedAt');
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (staffMember.isNew) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await _collection.add(data);
    } else {
      await _collection.doc(staffMember.id).set(data, SetOptions(merge: true));
    }
  }

  @override
  Future<void> delete(String id) => _collection.doc(id).delete();
}
