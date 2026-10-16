import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/constants/event_schedule.dart';
import 'package:app/core/designsystem/theme/app_gradients.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/clock.dart';
import 'package:app/core/router/router.dart';
import 'package:app/feature/event_guide/data/event_guide_seen_provider.dart';
import 'package:app/feature/push_notification/data/push_notification_provider.dart';
import 'package:app/feature/venue_events/ui/venue_event_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum _GuideStep {
  welcome,
  sessions,
  venueEvents,
  quiz;

  bool get isFirst => index == 0;

  bool get isLast => index == values.length - 1;

  String title(Translations t) => switch (this) {
    welcome => t.eventGuide.welcome.title,
    sessions => t.eventGuide.sessions.title,
    venueEvents => t.eventGuide.venueEvents.title,
    quiz => t.eventGuide.quiz.title,
  };

  String body(Translations t) => switch (this) {
    welcome => t.eventGuide.welcome.body,
    sessions => t.eventGuide.sessions.body,
    venueEvents => t.eventGuide.venueEvents.body,
    quiz => t.eventGuide.quiz.body,
  };
}

/// Counts the mounted guide pages, including one still in its exit transition.
/// go_router drops a closing guide from its configuration as soon as that
/// transition starts, and a link can open a second guide before the first one
/// is disposed.
///
/// A mutable box rather than provider state, because the pages update it while
/// they are disposed, when Riverpod rejects changes.
final class EventGuidePresence {
  var _mounted = 0;

  bool get onScreen => _mounted > 0;

  void enter() => _mounted++;

  /// Whether the page that left was the last guide on screen.
  bool leave() => --_mounted == 0;
}

final eventGuidePresenceProvider = Provider((ref) => EventGuidePresence());

class EventGuidePage extends HookConsumerWidget {
  const EventGuidePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = usePageController();
    final pushNotifications = ref.watch(pushNotificationRepositoryProvider);
    final presence = ref.watch(eventGuidePresenceProvider);
    useEffect(() {
      presence.enter();
      if (isEventGuideWindow(ref.read(clockProvider)())) {
        final seen = ref.read(eventGuideSeenProvider.notifier);
        WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(seen.markSeen()));
      }
      // The OS prompt waits until the last guide has gone, however it was
      // closed.
      return () {
        if (presence.leave()) {
          unawaited(pushNotifications.requestPermission());
        }
      };
    }, const []);
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: controller,
          children: [
            for (final step in _GuideStep.values) _StepView(step: step, controller: controller),
          ],
        ),
      ),
    );
  }
}

const _pageTurn = Duration(milliseconds: 300);
const _designScreenWidth = 390.0;
const _panelMargin = 16.0;
const _panelPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 24);

void _close(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  } else {
    const EventInfoRoute().go(context);
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step, required this.controller});

  final _GuideStep step;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    if (!step.isFirst)
                      IconButton(
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        color: colors.onSurfaceVariant,
                        onPressed: () => unawaited(controller.previousPage(duration: _pageTurn, curve: Curves.easeOut)),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    const Spacer(),
                    if (!step.isLast) TextButton(onPressed: () => _close(context), child: Text(t.eventGuide.skip)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      children: [
                        Flexible(
                          child: _IllustrationPanel(
                            decoration: step == _GuideStep.welcome
                                ? const BoxDecoration(gradient: AppGradients.brand)
                                : BoxDecoration(color: colors.surfaceContainer),
                            child: switch (step) {
                              _GuideStep.welcome => Center(
                                child: Image.asset(
                                  'res/assets/shuriken-logo.png',
                                  width: 240,
                                  height: 240,
                                  fit: BoxFit.contain,
                                  excludeFromSemantics: true,
                                ),
                              ),
                              _GuideStep.sessions => const _SessionsIllustration(),
                              _GuideStep.venueEvents => const _VenueEventsIllustration(),
                              _GuideStep.quiz => const _QuizIllustration(),
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                          child: Column(
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  step.title(t),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                step.body(t),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageDots(current: step.index, count: _GuideStep.values.length),
                  const SizedBox(height: 16),
                  if (step.isLast) ...[
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: () => const VenueEventsRoute().go(context),
                      child: Text(t.venueEvents.title, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: () => _close(context),
                      child: Text(t.eventGuide.close, textAlign: TextAlign.center),
                    ),
                  ] else
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: () => unawaited(controller.nextPage(duration: _pageTurn, curve: Curves.easeOut)),
                      child: Text(t.eventGuide.next, textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustrationPanel extends StatelessWidget {
  const _IllustrationPanel({required this.decoration, required this.child});

  final BoxDecoration decoration;
  final Widget child;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: _panelMargin),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 160, maxHeight: 360),
        // A stack of only positioned children has no intrinsic height, so the
        // page measures the panel at its minimum height and lets it grow into
        // the space the text leaves.
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: decoration.copyWith(borderRadius: BorderRadius.circular(28)),
                child: Padding(
                  padding: _panelPadding,
                  child: LayoutBuilder(
                    builder: (context, constraints) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: math.max(
                          constraints.maxWidth,
                          _designScreenWidth - 2 * _panelMargin - _panelPadding.horizontal,
                        ),
                        child: MediaQuery.withNoTextScaling(child: child),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: Translations.of(context).eventGuide.pageIndicator(page: current + 1, total: count),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          for (var index = 0; index < count; index++)
            DecoratedBox(
              decoration: BoxDecoration(
                color: index == current ? colors.primary : colors.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SizedBox(width: index == current ? 24 : 8, height: 8),
            ),
        ],
      ),
    );
  }
}

class _SessionsIllustration extends StatelessWidget {
  const _SessionsIllustration();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final placeholder = BoxDecoration(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(5),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      t.eventGuide.sessions.sampleTime,
                      style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        child: Text(
                          t.eventGuide.sessions.sampleRoom,
                          style: theme.textTheme.labelSmall?.copyWith(color: colors.onPrimaryContainer),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.bookmark, size: 22, color: colors.primary),
                  ],
                ),
                const SizedBox(height: 12),
                FractionallySizedBox(
                  widthFactor: 0.92,
                  child: DecoratedBox(decoration: placeholder, child: const SizedBox(height: 10)),
                ),
                const SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.64,
                  child: DecoratedBox(decoration: placeholder, child: const SizedBox(height: 10)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
                      child: const SizedBox.square(dimension: 24),
                    ),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const SizedBox(width: 96, height: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Text(
            t.eventGuide.sessions.afterSession,
            style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(22),
          ),
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 18, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      t.sessionDetails.feedback,
                      style: theme.textTheme.labelLarge?.copyWith(color: colors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VenueEventsIllustration extends StatelessWidget {
  const _VenueEventsIllustration();

  static const _features = [
    VenueEventFeature.stampRally,
    VenueEventFeature.profileExchange,
    VenueEventFeature.supportLt,
    VenueEventFeature.snsPost,
  ];

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const onBrand = Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Text(
            t.eventGuide.venueEvents.eventTab,
            style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colors.primary, width: 2),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.brand, borderRadius: BorderRadius.circular(12)),
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 12, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 22, color: onBrand),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.venueEvents.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: onBrand,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20, color: onBrand),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        for (var start = 0; start < _features.length; start += 2) ...[
          if (start > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _FeatureTile(feature: _features[start])),
                const SizedBox(width: 8),
                Expanded(child: _FeatureTile(feature: _features[start + 1])),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});

  final VenueEventFeature feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
              child: SizedBox.square(
                dimension: 36,
                child: Icon(feature.icon, size: 18, color: colors.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              feature.title(Translations.of(context)),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizIllustration extends StatelessWidget {
  const _QuizIllustration();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              t.venueEvents.day2,
              style: theme.textTheme.labelMedium?.copyWith(color: colors.onPrimaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(color: colors.inverseSurface, borderRadius: BorderRadius.circular(14)),
          child: SizedBox(
            width: 232,
            height: 132,
            child: Icon(Icons.qr_code_2, size: 76, color: colors.onInverseSurface),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          t.eventGuide.quiz.checkInOpens,
          style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            _RoundStart(round: t.eventGuide.quiz.firstRound, time: t.eventGuide.quiz.firstRoundTime),
            _RoundStart(round: t.eventGuide.quiz.secondRound, time: t.eventGuide.quiz.secondRoundTime),
          ],
        ),
      ],
    );
  }
}

class _RoundStart extends StatelessWidget {
  const _RoundStart({required this.round, required this.time});

  final String round;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 116,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(round, style: theme.textTheme.labelMedium?.copyWith(color: colors.primary)),
              Text(
                time,
                style: theme.textTheme.headlineSmall?.copyWith(fontSize: 26, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
