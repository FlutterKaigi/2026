import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Google Analytics (gtag.js) for `G-0FZ58E7XNG`.
///
/// Mounted per-route via `Document.head()` rather than the site-wide
/// `Document` in `main.server.dart`, so `/x/<token>` (see
/// `ShareLinkFallbackPage`) can omit it: `gtag('config', ...)` fires an
/// automatic `page_view` carrying `page_location` (the full URL, token
/// included), and that page has no legitimate use for the token being sent
/// anywhere off-device.
class Analytics extends StatelessComponent {
  const Analytics({super.key});

  @override
  Component build(BuildContext context) => Document.head(
    children: [
      script(
        src: 'https://www.googletagmanager.com/gtag/js?id=G-0FZ58E7XNG',
        async: true,
      ),
      script(
        content: '''
window.dataLayer = window.dataLayer || [];
function gtag() {
  dataLayer.push(arguments);
}
gtag('js', new Date());
gtag('config', 'G-0FZ58E7XNG');
''',
      ),
    ],
  );
}
