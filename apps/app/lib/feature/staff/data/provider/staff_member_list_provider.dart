import 'package:app/feature/staff/data/provider/staff_member_repository.dart';
import 'package:data/data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Streams staff members in their Firestore-defined display order.
final staffMemberListProvider = StreamProvider<List<StaffMember>>(
  (ref) => ref.watch(staffMemberRepositoryProvider).watchAll(),
);
