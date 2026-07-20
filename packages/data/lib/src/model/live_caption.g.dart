// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_caption.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveCaptionRoom _$LiveCaptionRoomFromJson(Map<String, dynamic> json) =>
    _LiveCaptionRoom(
      id: json['id'] as String,
      enabled: json['enabled'] as bool? ?? true,
      isLive: json['isLive'] as bool? ?? false,
      sourceLang: json['sourceLang'] as String?,
      interim: json['interim'] == null
          ? null
          : LiveCaptionInterim.fromJson(
              json['interim'] as Map<String, dynamic>,
            ),
      updatedAt: const FirestoreNullableDateTimeConverter().fromJson(
        json['updatedAt'],
      ),
    );

Map<String, dynamic> _$LiveCaptionRoomToJson(_LiveCaptionRoom instance) =>
    <String, dynamic>{
      'id': instance.id,
      'enabled': instance.enabled,
      'isLive': instance.isLive,
      'sourceLang': instance.sourceLang,
      'interim': instance.interim?.toJson(),
      'updatedAt': const FirestoreNullableDateTimeConverter().toJson(
        instance.updatedAt,
      ),
    };

_LiveCaptionInterim _$LiveCaptionInterimFromJson(Map<String, dynamic> json) =>
    _LiveCaptionInterim(
      text: json['text'] as String,
      srcLang: json['srcLang'] as String,
      updatedAt: const FirestoreNullableDateTimeConverter().fromJson(
        json['updatedAt'],
      ),
    );

Map<String, dynamic> _$LiveCaptionInterimToJson(_LiveCaptionInterim instance) =>
    <String, dynamic>{
      'text': instance.text,
      'srcLang': instance.srcLang,
      'updatedAt': const FirestoreNullableDateTimeConverter().toJson(
        instance.updatedAt,
      ),
    };

_LiveCaptionSegment _$LiveCaptionSegmentFromJson(Map<String, dynamic> json) =>
    _LiveCaptionSegment(
      id: json['id'] as String,
      seq: (json['seq'] as num).toInt(),
      srcLang: json['srcLang'] as String,
      srcText: json['srcText'] as String,
      ja: json['ja'] as String,
      en: json['en'] as String,
      startMs: (json['startMs'] as num?)?.toInt() ?? 0,
      endMs: (json['endMs'] as num?)?.toInt() ?? 0,
      createdAt: const FirestoreNullableDateTimeConverter().fromJson(
        json['createdAt'],
      ),
    );

Map<String, dynamic> _$LiveCaptionSegmentToJson(_LiveCaptionSegment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'seq': instance.seq,
      'srcLang': instance.srcLang,
      'srcText': instance.srcText,
      'ja': instance.ja,
      'en': instance.en,
      'startMs': instance.startMs,
      'endMs': instance.endMs,
      'createdAt': const FirestoreNullableDateTimeConverter().toJson(
        instance.createdAt,
      ),
    };
