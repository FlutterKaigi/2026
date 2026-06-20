import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';

part 'speaker.freezed.dart';
part 'speaker.g.dart';

@freezed
abstract class Speaker with _$Speaker {
  const Speaker._();

  const factory Speaker({
    required String id,
    required String name,
    String? avatarUrl,
    String? xId,
    String? bio,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
  }) = _Speaker;

  factory Speaker.fromJson(Map<String, dynamic> json) => _$SpeakerFromJson(json);

  bool get isNew => id.isEmpty;
}
