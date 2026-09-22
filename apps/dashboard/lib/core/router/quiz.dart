part of 'router.dart';

class QuizEventListRoute extends GoRouteData with $QuizEventListRoute {
  const QuizEventListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => const EventAdminPage(
    view: EventAdminView.quizEvents,
    child: QuizEventListPage(),
  );
}

class QuizConsoleRoute extends GoRouteData with $QuizConsoleRoute {
  const QuizConsoleRoute(this.eventId);

  final String eventId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => EventAdminPage(
    view: EventAdminView.quizConsole,
    eventId: eventId,
    child: QuizConsolePage(eventId: eventId),
  );
}

class QuizQuestionEditRoute extends GoRouteData with $QuizQuestionEditRoute {
  const QuizQuestionEditRoute(this.eventId, {this.questionId, this.$extra});

  final String eventId;
  final String? questionId;
  final QuizQuestion? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => NoTransitionPage(child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) => EventAdminPage(
    view: EventAdminView.quizQuestion,
    eventId: eventId,
    questionId: questionId ?? $extra?.id,
    child: QuizQuestionEditPage(eventId: eventId, questionId: questionId, question: $extra),
  );
}

@TypedGoRoute<QuizProjectionRoute>(path: '/quiz/:eventId/project')
class QuizProjectionRoute extends GoRouteData with $QuizProjectionRoute {
  const QuizProjectionRoute(this.eventId);

  final String eventId;

  @override
  Widget build(BuildContext context, GoRouterState state) => Scaffold(
    body: EventAdminPage(
      view: EventAdminView.quizProjection,
      eventId: eventId,
      child: QuizProjectionPage(eventId: eventId),
    ),
  );
}
