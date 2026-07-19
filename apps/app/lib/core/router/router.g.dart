// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$appShellRoute, $quizListRoute];

RouteBase get $appShellRoute => StatefulShellRouteData.$route(
  factory: $AppShellRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(path: '/news', factory: $NewsRoute._fromState),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(path: '/info', factory: $EventInfoRoute._fromState),
      ],
    ),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $NewsRoute on GoRouteData {
  static NewsRoute _fromState(GoRouterState state) => const NewsRoute();

  @override
  String get location => GoRouteData.$location('/news');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $EventInfoRoute on GoRouteData {
  static EventInfoRoute _fromState(GoRouterState state) =>
      const EventInfoRoute();

  @override
  String get location => GoRouteData.$location('/info');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $quizListRoute => GoRouteData.$route(
  path: '/quiz',
  factory: $QuizListRoute._fromState,
  routes: [
    GoRouteData.$route(path: ':eventId', factory: $QuizRoute._fromState),
  ],
);

mixin $QuizListRoute on GoRouteData {
  static QuizListRoute _fromState(GoRouterState state) => const QuizListRoute();

  @override
  String get location => GoRouteData.$location('/quiz');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $QuizRoute on GoRouteData {
  static QuizRoute _fromState(GoRouterState state) =>
      QuizRoute(state.pathParameters['eventId']!);

  QuizRoute get _self => this as QuizRoute;

  @override
  String get location =>
      GoRouteData.$location('/quiz/${Uri.encodeComponent(_self.eventId)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
