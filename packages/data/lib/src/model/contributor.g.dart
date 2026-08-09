// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contributor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Contributor _$ContributorFromJson(Map<String, dynamic> json) => _Contributor(
  login: json['login'] as String,
  avatarUrl: json['avatarUrl'] as String,
  htmlUrl: json['htmlUrl'] as String,
  contributions: (json['contributions'] as num).toInt(),
);

Map<String, dynamic> _$ContributorToJson(_Contributor instance) =>
    <String, dynamic>{
      'login': instance.login,
      'avatarUrl': instance.avatarUrl,
      'htmlUrl': instance.htmlUrl,
      'contributions': instance.contributions,
    };
