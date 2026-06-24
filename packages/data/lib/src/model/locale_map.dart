import 'package:freezed_annotation/freezed_annotation.dart';

part 'locale_map.freezed.dart';
part 'locale_map.g.dart';

@freezed
abstract class LocaleMap with _$LocaleMap {
  const factory LocaleMap({required String ja, required String en}) = _LocaleMap;

  factory LocaleMap.fromJson(Map<String, dynamic> json) => _$LocaleMapFromJson(json);
}
