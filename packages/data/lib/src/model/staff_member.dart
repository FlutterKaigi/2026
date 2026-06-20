import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';
import 'sns_link.dart';

part 'staff_member.freezed.dart';
part 'staff_member.g.dart';

@freezed
abstract class StaffMember with _$StaffMember {
  const StaffMember._();

  const factory StaffMember({
    required String id,
    required String name,
    required String iconUrl,
    String? greeting,
    @Default([]) List<SnsLink> snsLinks,
    required int order,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
  }) = _StaffMember;

  factory StaffMember.fromJson(Map<String, dynamic> json) => _$StaffMemberFromJson(json);

  bool get isNew => id.isEmpty;
}
