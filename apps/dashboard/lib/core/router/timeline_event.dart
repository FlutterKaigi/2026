part of 'router.dart';

class TimelineEventListRoute extends GoRouteData with $TimelineEventListRoute {
  const TimelineEventListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => const TimelineEventListPage();
}

class TimelineEventEditRoute extends GoRouteData with $TimelineEventEditRoute {
  const TimelineEventEditRoute({this.$extra});

  final TimelineEvent? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => TimelineEventEditPage(timelineEvent: $extra);
}
