import 'package:dashboard/core/env.dart';
import 'package:dashboard/core/event_environment/event_admin_client.dart';
import 'package:dashboard/core/event_environment/event_admin_repositories.dart';
import 'package:dashboard/core/event_environment/event_environment.dart';
import 'package:dashboard/core/router/paths.dart';
import 'package:dashboard/feature/auth/data/provider/auth_repository.dart';
import 'package:dashboard/feature/auth/data/provider/auth_state.dart';
import 'package:dashboard/feature/quiz/data/provider/quiz_repository.dart';
import 'package:dashboard/feature/quiz/ui/component/quiz_countdown.dart';
import 'package:dashboard/feature/sponsor/data/provider/sponsor_repository.dart';
import 'package:dashboard/feature/support_lt/data/provider/support_lt_state.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum EventAdminView { supportLt, quizEvents, quizConsole, quizQuestion, quizProjection }

class EventAdminPage extends ConsumerWidget {
  const EventAdminPage({super.key, required this.view, required this.child, this.eventId, this.questionId});

  final EventAdminView view;
  final String? eventId;
  final String? questionId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = GoRouterState.of(context).uri;
    final environment = parseEventEnvironment(uri.queryParameters['environment']);
    final source = ref.watch(dashboardFlavorProvider);
    final allowed = source == Flavor.dev ? [Flavor.dev] : [Flavor.stg, Flavor.prod];
    final auth = ref.watch(authStateProvider);
    final user = auth.asData?.value;
    if (auth.isLoading) return const Center(child: CircularProgressIndicator());
    if (user == null) return const Center(child: Text('サインインしてください。'));
    if (environment == null || !allowed.contains(environment)) {
      return const Center(child: Text('操作環境が不正です。メニューから開き直してください。'));
    }
    final scheme = Theme.of(context).colorScheme;
    final projection = view == EventAdminView.quizProjection;
    return Column(
      children: [
        ColoredBox(
          color: environment == Flavor.prod ? scheme.errorContainer : scheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(projection ? '表示環境: ${environment.label}' : '操作環境'),
                if (!projection) ...[
                  const SizedBox(width: 12),
                  DropdownButton<Flavor>(
                    key: const Key('event-environment-selector'),
                    value: environment,
                    items: [for (final item in allowed) DropdownMenuItem(value: item, child: Text(item.label))],
                    onChanged: (next) {
                      if (next == null || next == environment) return;
                      ref.read(eventEnvironmentProvider.notifier).select(next);
                      final listPath = view == EventAdminView.supportLt ? AppPaths.supportLt : AppPaths.quiz;
                      context.go(eventLocation(listPath, next));
                    },
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    projection ? '' : '${environment.label}のイベントを操作中',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _EventAdminScope(
            key: ValueKey((environment, view, eventId, questionId, user.uid)),
            environment: environment,
            view: {'view': view.name, 'eventId': ?eventId, 'questionId': ?questionId},
            auth: ref.watch(authRepositoryProvider),
            request: ref.watch(eventAdminRequestProvider),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _EventAdminScope extends StatefulWidget {
  const _EventAdminScope({
    super.key,
    required this.environment,
    required this.view,
    required this.auth,
    required this.request,
    required this.child,
  });
  final Flavor environment;
  final Map<String, dynamic> view;
  final AuthRepository auth;
  final EventAdminRequest request;
  final Widget child;

  @override
  State<_EventAdminScope> createState() => _EventAdminScopeState();
}

class _EventAdminScopeState extends State<_EventAdminScope> {
  late final EventAdminClient _client;
  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    _client = EventAdminClient(environment: widget.environment, view: widget.view, request: widget.request);
    _container = ProviderContainer(
      overrides: [
        eventAdminClientProvider.overrideWithValue(_client),
        authRepositoryProvider.overrideWithValue(widget.auth),
        supportLtRepositoryProvider.overrideWithValue(AdminSupportLtRepository(_client)),
        quizEventRepositoryProvider.overrideWithValue(AdminQuizEventRepository(_client)),
        quizParticipantRepositoryProvider.overrideWithValue(AdminQuizParticipantRepository(_client)),
        quizTeamRepositoryProvider.overrideWithValue(AdminQuizTeamRepository(_client)),
        quizQuestionRepositoryProvider.overrideWithValue(AdminQuizQuestionRepository(_client)),
        quizAnswerRepositoryProvider.overrideWithValue(AdminQuizAnswerRepository(_client)),
        quizOperationsRepositoryProvider.overrideWithValue(AdminQuizOperationsRepository(_client)),
        quizClockRepositoryProvider.overrideWithValue(AdminQuizClockRepository(_client)),
        sponsorRepositoryProvider.overrideWithValue(AdminQuizSponsorRepository(_client)),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _client.setActive(TickerMode.valuesOf(context).enabled);
  }

  @override
  void dispose() {
    _container.dispose();
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(container: _container, child: widget.child);
}
