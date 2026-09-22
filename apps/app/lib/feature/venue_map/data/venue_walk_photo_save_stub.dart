import 'dart:typed_data';

const supportsVenuePhotoDownload = false;

Future<void> saveVenuePhoto(Uint8List bytes, String filename) async {
  throw UnsupportedError('The demo downloads photos in a browser.');
}
