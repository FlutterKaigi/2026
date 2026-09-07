import 'dart:async';

import 'package:app/core/i18n/strings.g.dart';
import 'package:app/core/ui/launch_external_url.dart';
import 'package:app/feature/profile/data/sns_platform.dart';
import 'package:app/feature/profile/ui/widget/sns_link_icon_widget.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact chip for one [SnsLink].
///
/// Opens [link] externally when possible. When it isn't a launchable URI, or
/// nothing on the device can open it, the value is copied to the clipboard
/// instead so the link is still reachable.
class SnsLinkChip extends StatelessWidget {
  const SnsLinkChip({required this.link, super.key});

  final SnsLink link;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final platform = SnsPlatform.fromKey(link.type);
    final uri = Uri.tryParse(link.value);

    Future<void> handleTap() async {
      final launched = uri != null && await tryLaunchExternalUrl(uri);
      if (launched || !context.mounted) {
        return;
      }
      await Clipboard.setData(ClipboardData(text: link.value));
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t.links.copied)));
    }

    return ActionChip(
      avatar: SnsLinkIcon(platform: platform, size: 14),
      label: Text(platform.label ?? t.profile.snsPlatformOther),
      labelStyle: Theme.of(context).textTheme.labelMedium,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      tooltip: link.value,
      onPressed: () => unawaited(handleTap()),
    );
  }
}
