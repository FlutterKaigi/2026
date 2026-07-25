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

    return ListView(
      controller: scrollController,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
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
      ],
    );
  }
}
