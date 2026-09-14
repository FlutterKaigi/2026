import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

const supportsVenuePhotoDownload = true;

Future<void> saveVenuePhoto(Uint8List bytes, String filename) async {
  // Opt-in transport for the standalone local demo; app builds use object URLs.
  // ignore: do_not_use_environment
  const endpoint = String.fromEnvironment('VENUE_WALK_PHOTO_ENDPOINT');
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'image/png'));
  String url;
  if (endpoint.isNotEmpty) {
    // The local preview server supports hosts that cannot download blob URLs.
    final response = await web.window
        .fetch(
          endpoint.toJS,
          web.RequestInit(
            method: 'POST',
            headers: web.Headers()
              ..set('Content-Type', 'image/png')
              ..set('X-Venue-Walk-Photo', '1'),
            body: blob,
          ),
        )
        .toDart;
    if (!response.ok) {
      throw StateError('Photo server returned ${response.status}');
    }
    final result = jsonDecode((await response.text().toDart).toDart) as Map<String, Object?>;
    url = result['url']! as String;
  } else {
    url = web.URL.createObjectURL(blob);
  }
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  if (endpoint.isEmpty) {
    Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
  }
}
