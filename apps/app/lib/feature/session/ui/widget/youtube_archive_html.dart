import 'dart:convert';

/// The same player document is used by the native WebView and the web iframe.
/// [origin] identifies the installed app on native, and the hosting site on web.
String youtubeArchivePlayerHtml({required Uri embedUri, required Uri origin, required String title}) {
  final playerUri = embedUri.replace(
    queryParameters: {
      ...embedUri.queryParameters,
      'enablejsapi': '1',
      'origin': origin.origin,
      'playsinline': '1',
      'autoplay': '0',
    },
  );
  const escape = HtmlEscape();
  return '''
<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="referrer" content="strict-origin-when-cross-origin">
<style>html,body{margin:0;width:100%;height:100%;background:#000}iframe{display:block;width:100%;height:100%;border:0}</style>
</head>
<body>
<iframe id="youtube-archive-frame" src="${escape.convert(playerUri.toString())}"
 title="${escape.convert(title)}" referrerpolicy="strict-origin-when-cross-origin"
 allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture; fullscreen" allowfullscreen></iframe>
<script>
let archivePlayer;
function reportArchiveError() {
  if (window.YouTubeArchiveChannel) {
    window.YouTubeArchiveChannel.postMessage('error');
  } else if (window.parent !== window) {
    window.parent.postMessage('youtube-archive-error', ${jsonEncode(origin.origin)});
  }
}
function onYouTubeIframeAPIReady() {
  archivePlayer = new YT.Player('youtube-archive-frame', {
    events: {onError: reportArchiveError}
  });
}
window.addEventListener('pagehide', function () {
  if (archivePlayer) archivePlayer.destroy();
});
</script>
<script src="https://www.youtube.com/iframe_api" onerror="reportArchiveError()"></script>
</body>
</html>''';
}

/// YouTube requires the installed application identifier as the native referrer.
Uri youtubeArchiveAppOrigin(String packageName) => Uri(scheme: 'https', host: packageName.toLowerCase());
