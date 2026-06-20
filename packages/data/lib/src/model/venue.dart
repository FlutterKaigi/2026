import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';
import 'locale_map.dart';

part 'venue.freezed.dart';
part 'venue.g.dart';

@freezed
abstract class Venue with _$Venue {
  const Venue._();

  const factory Venue({
    required String id,
    required LocaleMap name,
    int? order,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
  }) = _Venue;

  factory Venue.fromJson(Map<String, dynamic> json) => _$VenueFromJson(json);

  bool get isNew => id.isEmpty;
}
