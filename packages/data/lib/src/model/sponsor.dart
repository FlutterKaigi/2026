import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';
import 'locale_map.dart';

part 'sponsor.freezed.dart';
part 'sponsor.g.dart';

@JsonEnum()
enum SponsorTier { platinum, gold, silver, bronze }

@freezed
abstract class Sponsor with _$Sponsor {
  const Sponsor._();

  const factory Sponsor({
    required String id,
    required LocaleMap name,
    String? nameKana,
    required LocaleMap description,
    required String logoUrl,
    required SponsorTier tier,
    String? xUrl,
    String? websiteUrl,
    String? recruitUrl,
    String? jobBoardUrl,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
  }) = _Sponsor;

  factory Sponsor.fromJson(Map<String, dynamic> json) => _$SponsorFromJson(json);

  bool get isNew => id.isEmpty;
}
