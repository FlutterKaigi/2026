/// Generates `apps/website/lib/constants/generated_sponsors.dart` and the
/// processed sponsor images under `apps/website/web/images/sponsors/` from the
/// tracc API (production) or a local sample fixture (local/preview).
///
/// Both outputs are **git-ignored** and regenerated on every build, so real
/// sponsor data never enters the git history (see `.gitignore`).
///
/// Run via:
///
/// ```sh
/// fvm dart run melos sponsors:generate          # uses the sample fixture
/// SPONSORS_API_URL=... TRACC_API_KEY=... \
///   fvm dart run tool/generate_sponsors.dart     # fetches the real API
/// ```
///
/// Data source selection:
///   - If `SPONSORS_API_URL` is set, GET it with `Authorization: Bearer
///     $TRACC_API_KEY` (when present) and parse the response.
///   - Otherwise fall back to `tool/sponsors/sample_sponsors.json`.
///
/// Logo handling (raster sources — PNG/JPG/WebP):
///   - square (home grid) + wide (detail banner) variants are written as PNG.
///   - an OGP card (1200x630) is composited over `web/images/ogp.png`.
///   - if a logo can't be fetched/decoded (e.g. an SVG), the remote URL is used
///     for display and the OGP falls back to the default site image — the build
///     never fails because of a single bad logo.
///   - sample entries use an empty `logoUrl`, so a branded placeholder is
///     synthesized offline.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

const _outFile = 'apps/website/lib/constants/generated_sponsors.dart';
const _imagesOutDir = 'apps/website/web/images/sponsors';
const _ogpBasePath = 'apps/website/web/images/sponsor_ogp_base.png';
const _sampleFile = 'tool/sponsors/sample_sponsors.json';

// Asset paths are written relative to the site base href.
const _assetPrefix = 'images/sponsors';
const _defaultOgp = 'images/ogp.png';

// Output sizes.
const _squarePx = 512;
const _wideW = 1000;
const _wideH = 340;
const _ogpW = 1200;
const _ogpH = 630;

Future<void> main(List<String> args) async {
  final entries = await _loadSponsors();
  if (entries.isEmpty) {
    stderr.writeln('warning: no sponsors found in the data source.');
  }

  Directory(_imagesOutDir).createSync(recursive: true);

  final ogpBase = img.decodeImage(File(_ogpBasePath).readAsBytesSync());
  if (ogpBase == null) {
    stderr.writeln('error: could not decode OGP base $_ogpBasePath');
    exitCode = 1;
    return;
  }

  for (final s in entries) {
    await _processImages(s, ogpBase);
  }

  _writeDart(entries);
  _format(_outFile);

  stdout.writeln(
    'Wrote $_outFile and ${entries.length} sponsor image set(s) to $_imagesOutDir/',
  );
}

// ── Data loading ──────────────────────────────────────────────────────────

Future<List<_Sponsor>> _loadSponsors() async {
  final apiUrl = Platform.environment['SPONSORS_API_URL'];

  if (apiUrl != null && apiUrl.trim().isNotEmpty) {
    try {
      final apiKey = Platform.environment['TRACC_API_KEY'];
      stdout.writeln('Fetching sponsors from API: $apiUrl');
      final resp = await http
          .get(
            Uri.parse(apiUrl),
            headers: {
              'Accept': 'application/json',
              if (apiKey != null && apiKey.isNotEmpty)
                'Authorization': 'Bearer $apiKey',
            },
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw HttpException('Sponsor API returned ${resp.statusCode}');
      }
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      final sponsors = _extractList(decoded).map(_Sponsor.fromJson).toList();
      stdout.writeln('Loaded ${sponsors.length} sponsor(s) from the API.');
      return sponsors;
    } catch (e) {
      // The API may be unreachable or not yet provisioned (e.g. no key yet).
      // Fall back to the sample fixture so the build still succeeds and the
      // preview renders placeholder sponsors instead of failing.
      stderr.writeln(
        'warning: could not load sponsors from the API ($e).\n'
        'Falling back to the sample fixture — placeholder sponsors will be shown.',
      );
    }
  } else {
    stdout.writeln('SPONSORS_API_URL not set — using sample fixture $_sampleFile');
  }

  return _loadSampleSponsors();
}

List<_Sponsor> _loadSampleSponsors() {
  final decoded = jsonDecode(File(_sampleFile).readAsStringSync());
  return _extractList(decoded).map(_Sponsor.fromJson).toList();
}

/// Accepts a bare array or a `{sponsors|data|items: [...]}` envelope.
List<Map<String, dynamic>> _extractList(Object? decoded) {
  final list = switch (decoded) {
    final List<dynamic> l => l,
    {'sponsors': final List<dynamic> l} => l,
    {'data': final List<dynamic> l} => l,
    {'items': final List<dynamic> l} => l,
    _ => const <dynamic>[],
  };
  return list.whereType<Map<String, dynamic>>().toList();
}

// ── Image processing ────────────────────────────────────────────────────────

Future<void> _processImages(_Sponsor s, img.Image ogpBase) async {
  img.Image? logo;
  final url = s.logoUrl.trim();
  if (url.isNotEmpty) {
    try {
      final bytes = await _fetchBytes(url);
      logo = img.decodeImage(bytes);
      if (logo == null) {
        stderr.writeln('warning: could not decode logo for "${s.name}" ($url)');
      }
    } catch (e) {
      stderr.writeln('warning: could not fetch logo for "${s.name}" ($url): $e');
    }
  }

  // SVG / fetch failure with a real URL: use the remote URL for display and the
  // default OGP. (Empty URL → synthesize a branded placeholder below.)
  if (logo == null && url.isNotEmpty) {
    s.squareLogo = url;
    s.wideLogo = url;
    s.ogpImage = _defaultOgp;
    return;
  }

  logo ??= _placeholderLogo(s.name, _squarePx, _squarePx);

  final square = _containCanvas(logo, _squarePx, _squarePx, padFrac: 0.12);
  _writePng('${s.slug}-square.png', square);
  s.squareLogo = '$_assetPrefix/${s.slug}-square.png';

  final wide = _containCanvas(logo, _wideW, _wideH, padFrac: 0.06);
  _writePng('${s.slug}-wide.png', wide);
  s.wideLogo = '$_assetPrefix/${s.slug}-wide.png';

  final ogp = _composeOgp(ogpBase, logo);
  _writePng('${s.slug}-ogp.png', ogp);
  s.ogpImage = '$_assetPrefix/${s.slug}-ogp.png';
}

Future<Uint8List> _fetchBytes(String url) async {
  final resp = await http
      .get(Uri.parse(url))
      .timeout(const Duration(seconds: 20));
  if (resp.statusCode != 200) {
    throw HttpException('status ${resp.statusCode}');
  }
  return resp.bodyBytes;
}

void _writePng(String name, img.Image image) {
  File('$_imagesOutDir/$name').writeAsBytesSync(img.encodePng(image));
}

/// Scales [src] to fit within [maxW]x[maxH] preserving aspect ratio.
img.Image _scaleToFit(img.Image src, int maxW, int maxH) {
  final scale = (maxW / src.width) < (maxH / src.height)
      ? maxW / src.width
      : maxH / src.height;
  final w = (src.width * scale).round().clamp(1, maxW);
  final h = (src.height * scale).round().clamp(1, maxH);
  return img.copyResize(
    src,
    width: w,
    height: h,
    interpolation: img.Interpolation.cubic,
  );
}

/// Centers [src] (contained) on a transparent [w]x[h] canvas. [padFrac] keeps
/// breathing room as a fraction of the canvas.
img.Image _containCanvas(img.Image src, int w, int h, {double padFrac = 0.0}) {
  final innerW = (w * (1 - padFrac)).round();
  final innerH = (h * (1 - padFrac)).round();
  final fitted = _scaleToFit(src, innerW, innerH);
  final canvas = img.Image(width: w, height: h, numChannels: 4);
  img.compositeImage(
    canvas,
    fitted,
    dstX: ((w - fitted.width) / 2).round(),
    dstY: ((h - fitted.height) / 2).round(),
  );
  return canvas;
}

/// Builds the 1200x630 OGP image: the branded base with the sponsor logo on a
/// white rounded card centered in its clear area.
img.Image _composeOgp(img.Image base, img.Image logo) {
  final ogp = img.copyResize(base, width: _ogpW, height: _ogpH);

  // White rounded card centered between the corner motifs of the base.
  const cardW = 760;
  const cardH = 380;
  final cardX = (_ogpW - cardW) ~/ 2;
  final cardY = (_ogpH - cardH) ~/ 2;
  img.fillRect(
    ogp,
    x1: cardX,
    y1: cardY,
    x2: cardX + cardW,
    y2: cardY + cardH,
    color: img.ColorRgb8(255, 255, 255),
    radius: 28,
  );

  // Logo contained within the card with padding.
  const cardPad = 56;
  final fitted = _scaleToFit(logo, cardW - cardPad * 2, cardH - cardPad * 2);
  img.compositeImage(
    ogp,
    fitted,
    dstX: cardX + (cardW - fitted.width) ~/ 2,
    dstY: cardY + (cardH - fitted.height) ~/ 2,
  );

  return ogp;
}

/// Deterministic branded placeholder for sample data / missing logos.
img.Image _placeholderLogo(String name, int w, int h) {
  final canvas = img.Image(width: w, height: h, numChannels: 4);
  final (r, g, b) = _brandColor(name);
  img.fillRect(canvas, x1: 0, y1: 0, x2: w, y2: h, color: img.ColorRgb8(r, g, b), radius: 0);
  final initials = _initials(name);
  final font = img.arial48;
  final textW = _approxTextWidth(initials, font);
  img.drawString(
    canvas,
    initials,
    font: font,
    x: ((w - textW) / 2).round(),
    y: (h - font.lineHeight) ~/ 2,
    color: img.ColorRgb8(255, 255, 255),
  );
  return canvas;
}

int _approxTextWidth(String s, img.BitmapFont font) {
  // BitmapFonts have no public measure API; approximate from line height.
  final perChar = font.lineHeight * 0.5;
  return (s.length * perChar).round();
}

String _initials(String name) {
  final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final w = words.first;
    return w.substring(0, w.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (words[0][0] + words[1][0]).toUpperCase();
}

(int, int, int) _brandColor(String seed) {
  var hash = 0;
  for (final c in seed.codeUnits) {
    hash = (hash * 31 + c) & 0x7fffffff;
  }
  // Brand-ish purples/magentas: fixed-ish hue band, varied lightness.
  const palette = [
    (101, 85, 143), // deep purple
    (143, 85, 130),
    (85, 90, 160),
    (120, 70, 150),
    (90, 80, 175),
  ];
  return palette[hash % palette.length];
}

// ── Dart emission ───────────────────────────────────────────────────────────

void _writeDart(List<_Sponsor> sponsors) {
  final out = StringBuffer()
    ..writeln('// GENERATED FILE — do not edit by hand and do not commit.')
    ..writeln('// Source of truth: tracc API (prod) or tool/sponsors/sample_sponsors.json.')
    ..writeln('// Regenerate via: fvm dart run melos sponsors:generate')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars, directives_ordering')
    ..writeln()
    ..writeln("import 'sponsors.dart';")
    ..writeln()
    ..writeln('const List<Sponsor> generatedSponsors = [');

  for (final s in sponsors) {
    out
      ..writeln('  Sponsor(')
      ..writeln('    id: ${_str(s.id)},')
      ..writeln('    slug: ${_str(s.slug)},')
      ..writeln('    tier: SponsorTier.${s.tier.name},')
      ..writeln('    name: ${_str(s.name)},')
      ..writeln('    prText: ${_str(s.prText)},')
      ..writeln('    links: [');
    for (final l in s.links) {
      out.writeln(
        '      SponsorLink(url: ${_str(l.url)}, title: ${_str(l.title)}, type: SponsorLinkType.${l.type.name}),',
      );
    }
    out
      ..writeln('    ],')
      ..writeln('    squareLogo: ${_str(s.squareLogo)},')
      ..writeln('    wideLogo: ${_str(s.wideLogo)},')
      ..writeln('    ogpImage: ${_str(s.ogpImage)},');
    if (s.benefits.isNotEmpty) {
      out.writeln('    benefits: [${s.benefits.map(_str).join(', ')}],');
    }
    out
      ..writeln('    year: ${s.year},')
      ..writeln('  ),');
  }

  out.writeln('];');
  File(_outFile).writeAsStringSync(out.toString());
}

void _format(String path) {
  // Format with whatever is available; never fail the build over formatting.
  // Try `dart` first (present in CI), then `fvm dart` (local fvm setups).
  // `Process.runSync` throws (not just non-zero) when the executable is
  // missing, so each candidate is guarded.
  const candidates = [
    ['dart', 'format'],
    ['fvm', 'dart', 'format'],
  ];
  for (final cmd in candidates) {
    try {
      final r = Process.runSync(cmd.first, [...cmd.skip(1), path]);
      if (r.exitCode == 0) return;
    } on ProcessException {
      // Executable not found — try the next candidate.
    }
  }
  stderr.writeln('warning: could not run `dart format` on $path; left unformatted.');
}

/// Single-quoted Dart string literal with the necessary escapes. Non-ASCII is
/// emitted verbatim (Dart source is UTF-8).
String _str(String s) {
  final b = StringBuffer("'");
  for (final r in s.runes) {
    switch (r) {
      case 0x5c: // backslash
        b.write(r'\\');
      case 0x27: // single quote
        b.write(r"\'");
      case 0x24: // dollar
        b.write(r'\$');
      case 0x0a:
        b.write(r'\n');
      case 0x0d:
        b.write(r'\r');
      case 0x09:
        b.write(r'\t');
      default:
        b.writeCharCode(r);
    }
  }
  b.write("'");
  return b.toString();
}

// ── Internal model ──────────────────────────────────────────────────────────

class _Sponsor {
  _Sponsor({
    required this.id,
    required this.slug,
    required this.tier,
    required this.name,
    required this.logoUrl,
    required this.prText,
    required this.links,
    required this.benefits,
    required this.year,
  });

  factory _Sponsor.fromJson(Map<String, dynamic> m) {
    final company = (m['company'] as Map<String, dynamic>?) ?? const {};
    final name = (company['name'] ?? m['name'] ?? '').toString();
    final links = ((company['links'] ?? m['links'] ?? const []) as List)
        .whereType<Map<String, dynamic>>()
        .map(
          (l) => _Link(
            url: (l['url'] ?? '').toString(),
            title: (l['title'] ?? l['url'] ?? '').toString(),
            type: _LinkType.parse((l['type'] ?? '').toString()),
          ),
        )
        .where((l) => l.url.isNotEmpty)
        .toList();
    final slug = (m['slug'] ?? '').toString().trim();
    return _Sponsor(
      id: (m['id'] ?? '').toString(),
      slug: slug.isNotEmpty ? slug : _slugify(name),
      tier: _Tier.parse((m['tier'] ?? '').toString()),
      name: name,
      logoUrl: (company['logoUrl'] ?? m['logoUrl'] ?? '').toString(),
      prText: (m['prText'] ?? '').toString(),
      links: links,
      benefits: ((m['benefits'] ?? const []) as List).map((e) => e.toString()).toList(),
      year: (m['year'] is int) ? m['year'] as int : 2026,
    );
  }

  final String id;
  final String slug;
  final _Tier tier;
  final String name;
  final String logoUrl;
  final String prText;
  final List<_Link> links;
  final List<String> benefits;
  final int year;

  // Filled in during image processing.
  String squareLogo = '';
  String wideLogo = '';
  String ogpImage = _defaultOgp;
}

class _Link {
  _Link({required this.url, required this.title, required this.type});
  final String url;
  final String title;
  final _LinkType type;
}

/// Mirrors `SponsorTier` in `apps/website/lib/constants/sponsors.dart`.
enum _Tier {
  platinum('Platinum'),
  gold('Gold'),
  silver('Silver'),
  bronze('Bronze'),
  tool('Tool'),
  student('Student'),
  community('Community'),
  individual('Individual');

  const _Tier(this.label);
  final String label;

  static _Tier parse(String raw) {
    final v = raw.toLowerCase().trim();
    return switch (v) {
      'platinum' || 'プラチナ' => _Tier.platinum,
      'gold' || 'ゴールド' || '金' => _Tier.gold,
      'silver' || 'シルバー' || '銀' => _Tier.silver,
      'bronze' || 'ブロンズ' || '銅' => _Tier.bronze,
      'tool' || 'ツール' => _Tier.tool,
      'student' || 'スチューデント' || '学生' => _Tier.student,
      'community' || 'コミュニティ' => _Tier.community,
      'individual' || 'インディビジュアル' || '個人' => _Tier.individual,
      _ => _Tier.community,
    };
  }
}

/// Mirrors `SponsorLinkType`.
enum _LinkType {
  x,
  recruit,
  other;

  static _LinkType parse(String raw) => switch (raw.toLowerCase().trim()) {
    'x' || 'twitter' => _LinkType.x,
    'recruit' || 'careers' || 'jobs' => _LinkType.recruit,
    _ => _LinkType.other,
  };
}

String _slugify(String name) {
  final s = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return s.isNotEmpty ? s : 'sponsor';
}
