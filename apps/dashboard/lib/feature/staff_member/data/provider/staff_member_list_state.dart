import 'package:data/data.dart';
import 'package:dashboard/feature/staff_member/data/provider/staff_member_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final staffMemberListProvider = StreamProvider<List<StaffMember>>(
  (ref) => ref.watch(staffMemberRepositoryProvider).watchAll(),
);
