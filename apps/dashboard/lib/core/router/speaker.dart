part of 'router.dart';

class SpeakerListRoute extends GoRouteData with $SpeakerListRoute {
  const SpeakerListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => const SpeakerListPage();
}

class SpeakerEditRoute extends GoRouteData with $SpeakerEditRoute {
  const SpeakerEditRoute({this.$extra});

  final Speaker? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => SpeakerEditPage(speaker: $extra);
}
