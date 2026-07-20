part of 'router.dart';

/// Shell hosting the main bottom/rail navigation destinations.
///
/// Uses [StatefulShellRoute.indexedStack] so switching tabs swaps branches
/// instantly (no page transition animation) while preserving each branch's
/// navigation and scroll state.
@TypedStatefulShellRoute<AppShellRoute>(
  branches: [
    TypedStatefulShellBranch<NewsBranch>(
      routes: [TypedGoRoute<NewsRoute>(path: '/news')],
    ),
    TypedStatefulShellBranch<LiveCaptionsBranch>(
      routes: [
        TypedGoRoute<LiveCaptionsRoute>(
          path: '/captions',
          routes: [
            TypedGoRoute<LiveCaptionScanRoute>(path: 'scan'),
            TypedGoRoute<LiveCaptionRoomRoute>(path: ':venueId'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<EventInfoBranch>(
      routes: [TypedGoRoute<EventInfoRoute>(path: '/info')],
    ),
  ],
)
class AppShellRoute extends StatefulShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    final t = Translations.of(context);
    return RootScaffold(
      navigationShell: navigationShell,
      destinations: [
        RootDestination(
          icon: Icons.campaign_outlined,
          label: t.navigation.news,
        ),
        RootDestination(
          icon: Icons.subtitles_outlined,
          label: t.navigation.captions,
        ),
        RootDestination(
          icon: Icons.info_outline,
          label: t.navigation.info,
        ),
      ],
    );
  }
}

/// Branch hosting the news tab. Branch order must match the order of
/// [RootScaffold.destinations] built in [AppShellRoute.builder].
class NewsBranch extends StatefulShellBranchData {
  const NewsBranch();
}

/// Branch hosting the live captions tab.
class LiveCaptionsBranch extends StatefulShellBranchData {
  const LiveCaptionsBranch();
}

/// Branch hosting the event info tab.
class EventInfoBranch extends StatefulShellBranchData {
  const EventInfoBranch();
}

/// `/news` — the news list.
class NewsRoute extends GoRouteData with $NewsRoute {
  const NewsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const NewsListPage();
}

/// `/captions` — session picker for live captions.
class LiveCaptionsRoute extends GoRouteData with $LiveCaptionsRoute {
  const LiveCaptionsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const LiveCaptionsPage();
}

/// `/captions/scan` — QR scanner that opens a caption room.
class LiveCaptionScanRoute extends GoRouteData with $LiveCaptionScanRoute {
  const LiveCaptionScanRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const LiveCaptionScanPage();
}

/// `/captions/:venueId` — live captions of one venue.
class LiveCaptionRoomRoute extends GoRouteData with $LiveCaptionRoomRoute {
  const LiveCaptionRoomRoute({required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      LiveCaptionRoomPage(venueId: venueId);
}

/// `/info` — event and app information.
class EventInfoRoute extends GoRouteData with $EventInfoRoute {
  const EventInfoRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const EventInfoPage();
}
