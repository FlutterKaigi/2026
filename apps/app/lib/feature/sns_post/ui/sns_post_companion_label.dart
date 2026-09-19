import 'package:app/core/i18n/strings.g.dart';
import 'package:data/data.dart';

String snsPostCompanionLabel(Translations t, SnsPostCompanion companion) => switch (companion) {
  SnsPostCompanion.staff => t.snsPost.companions.staff,
  SnsPostCompanion.speaker => t.snsPost.companions.speaker,
  SnsPostCompanion.sponsor => t.snsPost.companions.sponsor,
  SnsPostCompanion.firstTime => t.snsPost.companions.firstTime,
  SnsPostCompanion.differentCountry => t.snsPost.companions.differentCountry,
};
