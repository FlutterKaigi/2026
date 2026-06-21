part of 'router.dart';

@TypedShellRoute<AppShellRoute>(
  routes: [
    TypedGoRoute<HomeRoute>(path: AppPaths.home),
    TypedGoRoute<NewsListRoute>(
      path: AppPaths.news,
      routes: [
        TypedGoRoute<NewsEditRoute>(path: AppPaths.newsEdit),
      ],
    ),
    TypedGoRoute<VenueListRoute>(
      path: AppPaths.venues,
      routes: [
        TypedGoRoute<VenueEditRoute>(path: AppPaths.venueEdit),
      ],
    ),
    TypedGoRoute<SpeakerListRoute>(
      path: AppPaths.speakers,
      routes: [
        TypedGoRoute<SpeakerEditRoute>(path: AppPaths.speakerEdit),
      ],
    ),
    TypedGoRoute<StaffMemberListRoute>(
      path: AppPaths.staff,
      routes: [
        TypedGoRoute<StaffMemberEditRoute>(path: AppPaths.staffMemberEdit),
      ],
    ),
    TypedGoRoute<TimelineEventListRoute>(
      path: AppPaths.timeline,
      routes: [
        TypedGoRoute<TimelineEventEditRoute>(path: AppPaths.timelineEventEdit),
      ],
    ),
    TypedGoRoute<SessionListRoute>(path: AppPaths.sessions),
  ],
)
class AppShellRoute extends ShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return ScaffoldWithNav(child: navigator);
  }
}
