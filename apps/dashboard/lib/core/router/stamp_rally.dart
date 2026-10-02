part of 'router.dart';

class StampRallyRoute extends GoRouteData with $StampRallyRoute {
  const StampRallyRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => const StampRallyPage();
}
