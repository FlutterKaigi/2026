part of 'router.dart';

/// Shell hosting the main bottom/rail navigation destinations.
@TypedShellRoute<AppShellRoute>(
  routes: [
    TypedGoRoute<NewsRoute>(path: '/news'),
    TypedGoRoute<EventInfoRoute>(path: '/info'),
  ],
)
class AppShellRoute extends ShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    final t = Translations.of(context);
    return RootScaffold(
      navigator: navigator,
      destinations: [
        RootDestination(
          icon: Icons.campaign_outlined,
          label: t.navigation.news,
          location: const NewsRoute().location,
        ),
        RootDestination(
          icon: Icons.info_outline,
          label: t.navigation.info,
          location: const EventInfoRoute().location,
        ),
      ],
    );
  }
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
