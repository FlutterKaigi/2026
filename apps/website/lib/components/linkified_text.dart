import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Plain text with tappable http(s) URLs. Content is always HTML-escaped.
class LinkifiedText extends StatelessComponent {
  const LinkifiedText(this.text, {super.key});

  final String text;

  @override
  Component build(BuildContext context) => .fragment(_linkify(text).toList());
}

// Like the app's event description, stop URLs before non-ASCII text (e.g. 。).
// Quotes and angle brackets delimit a URL rather than becoming part of it.
final _urlPattern = RegExp(r'''https?://[^\s<>"'\u0080-\uFFFF]+''', caseSensitive: false);
final _trailingPunctuation = RegExp(r'''[.,;:!?)\]}>]+$''');

Iterable<Component> _linkify(String text) sync* {
  var start = 0;
  for (final match in _urlPattern.allMatches(text)) {
    final url = match[0]!.replaceFirst(_trailingPunctuation, '');
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      continue;
    }
    yield .text(text.substring(start, match.start));
    yield a(
      href: url,
      target: Target.blank,
      attributes: const {'rel': 'noopener noreferrer'},
      [.text(url)],
    );
    start = match.start + url.length;
  }
  yield .text(text.substring(start));
}
