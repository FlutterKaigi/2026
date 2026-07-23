import 'package:app/core/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VenueMapViewportWidget extends StatelessWidget {
  const VenueMapViewportWidget({
    required this.controller,
    required this.isLoading,
    required this.loadError,
    required this.onRetry,
    super.key,
  });

  final WebViewController controller;
  final bool isLoading;
  final String? loadError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: colorScheme.surface,
          child: loadError == null
              ? Stack(
                  children: [
                    WebViewWidget(controller: controller),
                    if (isLoading) const _VenueMapLoadingStateWidget(),
                  ],
                )
              : _VenueMapErrorStateWidget(
                  onRetry: onRetry,
                ),
        ),
      ),
    );
  }
}

class _VenueMapLoadingStateWidget extends StatelessWidget {
  const _VenueMapLoadingStateWidget();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surface.withValues(alpha: 0.86),
      child: const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }
}

class _VenueMapErrorStateWidget extends StatelessWidget {
  const _VenueMapErrorStateWidget({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_outlined,
                    color: colorScheme.error,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.venueMap.loadError,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.venueMap.loadErrorDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(t.common.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
