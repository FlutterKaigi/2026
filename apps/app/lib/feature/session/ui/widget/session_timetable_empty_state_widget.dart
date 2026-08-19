import 'package:app/core/i18n/strings.g.dart';
import 'package:flutter/material.dart';

class SessionTimetableEmptyStateWidget extends StatelessWidget {
  const SessionTimetableEmptyStateWidget({
    required this.scrollController,
    super.key,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentHeight = constraints.maxHeight > 48 ? constraints.maxHeight - 48 : 0.0;

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: contentHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.sessionTimetable.empty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
