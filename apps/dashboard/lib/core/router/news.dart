part of 'router.dart';

class NewsListRoute extends GoRouteData with $NewsListRoute {
  const NewsListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => const NewsListPage();
}

class NewsEditRoute extends GoRouteData with $NewsEditRoute {
  const NewsEditRoute({this.$extra});

  final News? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => NewsEditPage(news: $extra);
}
