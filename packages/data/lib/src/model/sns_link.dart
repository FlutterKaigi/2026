import 'package:freezed_annotation/freezed_annotation.dart';

part 'sns_link.freezed.dart';
part 'sns_link.g.dart';

@freezed
abstract class SnsLink with _$SnsLink {
  const factory SnsLink({required String type, required String value}) = _SnsLink;

  factory SnsLink.fromJson(Map<String, dynamic> json) => _$SnsLinkFromJson(json);
}
