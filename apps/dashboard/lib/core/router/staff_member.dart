part of 'router.dart';

class StaffMemberListRoute extends GoRouteData with $StaffMemberListRoute {
  const StaffMemberListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => const StaffMemberListPage();
}
