part of 'router.dart';

class QuizEventListRoute extends GoRouteData with $QuizEventListRoute {
  const QuizEventListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => const QuizEventListPage();
}

class QuizConsoleRoute extends GoRouteData with $QuizConsoleRoute {
  const QuizConsoleRoute(this.eventId);

  final String eventId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => QuizConsolePage(eventId: eventId);
}

class QuizQuestionEditRoute extends GoRouteData with $QuizQuestionEditRoute {
  const QuizQuestionEditRoute(this.eventId, {this.$extra});

  final String eventId;
  final QuizQuestion? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => QuizQuestionEditPage(eventId: eventId, question: $extra);
}
