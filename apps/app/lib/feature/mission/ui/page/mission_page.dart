import 'package:app/core/designsystem/theme/app_gradients.dart';
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
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.mission.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: switch (ref.watch(authStateChangesProvider)) {
        AsyncData(value: null) => _PageContent(
          child: SignInCard(title: t.auth.signIn.required, description: t.mission.signInRequired),
        ),
        AsyncData(:final value?) => _MissionBody(key: ValueKey(value.uid), uid: value.uid),
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
  const _MissionBody({required this.uid, super.key});

  final String uid;

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
          _SummaryCard(statuses: statuses),
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
            description: progress == null ? t.mission.exchangeDescription : null,
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
                      const SizedBox(height: 6),
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
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.statuses});

  final List<_Status> statuses;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final count = statuses.where((status) => status == _Status.complete).length;
    final complete = count == 3;
    final summary = complete
        ? t.mission.allComplete
        : statuses.contains(_Status.error)
        ? t.mission.checkFailed
        : statuses.contains(_Status.loading)
        ? t.mission.loading
        : t.mission.inProgress;
    return Semantics(
      container: true,
      child: Card.outlined(
        key: const ValueKey('mission-summary'),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(gradient: AppGradients.brand),
              // Keep white text readable over the magenta end of the artwork.
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$count / 3',
                                  semanticsLabel: t.mission.progress(n: count),
                                  style: theme.textTheme.displayMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  summary,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Image.asset(
                            'res/assets/shuriken-logo.png',
                            width: 96,
                            height: 96,
                            excludeFromSemantics: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ExcludeSemantics(
                        child: Row(
                          children: [
                            for (var index = 0; index < statuses.length; index++) ...[
                              if (index > 0) const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statuses[index] == _Status.complete
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.24),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
  final String? description;
  final _Status status;
  final VoidCallback onTap;
  final VoidCallback onRetry;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final complete = status == _Status.complete;
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      semanticContainer: false,
      color: complete ? colors.surfaceContainerLow : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: complete ? colors.primary.withValues(alpha: 0.35) : colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: complete ? colors.primaryContainer : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: complete ? colors.onPrimaryContainer : colors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: status),
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(description!, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
              ],
              if (detail != null) ...[const SizedBox(height: 10), detail!],
              if (status == _Status.error)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: onRetry, child: Text(Translations.of(context).error.retry)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _Status status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (background, foreground, icon) = switch (status) {
      _Status.complete => (colors.primaryContainer, colors.onPrimaryContainer, Icons.check_circle),
      _Status.incomplete => (colors.surfaceContainerHighest, colors.onSurfaceVariant, Icons.radio_button_unchecked),
      _Status.loading => (colors.tertiaryContainer, colors.onTertiaryContainer, Icons.hourglass_top_rounded),
      _Status.error => (colors.errorContainer, colors.onErrorContainer, Icons.error_outline),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 4),
            Text(
              status.label(Translations.of(context)),
              style: theme.textTheme.labelMedium?.copyWith(color: foreground, fontWeight: FontWeight.w700),
            ),
          ],
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
    final color = complete ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
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
