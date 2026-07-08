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

/// `/info` — event and app information.
class EventInfoRoute extends GoRouteData with $EventInfoRoute {
  const EventInfoRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const EventInfoPage();
}

/// `/quiz` — the quiz event screen.
///
/// Lives outside [AppShellRoute] so it is a full-screen page (no bottom
/// navigation). Entered by pushing from the event info page, so the app bar
/// back button returns there.
@TypedGoRoute<QuizRoute>(path: '/quiz')
class QuizRoute extends GoRouteData with $QuizRoute {
  const QuizRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const QuizPage();
}
