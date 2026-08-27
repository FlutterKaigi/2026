// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$settingsRoute, $appShellRoute];

RouteBase get $settingsRoute => GoRouteData.$route(path: '/settings', factory: $SettingsRoute._fromState);

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $appShellRoute => StatefulShellRouteData.$route(
  factory: $AppShellRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/info',
          factory: $EventInfoRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'staff',
              factory: $StaffMemberListRoute._fromState,
            ),
          ],
        ),
        GoRouteData.$route(path: '/news', factory: $NewsRoute._fromState),
        GoRouteData.$route(
          path: '/licenses',
          factory: $LicenseRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: ':packageName',
              factory: $LicenseDetailRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/sessions',
          factory: $SessionTimetableRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'search',
              factory: $SessionSearchRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'bookmarked',
              factory: $BookmarkedSessionsRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':sessionId',
              factory: $SessionDetailsRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/sponsors',
          factory: $SponsorRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: ':sponsorKey',
              factory: $SponsorDetailsRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/account',
          factory: $AccountRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'email',
              factory: $EmailSignInRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'profile',
              factory: $ProfileEditRoute._fromState,
            ),
          ],
        ),
      ],
    ),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $EventInfoRoute on GoRouteData {
  static EventInfoRoute _fromState(GoRouterState state) => const EventInfoRoute();

  @override
  String get location => GoRouteData.$location('/info');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $StaffMemberListRoute on GoRouteData {
  static StaffMemberListRoute _fromState(GoRouterState state) => const StaffMemberListRoute();

  @override
  String get location => GoRouteData.$location('/info/staff');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
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
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $LicenseRoute on GoRouteData {
  static LicenseRoute _fromState(GoRouterState state) => const LicenseRoute();

  @override
  String get location => GoRouteData.$location('/licenses');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $LicenseDetailRoute on GoRouteData {
  static LicenseDetailRoute _fromState(GoRouterState state) =>
      LicenseDetailRoute(packageName: state.pathParameters['packageName']!);

  LicenseDetailRoute get _self => this as LicenseDetailRoute;

  @override
  String get location => GoRouteData.$location(
    '/licenses/${Uri.encodeComponent(_self.packageName)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SessionTimetableRoute on GoRouteData {
  static SessionTimetableRoute _fromState(GoRouterState state) => const SessionTimetableRoute();

  @override
  String get location => GoRouteData.$location('/sessions');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SessionSearchRoute on GoRouteData {
  static SessionSearchRoute _fromState(GoRouterState state) => const SessionSearchRoute();

  @override
  String get location => GoRouteData.$location('/sessions/search');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $BookmarkedSessionsRoute on GoRouteData {
  static BookmarkedSessionsRoute _fromState(GoRouterState state) => const BookmarkedSessionsRoute();

  @override
  String get location => GoRouteData.$location('/sessions/bookmarked');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SessionDetailsRoute on GoRouteData {
  static SessionDetailsRoute _fromState(GoRouterState state) =>
      SessionDetailsRoute(sessionId: state.pathParameters['sessionId']!);

  SessionDetailsRoute get _self => this as SessionDetailsRoute;

  @override
  String get location => GoRouteData.$location(
    '/sessions/${Uri.encodeComponent(_self.sessionId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SponsorRoute on GoRouteData {
  static SponsorRoute _fromState(GoRouterState state) => const SponsorRoute();

  @override
  String get location => GoRouteData.$location('/sponsors');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SponsorDetailsRoute on GoRouteData {
  static SponsorDetailsRoute _fromState(GoRouterState state) =>
      SponsorDetailsRoute(sponsorKey: state.pathParameters['sponsorKey']!);

  SponsorDetailsRoute get _self => this as SponsorDetailsRoute;

  @override
  String get location => GoRouteData.$location(
    '/sponsors/${Uri.encodeComponent(_self.sponsorKey)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountRoute on GoRouteData {
  static AccountRoute _fromState(GoRouterState state) => const AccountRoute();

  @override
  String get location => GoRouteData.$location('/account');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $EmailSignInRoute on GoRouteData {
  static EmailSignInRoute _fromState(GoRouterState state) => const EmailSignInRoute();

  @override
  String get location => GoRouteData.$location('/account/email');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ProfileEditRoute on GoRouteData {
  static ProfileEditRoute _fromState(GoRouterState state) => const ProfileEditRoute();

  @override
  String get location => GoRouteData.$location('/account/profile');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) => context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
