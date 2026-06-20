part of 'router.dart';

class VenueListRoute extends GoRouteData with $VenueListRoute {
  const VenueListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => const VenueListPage();
}
