part of 'router.dart';

class SessionListRoute extends GoRouteData with $SessionListRoute {
  const SessionListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => const SessionListPage();
}

class SessionEditRoute extends GoRouteData with $SessionEditRoute {
  const SessionEditRoute({this.$extra});

  final Session? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => SessionEditPage(session: $extra);
}
