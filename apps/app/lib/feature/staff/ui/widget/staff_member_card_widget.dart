import 'package:app/core/ui/widget/app_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                      icon: _SnsLinkIcon(type: link.type),
                      tooltip: _snsLinkLabel(link.type),
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

  Future<void> _openLink(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Brand mark for a single SNS link, tinted to the current color scheme.
class _SnsLinkIcon extends StatelessWidget {
  const _SnsLinkIcon({required this.type});

  final String type;

  static const _size = 20.0;

  @override
  Widget build(BuildContext context) {
    final asset = _snsLinkIconAsset(type);
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    // アセットは単色マークなので、テーマ側の色で塗り直して light / dark 両方に合わせる。
    if (asset.endsWith('.png')) {
      return Image.asset(
        asset,
        width: _size,
        height: _size,
        color: color,
        excludeFromSemantics: true,
      );
    }
    return SvgPicture.asset(
      asset,
      width: _size,
      height: _size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}

/// Icon asset for a [SnsLink.type] as entered in the admin dashboard
/// (`x`, `github`, `note`, `medium`, `qiita`, `zenn`, `bluesky`, `mixi2`, …).
/// Platforms without a dedicated icon fall back to the generic globe.
///
/// mixi2 だけ png なのは、公式が配布するブランドアセットが png / ai のみで
/// svg が無いため (website 側と同じ素材を流用している)。
String _snsLinkIconAsset(String type) => switch (type.toLowerCase()) {
  'x' || 'twitter' => 'res/assets/icons/link_x.svg',
  'github' => 'res/assets/icons/link_github.svg',
  'note' => 'res/assets/icons/link_note.svg',
  'medium' => 'res/assets/icons/link_medium.svg',
  'bluesky' => 'res/assets/icons/link_bluesky.svg',
  'qiita' => 'res/assets/icons/link_qiita.svg',
  'zenn' => 'res/assets/icons/link_zenn.svg',
  'mixi2' => 'res/assets/icons/link_mixi2.png',
  _ => 'res/assets/icons/link_globe.svg',
};

/// Human-readable platform name, used as the icon button tooltip.
String _snsLinkLabel(String type) => switch (type.toLowerCase()) {
  'x' || 'twitter' => 'X',
  'github' => 'GitHub',
  'note' => 'note',
  'medium' => 'Medium',
  'bluesky' => 'Bluesky',
  'qiita' => 'Qiita',
  'zenn' => 'Zenn',
  'mixi2' => 'mixi2',
  _ => 'Web',
};
