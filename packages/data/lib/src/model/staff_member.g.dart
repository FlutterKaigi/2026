// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StaffMember _$StaffMemberFromJson(Map<String, dynamic> json) => _StaffMember(
  id: json['id'] as String,
  name: json['name'] as String,
  iconUrl: json['iconUrl'] as String,
  greeting: json['greeting'] as String?,
  snsLinks:
      (json['snsLinks'] as List<dynamic>?)
          ?.map((e) => SnsLink.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  order: (json['order'] as num).toInt(),
  createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$StaffMemberToJson(
  _StaffMember instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'iconUrl': instance.iconUrl,
  'greeting': instance.greeting,
  'snsLinks': instance.snsLinks.map((e) => e.toJson()).toList(),
  'order': instance.order,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
};
