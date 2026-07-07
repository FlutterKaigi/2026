import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/log/talker.dart';
import 'package:app/core/ui/not_found_page.dart';
import 'package:app/core/ui/root_scaffold.dart';
import 'package:app/feature/event/ui/page/event_info_page.dart';
import 'package:app/feature/news/ui/page/news_list_page.dart';
import 'package:app/feature/session/ui/page/session_timetable_page.dart';
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
  return GoRouter(
    initialLocation: const NewsRoute().location,
    routes: $appRoutes,
    observers: [TalkerRouteObserver(talker)],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
});
