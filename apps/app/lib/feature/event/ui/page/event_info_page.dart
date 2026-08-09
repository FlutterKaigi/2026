import 'dart:async';

import 'package:app/core/constants/app_links.dart';
import 'package:app/core/designsystem/theme/app_gradients.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/provider/app_locale.dart';
import 'package:app/core/router/router.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/core/ui/widget/settings_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Shows the FlutterKaigi 2026 overview, related links, and app settings.
class EventInfoPage extends ConsumerWidget {
  const EventInfoPage({super.key, this.externalUrlLauncher});

  /// Optional launcher used by tests to observe the destination URI.
  final ExternalUrlLauncher? externalUrlLauncher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final appLocale = ref.watch(appLocaleProvider);
    final localizedLinks = _LocalizedEventLinks.fromLocale(appLocale);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(
          t.eventInfo.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [SettingsIconButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 840 ? 32.0 : 16.0;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              24,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _NewsBanner(
                        onTap: () => const NewsRoute().push<void>(context),
                      ),
                      const SizedBox(height: 8),
                      _EventOverviewCard(
                        onOpenMap: () => unawaited(
                          _openExternalUrl(
                            context,
                            url: AppLinks.venueMap,
                            failureMessage: t.links.openError,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionHeading(title: t.eventInfo.other),
                      const SizedBox(height: 8),
                      Card.outlined(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _ExternalLinkTile(
                              icon: Icons.language,
                              title: t.eventInfo.officialWebsite,
                              onTap: () => unawaited(
                                _openExternalUrl(
                                  context,
                                  url: AppLinks.officialWebsite,
                                  failureMessage: t.links.openError,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _ExternalLinkTile(
                              icon: Icons.handshake_outlined,
                              title: t.eventInfo.codeOfConduct,
                              onTap: () => unawaited(
                                _openExternalUrl(
                                  context,
                                  url: localizedLinks.codeOfConduct,
                                  failureMessage: t.links.openError,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _ExternalLinkTile(
                              icon: Icons.privacy_tip_outlined,
                              title: t.eventInfo.privacyPolicy,
                              onTap: () => unawaited(
                                _openExternalUrl(
                                  context,
                                  url: localizedLinks.privacyPolicy,
                                  failureMessage: t.links.openError,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _ExternalLinkTile(
                              icon: Icons.policy_outlined,
                              title: t.eventInfo.exclusionPolicy,
                              onTap: () => unawaited(
                                _openExternalUrl(
                                  context,
                                  url: localizedLinks.exclusionPolicy,
                                  failureMessage: t.links.openError,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _ExternalLinkTile(
                              icon: Icons.mail_outline,
                              title: t.eventInfo.contact,
                              onTap: () => unawaited(
                                _openExternalUrl(
                                  context,
                                  url: AppLinks.contact,
                                  failureMessage: t.links.openError,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _ExternalLinkTile(
                              icon: Icons.code,
                              title: t.eventInfo.sourceCode,
                              onTap: () => unawaited(
                                _openExternalUrl(
                                  context,
                                  url: AppLinks.repository,
                                  failureMessage: t.links.openError,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            _ExternalLinkTile(
                              icon: Icons.article_outlined,
                              title: t.eventInfo.ossLicenses,
                              external: false,
                              onTap: () => const LicenseRoute().push<void>(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openExternalUrl(
    BuildContext context, {
    required String url,
    required String failureMessage,
  }) => launchExternalUrl(
    context,
    uri: Uri.parse(url),
    failureMessage: failureMessage,
    launcher: externalUrlLauncher,
  );
}

/// External documents that have separate Japanese and English pages.
class _LocalizedEventLinks {
  const _LocalizedEventLinks({
    required this.codeOfConduct,
    required this.privacyPolicy,
    required this.exclusionPolicy,
  });

  factory _LocalizedEventLinks.fromLocale(AppLocale locale) => switch (locale) {
    AppLocale.ja => const _LocalizedEventLinks(
      codeOfConduct: AppLinks.codeOfConductJa,
      privacyPolicy: AppLinks.privacyPolicyJa,
      exclusionPolicy: AppLinks.exclusionPolicyJa,
    ),
    AppLocale.en => const _LocalizedEventLinks(
      codeOfConduct: AppLinks.codeOfConductEn,
      privacyPolicy: AppLinks.privacyPolicyEn,
      exclusionPolicy: AppLinks.exclusionPolicyEn,
    ),
  };

  final String codeOfConduct;
  final String privacyPolicy;
  final String exclusionPolicy;
}

class _EventOverviewCard extends StatelessWidget {
  const _EventOverviewCard({required this.onOpenMap});

  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final artwork = Image.asset(
      'res/assets/shuriken-logo.png',
      fit: BoxFit.contain,
      semanticLabel: t.eventInfo.logoSemanticLabel,
    );
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                t.eventInfo.tagline,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                t.eventInfo.themeName,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            t.eventInfo.description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 16),
          _EventFactRow(
            icon: Icons.calendar_today_outlined,
            label: t.eventInfo.dateLabel,
            value: t.eventInfo.date,
          ),
          const SizedBox(height: 12),
          _EventFactRow(
            icon: Icons.location_on_outlined,
            label: t.eventInfo.venueLabel,
            value: t.eventInfo.venue,
            actionLabel: t.eventInfo.viewMap,
            onAction: onOpenMap,
          ),
        ],
      ),
    );

    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 152,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: AppGradients.brand,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: artwork,
              ),
            ),
          ),
          content,
        ],
      ),
    );
  }
}

class _NewsBanner extends StatelessWidget {
  const _NewsBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    const foreground = Colors.white;
    const textShadows = [
      Shadow(color: Color(0xCC000000), blurRadius: 3),
    ];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: AppGradients.brand,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 22,
                  color: foreground,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.eventInfo.newsTitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                          shadows: textShadows,
                        ),
                      ),
                      Text(
                        t.eventInfo.newsSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: foreground,
                          shadows: textShadows,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 20, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventFactRow extends StatelessWidget {
  const _EventFactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Icon(
            icon,
            size: 22,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 1),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (actionLabel case final actionLabel?)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.standard,
                        textStyle: theme.textTheme.labelMedium,
                      ),
                      child: Text(actionLabel),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    ),
  );
}

class _ExternalLinkTile extends StatelessWidget {
  const _ExternalLinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.external = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool external;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    minTileHeight: 48,
    leading: Icon(icon, size: 22),
    title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
    trailing: Icon(
      external ? Icons.open_in_new : Icons.chevron_right,
      size: 20,
    ),
    onTap: onTap,
  );
}
