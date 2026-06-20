import 'package:dashboard/core/router/paths.dart';
import 'package:dashboard/core/ui/scaffold_with_nav.dart';
import 'package:dashboard/feature/auth/data/provider/auth_state.dart';
import 'package:dashboard/feature/auth/ui/auth/page/login_page.dart';
import 'package:dashboard/feature/auth/ui/home/page/home_page.dart';
import 'package:dashboard/feature/news/ui/page/news_edit_page.dart';
import 'package:dashboard/feature/news/ui/page/news_list_page.dart';
import 'package:data/news.dart';
import 'package:dashboard/feature/session/ui/page/session_list_page.dart';
import 'package:dashboard/feature/speaker/ui/page/speaker_list_page.dart';
import 'package:dashboard/feature/staff_member/ui/page/staff_member_list_page.dart';
import 'package:dashboard/feature/timeline_event/ui/page/timeline_event_list_page.dart';
import 'package:dashboard/feature/venue/ui/page/venue_list_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'router.g.dart';
part 'auth.dart';
part 'home.dart';
part 'shell.dart';
part 'news.dart';
part 'venue.dart';
part 'speaker.dart';
part 'staff_member.dart';
part 'timeline_event.dart';
part 'session.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final initial = ref.read(authStateProvider);
  final isLoggedInNotifier = ValueNotifier<bool>(initial.value != null);
  final isLoadingNotifier = ValueNotifier<bool>(initial.isLoading);

  ref
    ..listen(authStateProvider, (_, _) {
      final next = ref.read(authStateProvider);
      isLoadingNotifier.value = next.isLoading;
      isLoggedInNotifier.value = next.value != null;
    })
    ..onDispose(() {
      isLoggedInNotifier.dispose();
      isLoadingNotifier.dispose();
    });

  return GoRouter(
    refreshListenable: Listenable.merge([isLoggedInNotifier, isLoadingNotifier]),
    redirect: (context, state) {
      if (isLoadingNotifier.value) return null;

      final isLoggedIn = isLoggedInNotifier.value;
      final loc = state.matchedLocation;
      final loginLocation = const LoginRoute().location;
      final homeLocation = const HomeRoute().location;

      if (!isLoggedIn) return loc == loginLocation ? null : loginLocation;
      if (loc == loginLocation) return homeLocation;
      return null;
    },
    routes: $appRoutes,
  );
});
