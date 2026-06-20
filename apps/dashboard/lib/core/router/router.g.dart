// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$loginRoute, $appShellRoute];

RouteBase get $loginRoute =>
    GoRouteData.$route(path: '/login', factory: $LoginRoute._fromState);

mixin $LoginRoute on GoRouteData {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  @override
  String get location => GoRouteData.$location('/login');

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

RouteBase get $appShellRoute => ShellRouteData.$route(
  factory: $AppShellRouteExtension._fromState,
  routes: [
    GoRouteData.$route(path: '/', factory: $HomeRoute._fromState),
    GoRouteData.$route(path: '/news', factory: $NewsListRoute._fromState),
    GoRouteData.$route(path: '/venues', factory: $VenueListRoute._fromState),
    GoRouteData.$route(
      path: '/speakers',
      factory: $SpeakerListRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/staff',
      factory: $StaffMemberListRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/timeline',
      factory: $TimelineEventListRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/sessions',
      factory: $SessionListRoute._fromState,
    ),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/');

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

mixin $NewsListRoute on GoRouteData {
  static NewsListRoute _fromState(GoRouterState state) => const NewsListRoute();

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

mixin $VenueListRoute on GoRouteData {
  static VenueListRoute _fromState(GoRouterState state) =>
      const VenueListRoute();

  @override
  String get location => GoRouteData.$location('/venues');

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

mixin $SpeakerListRoute on GoRouteData {
  static SpeakerListRoute _fromState(GoRouterState state) =>
      const SpeakerListRoute();

  @override
  String get location => GoRouteData.$location('/speakers');

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

mixin $StaffMemberListRoute on GoRouteData {
  static StaffMemberListRoute _fromState(GoRouterState state) =>
      const StaffMemberListRoute();

  @override
  String get location => GoRouteData.$location('/staff');

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

mixin $TimelineEventListRoute on GoRouteData {
  static TimelineEventListRoute _fromState(GoRouterState state) =>
      const TimelineEventListRoute();

  @override
  String get location => GoRouteData.$location('/timeline');

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

mixin $SessionListRoute on GoRouteData {
  static SessionListRoute _fromState(GoRouterState state) =>
      const SessionListRoute();

  @override
  String get location => GoRouteData.$location('/sessions');

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
