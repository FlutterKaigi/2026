import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

const supportsVenuePhotoDownload = true;

Future<void> saveVenuePhoto(Uint8List bytes, String filename) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'image/png'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
}
