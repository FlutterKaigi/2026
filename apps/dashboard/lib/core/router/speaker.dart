part of 'router.dart';

class SpeakerListRoute extends GoRouteData with $SpeakerListRoute {
  const SpeakerListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => const SpeakerListPage();
}
