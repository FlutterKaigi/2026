import 'package:data/archive_url.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/theme.dart';
import '../l10n/strings.dart';

/// The player stays unloaded until its surrounding popover is opened.
/// Keep the external link available for videos whose owners disable embedding.
class TimetableArchive extends StatelessComponent {
  const TimetableArchive({required this.url, required this.title, required this.strings, super.key});

  final String url;
  final String title;
  final Strings strings;

  @override
  Component build(BuildContext context) {
    final external = youtubeArchiveUri(url);
    if (external == null) return const .fragment([]);
    final embed = youtubeArchiveEmbedUri(url);
    return div(classes: 'timetable-archive', [
      if (embed != null)
        Component.element(
          tag: 'iframe',
          classes: 'timetable-archive__player',
          attributes: {
            'data-archive-src': embed
                .replace(queryParameters: {...embed.queryParameters, 'playsinline': '1'})
                .toString(),
            'title': strings.timetableArchivePlayerTitle(title),
            'allow': 'accelerometer; encrypted-media; gyroscope; picture-in-picture; fullscreen',
            'allowfullscreen': '',
            // YouTube identifies the embedding site through its HTTP Referer.
            'referrerpolicy': 'strict-origin-when-cross-origin',
          },
        ),
      a(
        href: external.toString(),
        target: Target.blank,
        classes: 'timetable-archive__link',
        attributes: const {'rel': 'noopener noreferrer'},
        [.text(strings.timetableWatchOnYouTube)],
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.timetable-archive').styles(display: .flex, flexDirection: .column, gap: Gap.row(12.px)),
    css('.timetable-archive__player').styles(
      width: 100.percent,
      radius: .circular(8.px),
      raw: const {
        'display': 'block',
        // https://developers.google.com/youtube/player_parameters
        'min-width': '200px',
        'min-height': '200px',
        'aspect-ratio': '16 / 9',
        'border': '0',
        'background': '#000',
      },
    ),
    css('.timetable-archive__link').styles(
      color: primary,
      fontFamily: uiFontFamily,
      fontWeight: .w600,
      raw: const {'text-decoration': 'underline', 'text-underline-offset': '0.2em'},
    ),
  ];
}
