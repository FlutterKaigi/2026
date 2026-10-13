import 'dart:convert';

import 'package:qr/qr.dart';

export 'open_html_stub.dart' if (dart.library.js_interop) 'open_html_web.dart';

/// A standalone page of QR codes. Flutter Web draws onto a canvas, which
/// browsers do not paginate when printing, so codes are printed as SVG.
String stampRallyPrintHtml(List<({String label, String url})> codes) {
  const escape = HtmlEscape();
  final cards = codes
      .map(
        (code) =>
            '<section><h2>${escape.convert(code.label)}</h2>${_svg(code.url)}<p>${escape.convert(code.url)}</p></section>',
      )
      .join();
  return '<!doctype html><html lang="ja"><head><meta charset="utf-8"><title>スタンプラリー QRコード</title><style>'
      'body{font-family:sans-serif;margin:0}'
      'section{display:inline-block;box-sizing:border-box;width:46%;margin:2%;padding:12px;border:1px solid #999;'
      'text-align:center;vertical-align:top;break-inside:avoid;page-break-inside:avoid}'
      'h2{font-size:14pt;margin:0 0 8px}svg{width:60mm;height:60mm}p{font-size:7pt;word-break:break-all;margin:8px 0 0}'
      '</style></head><body>$cards<script>addEventListener("load",()=>print())</script></body></html>';
}

String _svg(String data) {
  const quietZone = 4;
  final image = QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M));
  final size = image.moduleCount + quietZone * 2;
  final path = StringBuffer();
  for (var y = 0; y < image.moduleCount; y++) {
    for (var x = 0; x < image.moduleCount; x++) {
      if (image.isDark(y, x)) path.write('M${x + quietZone},${y + quietZone}h1v1h-1z');
    }
  }
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $size $size" shape-rendering="crispEdges">'
      '<rect width="$size" height="$size" fill="#fff"/><path d="$path"/></svg>';
}
