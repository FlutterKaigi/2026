part of 'router.dart';

class SponsorListRoute extends GoRouteData with $SponsorListRoute {
  const SponsorListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => const SponsorListPage();
}

class SponsorEditRoute extends GoRouteData with $SponsorEditRoute {
  const SponsorEditRoute({this.$extra});

  final Sponsor? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => SponsorEditPage(sponsor: $extra);
}
