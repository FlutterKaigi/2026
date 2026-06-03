// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:website/components/event_section/event_info_card.dart'
    as _event_info_card;
import 'package:website/components/event_section/news_card.dart' as _news_card;
import 'package:website/components/event_section/roadmap_card.dart'
    as _roadmap_card;
import 'package:website/components/event_section/social_link_card.dart'
    as _social_link_card;
import 'package:website/components/event_section.dart' as _event_section;
import 'package:website/components/footer.dart' as _footer;
import 'package:website/components/header.dart' as _header;
import 'package:website/components/sponsors_section.dart' as _sponsors_section;
import 'package:website/pages/home.dart' as _home;
import 'package:website/pages/sponsor_detail.dart' as _sponsor_detail;
import 'package:website/app.dart' as _app;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',

  styles: () => [
    ..._event_info_card.EventInfoCard.styles,
    ..._news_card.NewsCard.styles,
    ..._roadmap_card.RoadmapCard.styles,
    ..._social_link_card.SocialLinkCard.styles,
    ..._event_section.EventSection.styles,
    ..._footer.Footer.styles,
    ..._header.Header.styles,
    ..._sponsors_section.SponsorsSection.styles,
    ..._home.Home.styles,
    ..._sponsor_detail.SponsorDetailPage.styles,
    ..._app.App.styles,
  ],
);
