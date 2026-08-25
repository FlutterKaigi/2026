import 'package:app/core/ui/widget/app_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A staff profile card with optional greeting and social links.
class StaffMemberCardWidget extends StatelessWidget {
  const StaffMemberCardWidget({
    required this.staffMember,
    super.key,
  });

  final StaffMember staffMember;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final greeting = staffMember.greeting?.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppNetworkAvatar(
              imageUrl: staffMember.iconUrl,
              radius: 48,
              backgroundColor: colorScheme.surfaceContainerHighest,
              fallback: Icon(
                Icons.person_outline,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              staffMember.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (greeting != null && greeting.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                greeting,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
            if (staffMember.snsLinks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: [
                  for (final link in staffMember.snsLinks)
                    IconButton(
                      icon: Icon(_iconFor(link.type)),
                      tooltip: link.type,
                      onPressed: () => _openLink(link.value),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) => switch (type.toLowerCase()) {
    'github' => Icons.code,
    'x' || 'twitter' => Icons.alternate_email,
    'bluesky' => Icons.cloud_outlined,
    'medium' || 'note' || 'zenn' || 'qiita' => Icons.article_outlined,
    _ => Icons.link,
  };

  Future<void> _openLink(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
