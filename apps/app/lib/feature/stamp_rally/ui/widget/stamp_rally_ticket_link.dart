import 'package:app/core/constants/app_links.dart';
import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:flutter/material.dart';

/// Opens the event page where attendees can show their Luma ticket.
class StampRallyTicketLink extends StatelessWidget {
  const StampRallyTicketLink({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => launchExternalUrl(
            context,
            uri: Uri.parse(AppLinks.lumaEvent),
            failureMessage: t.links.openError,
          ),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(t.stampRally.lumaTicketButton, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 8),
        Text(
          t.stampRally.lumaTicketDescription,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
