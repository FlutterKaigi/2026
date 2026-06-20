part of 'router.dart';

@TypedShellRoute<AppShellRoute>(
  routes: [
    TypedGoRoute<HomeRoute>(path: AppPaths.home),
    TypedGoRoute<NewsListRoute>(path: AppPaths.news),
    TypedGoRoute<VenueListRoute>(path: AppPaths.venues),
    TypedGoRoute<SpeakerListRoute>(path: AppPaths.speakers),
    TypedGoRoute<StaffMemberListRoute>(path: AppPaths.staff),
    TypedGoRoute<TimelineEventListRoute>(path: AppPaths.timeline),
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
