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
    GoRouteData.$route(
      path: '/news',
      factory: $NewsListRoute._fromState,
      routes: [
        GoRouteData.$route(path: 'edit', factory: $NewsEditRoute._fromState),
      ],
    ),
    GoRouteData.$route(
      path: '/venues',
      factory: $VenueListRoute._fromState,
      routes: [
        GoRouteData.$route(path: 'edit', factory: $VenueEditRoute._fromState),
      ],
    ),
    GoRouteData.$route(
      path: '/speakers',
      factory: $SpeakerListRoute._fromState,
      routes: [
        GoRouteData.$route(path: 'edit', factory: $SpeakerEditRoute._fromState),
      ],
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

mixin $NewsEditRoute on GoRouteData {
  static NewsEditRoute _fromState(GoRouterState state) =>
      NewsEditRoute($extra: state.extra as News?);

  NewsEditRoute get _self => this as NewsEditRoute;

  @override
  String get location => GoRouteData.$location('/news/edit');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
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

mixin $VenueEditRoute on GoRouteData {
  static VenueEditRoute _fromState(GoRouterState state) =>
      VenueEditRoute($extra: state.extra as Venue?);

  VenueEditRoute get _self => this as VenueEditRoute;

  @override
  String get location => GoRouteData.$location('/venues/edit');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
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

mixin $SpeakerEditRoute on GoRouteData {
  static SpeakerEditRoute _fromState(GoRouterState state) =>
      SpeakerEditRoute($extra: state.extra as Speaker?);

  SpeakerEditRoute get _self => this as SpeakerEditRoute;

  @override
  String get location => GoRouteData.$location('/speakers/edit');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
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
