part of 'router.dart';

/// `/settings` — appearance, language, and app information.
@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SettingsPage();
}

/// Shell hosting the main bottom/rail navigation destinations.
///
/// Uses [StatefulShellRoute.indexedStack] so switching tabs swaps branches
/// instantly (no page transition animation) while preserving each branch's
/// navigation and scroll state.
@TypedStatefulShellRoute<AppShellRoute>(
  branches: [
    TypedStatefulShellBranch<EventInfoBranch>(
      routes: [
        TypedGoRoute<EventInfoRoute>(path: '/info'),
        TypedGoRoute<NewsRoute>(path: '/news'),
        TypedGoRoute<LicenseRoute>(
          path: '/licenses',
          routes: [
            TypedGoRoute<LicenseDetailRoute>(path: ':packageName'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<SessionBranch>(
      routes: [
        TypedGoRoute<SessionTimetableRoute>(
          path: '/sessions',
          routes: [
            TypedGoRoute<SessionSearchRoute>(path: 'search'),
            TypedGoRoute<BookmarkedSessionsRoute>(path: 'bookmarked'),
            TypedGoRoute<SessionDetailsRoute>(path: ':sessionId'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<SponsorBranch>(
      routes: [
        TypedGoRoute<SponsorRoute>(
          path: '/sponsors',
          routes: [TypedGoRoute<SponsorDetailsRoute>(path: ':sponsorKey')],
        ),
      ],
    ),
    TypedStatefulShellBranch<AccountBranch>(
      routes: [
        TypedGoRoute<AccountRoute>(
          path: '/account',
          routes: [TypedGoRoute<EmailSignInRoute>(path: 'email')],
        ),
      ],
    ),
  ],
)
class AppShellRoute extends StatefulShellRouteData {
  const AppShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    final t = Translations.of(context);
    return RootScaffold(
      navigationShell: navigationShell,
      destinations: [
        RootDestination(
          icon: Icons.event_outlined,
          label: t.navigation.info,
        ),
        RootDestination(
          icon: Icons.calendar_today_outlined,
          label: t.navigation.sessions,
        ),
        RootDestination(
          icon: Icons.business_outlined,
          label: t.navigation.sponsors,
        ),
        RootDestination(
          icon: Icons.person_outline,
          label: t.navigation.account,
        ),
      ],
    );
  }
}

/// Branch hosting the event overview and its news destination. Branch order
/// must match the order of
/// [RootScaffold.destinations] built in [AppShellRoute.builder].
class EventInfoBranch extends StatefulShellBranchData {
  const EventInfoBranch();
}

/// Branch hosting the session timetable tab.
class SessionBranch extends StatefulShellBranchData {
  const SessionBranch();
}

/// Branch hosting the sponsors tab.
class SponsorBranch extends StatefulShellBranchData {
  const SponsorBranch();
}

/// Branch hosting the account tab.
class AccountBranch extends StatefulShellBranchData {
  const AccountBranch();
}

/// `/account` — sign-in options while signed out, account info while signed
/// in.
class AccountRoute extends GoRouteData with $AccountRoute {
  const AccountRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const AccountPage();
}

/// `/account/email` — email/password sign-in and account creation.
class EmailSignInRoute extends GoRouteData with $EmailSignInRoute {
  const EmailSignInRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const EmailSignInPage();
}

/// `/news` — the news list opened from the event overview.
class NewsRoute extends GoRouteData with $NewsRoute {
  const NewsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const NewsListPage();
}

/// `/licenses` — bundled OSS packages and their license counts.
class LicenseRoute extends GoRouteData with $LicenseRoute {
  const LicenseRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const OssLicensePage();
}

/// `/licenses/:packageName` — license text for one bundled package.
class LicenseDetailRoute extends GoRouteData with $LicenseDetailRoute {
  const LicenseDetailRoute({required this.packageName});

  final String packageName;

  @override
  Widget build(BuildContext context, GoRouterState state) => LicenseDetailPage(
    packageName: packageName,
  );
}

/// `/sessions` — the session timetable.
class SessionTimetableRoute extends GoRouteData with $SessionTimetableRoute {
  const SessionTimetableRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SessionTimetablePage();
}

/// `/sessions/search` — local search across published sessions.
class SessionSearchRoute extends GoRouteData with $SessionSearchRoute {
  const SessionSearchRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SessionSearchPage();
}

/// `/sessions/bookmarked` — locally bookmarked sessions.
class BookmarkedSessionsRoute extends GoRouteData with $BookmarkedSessionsRoute {
  const BookmarkedSessionsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const BookmarkedSessionsPage();
}

/// `/sessions/:sessionId` — session details.
class SessionDetailsRoute extends GoRouteData with $SessionDetailsRoute {
  const SessionDetailsRoute({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, GoRouterState state) => SessionDetailsPage(sessionId: sessionId);
}

/// `/sponsors` — the sponsor logo wall.
class SponsorRoute extends GoRouteData with $SponsorRoute {
  const SponsorRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SponsorListPage();
}

/// `/sponsors/:sponsorKey` — sponsor details.
class SponsorDetailsRoute extends GoRouteData with $SponsorDetailsRoute {
  const SponsorDetailsRoute({
    required this.sponsorKey,
  });

  final String sponsorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) => SponsorDetailsPage(sponsorKey: sponsorKey);
}

/// `/info` — event and app information.
class EventInfoRoute extends GoRouteData with $EventInfoRoute {
  const EventInfoRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const EventInfoPage();
}
