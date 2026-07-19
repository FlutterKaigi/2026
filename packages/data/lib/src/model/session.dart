import 'package:freezed_annotation/freezed_annotation.dart';

import '../converter/firestore_converters.dart';
import 'locale_map.dart';

part 'session.freezed.dart';
part 'session.g.dart';

@freezed
abstract class Session with _$Session {
  const Session._();

  const factory Session({
    required String id,
    required LocaleMap title,
    required LocaleMap description,
    required String primaryLocale,
    @FirestoreDateTimeConverter() required DateTime startsAt,
    @FirestoreDateTimeConverter() required DateTime endsAt,
    required String venueId,
    @Default([]) List<String> speakerIds,
    @Default(false) bool isLightningTalk,
    @Default(false) bool isBeginnersLightningTalk,
    @Default(false) bool isHandsOn,
    String? sessionizeUrl,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);

  bool get isNew => id.isEmpty;
}
