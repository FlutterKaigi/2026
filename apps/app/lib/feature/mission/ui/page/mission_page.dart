import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/widget/app_error_view.dart';
import 'package:app/core/ui/widget/app_scrollbar.dart';
import 'package:app/feature/auth/data/provider/auth_state.dart';
import 'package:app/feature/auth/ui/widget/sign_in_card.dart';
import 'package:app/feature/exchange/data/provider/profile_exchange_provider.dart';
import 'package:app/feature/mission/data/mission_provider.dart';
import 'package:app/feature/sns_post/data/sns_post_provider.dart';
import 'package:app/feature/sns_post/ui/sns_post_companion_label.dart';
import 'package:app/feature/support_lt/data/provider/support_lt_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MissionPage extends ConsumerWidget {
  const MissionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.mission.title)),
      body: switch (ref.watch(authStateChangesProvider)) {
        AsyncData(value: null) => _PageContent(
          child: SignInCard(title: t.auth.signIn.required, description: t.mission.signInRequired),
        ),
        AsyncData(:final value?) => _MissionBody(
          key: ValueKey(value.uid),
          uid: value.uid,
          displayName: value.displayName,
        ),
        AsyncError(:final error) => AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(authStateChangesProvider),
        ),
        _ => const Center(child: CircularProgressIndicator.adaptive()),
      },
    );
  }
}

enum _Status {
  complete,
  incomplete,
  loading,
  error;

  static _Status from<T>(AsyncValue<T> value, bool Function(T) isComplete) => switch (value) {
    AsyncData(:final value) => isComplete(value) ? complete : incomplete,
    AsyncError() => error,
    _ => loading,
  };

  String label(Translations t) => switch (this) {
    complete => t.mission.complete,
    incomplete => t.mission.incomplete,
    loading => t.mission.loading,
    error => t.mission.loadFailed,
  };
}

class _MissionBody extends ConsumerWidget {
  const _MissionBody({required this.uid, required this.displayName, super.key});

  final String uid;
  final String? displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final lt = ref.watch(supportLtRegistrationProvider(uid));
    final exchanges = ref.watch(missionExchangeProgressProvider(uid));
    final sns = ref.watch(snsPostRegistrationProvider(uid));
    final ltStatus = _Status.from(lt, (value) => value != null);
    final exchangeStatus = _Status.from(exchanges, (value) => value.isComplete);
    final snsStatus = _Status.from(sns, (value) => value != null);
    final statuses = [ltStatus, exchangeStatus, snsStatus];
    final count = statuses.where((status) => status == _Status.complete).length;
    final profile = ref.watch(exchangedUserProfileProvider(uid));
    final progress = exchanges.asData?.value;
    final post = sns.asData?.value;

    void retryExchange() {
      final entries = ref.read(missionExchangesProvider(uid)).value ?? [];
      for (final entry in entries) {
        ref.invalidate(exchangedUserProfileProvider(entry.id));
      }
      ref.invalidate(exchangedUserProfileProvider(uid));
      ref.invalidate(missionExchangesProvider(uid));
    }

    return _PageContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryCard(
            count: count,
            name: profile.asData?.value?.displayName ?? displayName,
            hasError: statuses.contains(_Status.error),
            isLoading: statuses.contains(_Status.loading),
          ),
          const SizedBox(height: 16),
          _MissionCard(
            key: const ValueKey('mission-lt'),
            icon: Icons.mic_none_outlined,
            title: t.mission.ltTitle,
            description: t.mission.ltDescription,
            status: ltStatus,
            onTap: () => const SupportLtRoute().push<void>(context),
            onRetry: () => ref.invalidate(supportLtRegistrationProvider(uid)),
          ),
          const SizedBox(height: 10),
          _MissionCard(
            key: const ValueKey('mission-exchange'),
            icon: Icons.people_outline,
            title: t.mission.exchangeTitle,
            description: t.mission.exchangeDescription,
            status: exchangeStatus,
            onTap: () => const ExchangeHomeRoute().push<void>(context),
            onRetry: retryExchange,
            detail: progress == null
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Condition(
                        complete: progress.count >= 3,
                        text: t.mission.exchangeCount(n: progress.count),
                      ),
                      const SizedBox(height: 4),
                      _Condition(complete: progress.hasDifferentCountry, text: t.mission.differentCountry),
                      if (!progress.hasProfile)
                        TextButton(
                          onPressed: () => const ProfileEditRoute().push<void>(context),
                          child: Text(t.mission.profileRequired),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          _MissionCard(
            key: const ValueKey('mission-sns'),
            icon: Icons.add_photo_alternate_outlined,
            title: t.mission.snsTitle,
            description: post == null ? t.mission.snsDescription : snsPostCompanionLabel(t, post.companion),
            status: snsStatus,
            onTap: () => const SnsPostRoute().push<void>(context),
            onRetry: () => ref.invalidate(snsPostRegistrationProvider(uid)),
          ),
          const SizedBox(height: 16),
          Text(t.mission.presentationHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

Color _successColor(ThemeData theme) =>
    theme.brightness == Brightness.dark ? const Color(0xFF83DBAC) : const Color(0xFF18784B);

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.count, required this.name, required this.hasError, required this.isLoading});

  final int count;
  final String? name;
  final bool hasError;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final complete = count == 3;
    final color = complete ? _successColor(theme) : theme.colorScheme.primary;
    return Semantics(
      container: true,
      child: Container(
        key: const ValueKey('mission-summary'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (name != null && name!.isNotEmpty) ...[
              Text(name!, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$count / 3',
                      style: theme.textTheme.displaySmall?.copyWith(color: color, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                if (complete) Icon(Icons.verified_outlined, size: 36, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              complete
                  ? t.mission.allComplete
                  : hasError
                  ? t.mission.checkFailed
                  : isLoading
                  ? t.mission.loading
                  : t.mission.inProgress,
              style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: count / 3,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
              semanticsLabel: t.mission.progress(n: count),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onTap,
    required this.onRetry,
    this.detail,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final _Status status;
  final VoidCallback onTap;
  final VoidCallback onRetry;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final complete = status == _Status.complete;
    final color = complete ? _successColor(theme) : theme.colorScheme.onSurfaceVariant;
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      semanticContainer: false,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            complete
                                ? Icons.check_circle
                                : status == _Status.error
                                ? Icons.error_outline
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status.label(t),
                            style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              if (detail != null) ...[const SizedBox(height: 10), detail!],
              if (status == _Status.error)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: onRetry, child: Text(t.error.retry)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Condition extends StatelessWidget {
  const _Condition({required this.complete, required this.text});

  final bool complete;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = complete ? _successColor(theme) : theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(complete ? Icons.check_circle_outline : Icons.radio_button_unchecked, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color)),
        ),
      ],
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AppScrollbar(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: child),
      ),
    ),
  );
}
