import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The activities attendees join at the venue. Both the signed-out preview and
/// the signed-in list of the venue events hub are built from this one list.
enum VenueEventFeature {
  quiz(Icons.quiz_outlined),
  stampRally(Icons.approval_outlined),
  profileExchange(Icons.qr_code_2_outlined),
  supportLt(Icons.mic_none_outlined),
  snsPost(Icons.image_outlined),
  mission(Icons.track_changes_outlined);

  const VenueEventFeature(this.icon);

  final IconData icon;

  /// Rows of the signed-in hub. Missions follow them in a card of their own.
  static const signedInRows = [quiz, stampRally, profileExchange, supportLt, snsPost];

  /// Tiles of the signed-out preview.
  static const signedOutPreview = [stampRally, profileExchange, supportLt, snsPost, quiz, mission];

  String title(Translations t) => switch (this) {
    quiz => t.venueEvents.features.quiz.title,
    stampRally => t.venueEvents.features.stampRally.title,
    profileExchange => t.venueEvents.features.profileExchange.title,
    supportLt => t.venueEvents.features.supportLt.title,
    snsPost => t.venueEvents.features.snsPost.title,
    mission => t.venueEvents.features.mission.title,
  };

  /// What to do there, under the title of a signed-in row. Missions have none
  /// because their card shows the attendee's progress instead.
  String? action(Translations t) => switch (this) {
    quiz => t.venueEvents.features.quiz.action,
    stampRally => t.venueEvents.features.stampRally.action,
    profileExchange => t.venueEvents.features.profileExchange.action,
    supportLt => t.venueEvents.features.supportLt.action,
    snsPost => t.venueEvents.features.snsPost.action,
    mission => null,
  };

  /// What the activity is, on its signed-out preview tile.
  String preview(Translations t) => switch (this) {
    quiz => t.venueEvents.features.quiz.preview,
    stampRally => t.venueEvents.features.stampRally.preview,
    profileExchange => t.venueEvents.features.profileExchange.preview,
    supportLt => t.venueEvents.features.supportLt.preview,
    snsPost => t.venueEvents.features.snsPost.preview,
    mission => t.venueEvents.features.mission.preview,
  };

  GoRouteData get route => switch (this) {
    quiz => const QuizListRoute(),
    stampRally => const StampRallyRoute(),
    profileExchange => const ExchangeHomeRoute(),
    supportLt => const SupportLtRoute(),
    snsPost => const SnsPostRoute(),
    mission => const MissionRoute(),
  };
}
