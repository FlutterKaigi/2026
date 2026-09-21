import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/remote_config/event_features_provider.dart';
import 'package:app/core/ui/not_found_page.dart';
import 'package:app/core/ui/root_scaffold.dart';
import 'package:app/feature/auth/ui/page/account_page.dart';
import 'package:app/feature/auth/ui/page/email_sign_in_page.dart';
import 'package:app/feature/event/ui/page/event_info_page.dart';
import 'package:app/feature/exchange/ui/page/exchange_home_page.dart';
import 'package:app/feature/exchange/ui/page/exchange_list_page.dart';
import 'package:app/feature/exchange/ui/page/exchange_scan_page.dart';
import 'package:app/feature/exchange/ui/page/exchange_share_link_page.dart';
import 'package:app/feature/license/ui/page/license_detail_page.dart';
import 'package:app/feature/license/ui/page/license_page.dart';
import 'package:app/feature/mission/ui/page/mission_page.dart';
import 'package:app/feature/news/ui/page/news_list_page.dart';
import 'package:app/feature/profile/ui/page/profile_edit_page.dart';
import 'package:app/feature/quiz/ui/page/quiz_event_list_page.dart';
import 'package:app/feature/quiz/ui/page/quiz_page.dart';
import 'package:app/feature/session/ui/page/bookmarked_sessions_page.dart';
import 'package:app/feature/session/ui/page/session_details_page.dart';
import 'package:app/feature/session/ui/page/session_search_page.dart';
import 'package:app/feature/session/ui/page/session_timetable_page.dart';
import 'package:app/feature/settings/ui/page/settings_page.dart';
import 'package:app/feature/sns_post/ui/page/sns_post_page.dart';
import 'package:app/feature/sponsor/ui/page/sponsor_details_page.dart';
import 'package:app/feature/sponsor/ui/page/sponsor_list_page.dart';
import 'package:app/feature/staff/ui/page/staff_member_list_page.dart';
import 'package:app/feature/support_lt/ui/page/support_lt_page.dart';
import 'package:app/feature/venue_map/ui/page/venue_map_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'router.g.dart';
part 'routes.dart';

/// Base path of [ShareLinkRoute] (`/x/:token`).
///
/// トークンが必須の型付きルートからはベースパスだけを安全に取り出せないため
/// (`.location` は必ずトークン付きの値になる)、routes.dart の
/// `@TypedGoRoute(path: '/x/:token')` と同じ値をここに定数で置く。
const _shareLinkBasePath = '/x';

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

  // `redirect` re-reads this on every navigation via `refreshListenable`, so
  // the flag can flip mid-session without rebuilding the GoRouter itself
  // (that would reset the whole navigation stack). Kept as a `ValueNotifier`
  // instead of `ref.watch`ing the provider directly here.
  final eventFeaturesEnabled = ValueNotifier<bool>(ref.read(eventFeaturesEnabledProvider));
  ref.onDispose(eventFeaturesEnabled.dispose);
  ref.listen(eventFeaturesEnabledProvider, (_, next) => eventFeaturesEnabled.value = next);

  // Conference-day destinations hidden behind `event_features_enabled`,
  // including their sub-routes (quiz event detail, exchange scan/list, …).
  final eventFeatureLocations = <String>[
    const MissionRoute().location,
    const QuizListRoute().location,
    const SupportLtRoute().location,
    const ExchangeHomeRoute().location,
    const SnsPostRoute().location,
    // プロフィール交換のシェアリンク `/x/<token>` も塞ぐ。下の判定は完全一致か
    // `'$location/'` の前方一致だけなので、`/xyz` のような無関係なパスには
    // 当たらない。
    _shareLinkBasePath,
  ];

  return GoRouter(
    initialLocation: const EventInfoRoute().location,
    routes: $appRoutes,
    observers: [TalkerRouteObserver(talker)],
    errorBuilder: (context, state) => const NotFoundPage(),
    refreshListenable: eventFeaturesEnabled,
    redirect: (context, state) {
      if (eventFeaturesEnabled.value) {
        return null;
      }
      final path = state.uri.path;
      final isBlocked = eventFeatureLocations.any((location) => path == location || path.startsWith('$location/'));
      return isBlocked ? const AccountRoute().location : null;
    },
  );
});
