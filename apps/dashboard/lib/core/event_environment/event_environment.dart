import 'package:dashboard/core/env.dart';
import 'package:dashboard/core/router/paths.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final dashboardFlavorProvider = Provider<Flavor>((_) => Flavor.current);

final eventEnvironmentProvider = NotifierProvider<EventEnvironmentController, Flavor>(EventEnvironmentController.new);

class EventEnvironmentController extends Notifier<Flavor> {
  @override
  Flavor build() => ref.watch(dashboardFlavorProvider);

  void select(Flavor environment) => state = environment;
}

extension EventEnvironmentLabel on Flavor {
  String get label => switch (this) {
    Flavor.dev => 'ローカル',
    Flavor.stg => 'STG',
    Flavor.prod => '本番',
  };
}

bool isEventPath(String path) =>
    path == AppPaths.supportLt || path == AppPaths.quiz || path.startsWith('${AppPaths.quiz}/');

Flavor? parseEventEnvironment(String? value) => Flavor.values.where((flavor) => flavor.name == value).firstOrNull;

String eventLocation(String location, Flavor environment) {
  final uri = Uri.parse(location);
  return uri.replace(queryParameters: {...uri.queryParameters, 'environment': environment.name}).toString();
}

/// Carry the environment into detail, question and projection URLs, including
/// when they are opened in another tab or restored after signing in.
Future<T?> pushEventRoute<T>(BuildContext context, String location) {
  final environment = parseEventEnvironment(GoRouterState.of(context).uri.queryParameters['environment']);
  if (environment == null) throw StateError('操作環境が選択されていません。');
  return context.push<T>(eventLocation(location, environment));
}
