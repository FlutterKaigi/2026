part of 'router.dart';

class VenueListRoute extends GoRouteData with $VenueListRoute {
  const VenueListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => const VenueListPage();
}

class VenueEditRoute extends GoRouteData with $VenueEditRoute {
  const VenueEditRoute({this.$extra});

  final Venue? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => VenueEditPage(venue: $extra);
}
