import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/ui/not_found_page.dart';
import 'package:app/core/ui/root_scaffold.dart';
import 'package:app/feature/auth/ui/page/account_page.dart';
import 'package:app/feature/auth/ui/page/email_sign_in_page.dart';
import 'package:app/feature/event/ui/page/event_info_page.dart';
import 'package:app/feature/license/ui/page/license_detail_page.dart';
import 'package:app/feature/license/ui/page/license_page.dart';
import 'package:app/feature/news/ui/page/news_list_page.dart';
import 'package:app/feature/profile/ui/page/profile_edit_page.dart';
import 'package:app/feature/quiz/ui/page/quiz_event_list_page.dart';
import 'package:app/feature/quiz/ui/page/quiz_page.dart';
import 'package:app/feature/session/ui/page/bookmarked_sessions_page.dart';
import 'package:app/feature/session/ui/page/session_details_page.dart';
import 'package:app/feature/session/ui/page/session_search_page.dart';
import 'package:app/feature/session/ui/page/session_timetable_page.dart';
import 'package:app/feature/settings/ui/page/settings_page.dart';
import 'package:app/feature/sponsor/ui/page/sponsor_details_page.dart';
import 'package:app/feature/sponsor/ui/page/sponsor_list_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'router.g.dart';
part 'routes.dart';

/// Provides the application [GoRouter].
///
/// Routes are declared with `go_router_builder` typed routes in `routes.dart`;
/// add new destinations there and regenerate with `melos gen`.
final routerProvider = Provider<GoRouter>((ref) {
  final talker = ref.watch(talkerProvider);

  // Session details and bookmarks are opened with `push` so native back
  // navigation returns to the exact previous screen. go_router ignores
  // imperative matches in the browser URL by default, even when the target is
  // a declared deep link. All imperative destinations in this app are declared
  // routes, so reflecting the top-most match keeps web URLs shareable without
  // sacrificing the navigation stack.
  GoRouter.optionURLReflectsImperativeAPIs = true;

  return GoRouter(
    initialLocation: const EventInfoRoute().location,
    routes: $appRoutes,
    observers: [TalkerRouteObserver(talker)],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
});
