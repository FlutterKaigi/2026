part of 'router.dart';

class SupportLtRoute extends GoRouteData with $SupportLtRoute {
  const SupportLtRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => const SupportLtPage();
}
