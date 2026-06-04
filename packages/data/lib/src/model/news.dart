import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';

part 'news.freezed.dart';
part 'news.g.dart';

@freezed
abstract class News with _$News {
  const News._();

  const factory News({
    required String id,
    required String title,
    required NewsStatus status,
    @FirestoreDateTimeConverter() required DateTime startsAt,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
    @FirestoreNullableUriConverter() Uri? url,
    @FirestoreNullableDateTimeConverter() DateTime? endsAt,
  }) = _News;

  factory News.fromJson(Map<String, dynamic> json) => _$NewsFromJson(json);

  bool isActiveAt(DateTime now) {
    return status == NewsStatus.published && !startsAt.isAfter(now) && (endsAt == null || endsAt!.isAfter(now));
  }
}

enum NewsStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('published')
  published,
  @JsonValue('archived')
  archived,
}
