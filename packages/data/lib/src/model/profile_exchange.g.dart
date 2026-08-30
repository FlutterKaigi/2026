// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_exchange.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileExchange _$ProfileExchangeFromJson(Map<String, dynamic> json) => _ProfileExchange(
  id: json['id'] as String,
  createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
  origin: $enumDecode(_$ProfileExchangeOriginEnumMap, json['origin']),
  token: json['token'] as String?,
  note: json['note'] as String?,
);

Map<String, dynamic> _$ProfileExchangeToJson(
  _ProfileExchange instance,
) => <String, dynamic>{
  'id': instance.id,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'origin': _$ProfileExchangeOriginEnumMap[instance.origin]!,
  'token': instance.token,
  'note': instance.note,
};

const _$ProfileExchangeOriginEnumMap = {
  ProfileExchangeOrigin.scan: 'scan',
  ProfileExchangeOrigin.mirror: 'mirror',
};
