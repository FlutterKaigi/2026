/// Generates `apps/website/lib/constants/generated_sponsors.dart` and the
/// processed logo images under `apps/website/web/images/logos/` from the
/// `sponsors` Firestore collection managed by `packages/data` (the same data
/// the admin dashboard writes), or a local sample fixture as a fallback.
///
/// NB: the served image directory and the link-icon filenames deliberately
/// avoid the word "sponsor" — ad blockers (EasyList et al.) network-block URLs
/// containing it, which rendered the logos blank. Keep served asset paths
/// neutral.
///
/// Both outputs are **git-ignored** and regenerated on every build, so sponsor
/// data is never committed to the git history (see `.gitignore`).
///
/// Run via:
///
/// ```sh
/// # Local: reads the Firestore emulator (start it + seed first, e.g.
/// #   fvm dart run melos firebase:start  /  fvm dart run melos firebase:seed)
/// fvm dart run melos sponsors:generate
///
/// # STG / prod: point at the real project over HTTPS.
/// FIREBASE_PROJECT_ID=flutterkaigi-2026-stg \
///   FIRESTORE_HOST=firestore.googleapis.com \
///   FIRESTORE_ACCESS_TOKEN=$(gcloud auth print-access-token) \
///   fvm dart run tool/generate_sponsors.dart
/// ```
///
/// Data source (Firestore REST API, mirroring `tool/firebase_seed.dart`):
///   - `FIREBASE_PROJECT_ID`     — defaults to `dev-flutterkaigi-2026`.
///   - `FIRESTORE_EMULATOR_HOST` — when set (or the host is localhost), talk to
///     the emulator over HTTP with the `owner` bearer token.
///   - `FIRESTORE_HOST`          — explicit host for a real project (HTTPS).
///   - `FIRESTORE_ACCESS_TOKEN`  — OAuth bearer token for a real project.
///   - `FIRESTORE_API_KEY`       — optional `?key=` for a real project.
///   - If Firestore is unreachable, fall back to `tool/sponsors/sample_sponsors.json`
///     so offline/preview builds still render placeholders. A *reachable but
///     empty* collection yields an empty site (no fake data).
///
/// Logo handling:
///   - Display logos are used **as-is** from the public bucket: `primaryLogoUrl`
///     → wide (detail banner), `secondaryLogoUrl` → square (home grid, falls
///     back to primary). The bucket URL (webp) is passed straight through to the
///     site; padding / rounded corners / circular cropping are applied in CSS at
///     render time, NOT baked into re-rasterized PNG variants.
///   - The OGP card (1200x630) is the one exception that is still generated
///     server-side: it composites the primary logo onto `web/images/ogp.png` (a
///     branded base that cannot be assembled at display time). It needs a
///     decodable raster; an SVG / undecodable / unreachable primary falls back to
///     the default site OGP — the build never fails because of a single bad logo.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

const _outFile = 'apps/website/lib/constants/generated_sponsors.dart';
const _imagesOutDir = 'apps/website/web/images/logos';
const _ogpBasePath = 'apps/website/web/images/ogp_base.png';
const _sampleFile = 'tool/sponsors/sample_sponsors.json';

// Firestore defaults — kept in sync with tool/firebase_seed.dart.
const _defaultProjectId = 'dev-flutterkaigi-2026';
const _defaultFirestoreHost = 'localhost:8080';

// Asset paths are written relative to the site base href. The directory name
// avoids "sponsor" so ad blockers don't network-block the logo requests.
const _assetPrefix = 'images/logos';
const _defaultOgp = 'images/ogp.png';

// OGP card output size (the only image still generated server-side).
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
  try {
    final sponsors = await _fetchFirestoreSponsors();
    stdout.writeln('Loaded ${sponsors.length} sponsor(s) from Firestore.');
    // A reachable but empty collection is a valid state (e.g. data not seeded
    // yet) — emit an empty site rather than masking it with fake placeholders.
    return _dedupeSlugs(_onlyPublishable(sponsors));
  } catch (e) {
    stderr.writeln(
      'warning: could not load sponsors from Firestore ($e).\n'
      'Falling back to $_sampleFile — placeholder sponsors will be shown.',
    );
    return _dedupeSlugs(_onlyPublishable(_loadSampleSponsors()));
  }
}

/// Temporary publication gate: only sponsors with a configured
/// [`primaryLogoUrl`] are listed on the site for now; logos are being collected
/// progressively and the rest will be published as theirs arrive. (The square
/// home-grid logo falls back to the primary when `secondaryLogoUrl` is unset, so
/// only the primary is required to publish.) Gating here (at the data source)
/// rather than in the website UI is deliberate — the generator otherwise
/// synthesizes branded placeholder logos that the UI cannot tell apart from
/// real ones — and it also skips emitting the hidden sponsors' detail pages, so
/// no orphan routes are produced. Drop this filter to publish everyone.
List<_Sponsor> _onlyPublishable(List<_Sponsor> sponsors) {
  final kept = sponsors.where((s) => s.primaryLogoUrl.trim().isNotEmpty).toList();
  final dropped = sponsors.length - kept.length;
  if (dropped > 0) {
    stdout.writeln('Withholding $dropped sponsor(s) without a primaryLogoUrl (published progressively as logos arrive).');
  }
  return kept;
}

/// Fetches every document in the `sponsors` collection via the Firestore REST
/// API and maps each to the website [_Sponsor] model.
///
/// Talks to the local emulator by default; set the `FIRESTORE_*` /
/// `FIREBASE_PROJECT_ID` env vars (see the library doc) to target STG/prod.
Future<List<_Sponsor>> _fetchFirestoreSponsors() async {
  final projectId = Platform.environment['FIREBASE_PROJECT_ID'] ?? _defaultProjectId;
  final emulatorHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  final host = _normalizeHost(
    Platform.environment['FIRESTORE_HOST'] ?? emulatorHost ?? _defaultFirestoreHost,
  );
  final isEmulator = emulatorHost != null || host.startsWith('localhost') || host.startsWith('127.0.0.1');
  final scheme = isEmulator ? 'http' : 'https';
  final token = Platform.environment['FIRESTORE_ACCESS_TOKEN'];
  final apiKey = Platform.environment['FIRESTORE_API_KEY'];

  stdout.writeln(
    'Fetching sponsors from Firestore '
    '($scheme://$host, project $projectId${isEmulator ? ', emulator' : ''}).',
  );

  final headers = <String, String>{
    'Accept': 'application/json',
    if (isEmulator)
      'Authorization': 'Bearer owner'
    else if (token != null && token.isNotEmpty)
      'Authorization': 'Bearer $token',
  };

  final base =
      '$scheme://$host/v1/projects/${Uri.encodeComponent(projectId)}'
      '/databases/(default)/documents/sponsors';

  final sponsors = <_Sponsor>[];
  String? pageToken;
  do {
    final query = <String>[
      'pageSize=300',
      if (pageToken != null && pageToken.isNotEmpty) 'pageToken=${Uri.encodeComponent(pageToken)}',
      if (apiKey != null && apiKey.isNotEmpty) 'key=${Uri.encodeComponent(apiKey)}',
    ];
    final uri = Uri.parse('$base?${query.join('&')}');
    final resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200) {
      throw HttpException('Firestore returned ${resp.statusCode}: ${resp.body}');
    }
    final decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final docs = (decoded['documents'] as List?) ?? const [];
    for (final doc in docs.whereType<Map<String, dynamic>>()) {
      sponsors.add(_Sponsor.fromModel(_decodeFirestoreDoc(doc)));
    }
    pageToken = decoded['nextPageToken'] as String?;
  } while (pageToken != null && pageToken.isNotEmpty);

  return sponsors;
}

List<_Sponsor> _loadSampleSponsors() {
  final decoded = jsonDecode(File(_sampleFile).readAsStringSync());
  return _extractList(decoded).map(_Sponsor.fromModel).toList();
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

/// Ensures every sponsor has a unique [_Sponsor.slug] (slugs derived from names
/// can collide); appends `-2`, `-3`, … to later duplicates so detail-page
/// routes (`sponsors/{slug}`) never clash.
List<_Sponsor> _dedupeSlugs(List<_Sponsor> sponsors) {
  final counts = <String, int>{};
  for (final s in sponsors) {
    final n = (counts[s.slug] ?? 0) + 1;
    counts[s.slug] = n;
    if (n > 1) s.slug = '${s.slug}-$n';
  }
  return sponsors;
}

String _normalizeHost(String host) {
  var value = host.trim().replaceFirst(RegExp(r'^https?://'), '');
  while (value.endsWith('/')) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}

// ── Firestore REST decoding (inverse of tool/firebase_seed.dart) ────────────

/// Decodes a Firestore REST document (`{name, fields, ...}`) into a plain map
/// of the `packages/data` `Sponsor` model, injecting the doc id.
Map<String, dynamic> _decodeFirestoreDoc(Map<String, dynamic> doc) {
  final name = (doc['name'] ?? '').toString();
  final id = name.contains('/') ? name.split('/').last : name;
  final fields = (doc['fields'] as Map?)?.cast<String, dynamic>() ?? const {};
  return {
    for (final e in fields.entries) e.key: _decodeFirestoreValue(e.value),
    'id': id,
  };
}

/// Inverse of `_encodeFirestoreValue` in `tool/firebase_seed.dart`.
Object? _decodeFirestoreValue(Object? value) {
  final m = (value as Map?)?.cast<String, dynamic>();
  if (m == null) return null;
  if (m.containsKey('nullValue')) return null;
  if (m.containsKey('booleanValue')) return m['booleanValue'];
  if (m.containsKey('integerValue')) {
    return int.tryParse(m['integerValue'].toString());
  }
  if (m.containsKey('doubleValue')) return m['doubleValue'];
  if (m.containsKey('timestampValue')) return m['timestampValue'];
  if (m.containsKey('stringValue')) return m['stringValue'];
  if (m.containsKey('referenceValue')) return m['referenceValue'];
  if (m.containsKey('mapValue')) {
    final fields = ((m['mapValue'] as Map?)?['fields'] as Map?)?.cast<String, dynamic>() ?? const {};
    return {
      for (final e in fields.entries) e.key: _decodeFirestoreValue(e.value),
    };
  }
  if (m.containsKey('arrayValue')) {
    final values = ((m['arrayValue'] as Map?)?['values'] as List?) ?? const [];
    return values.map(_decodeFirestoreValue).toList();
  }
  return null;
}

// ── Image processing ────────────────────────────────────────────────────────

Future<void> _processImages(_Sponsor s, img.Image ogpBase) async {
  // Two logo sources with distinct roles (see the dashboard's primary/secondary
  // logo fields):
  //   - primary  → wide detail-banner logo + the OGP card.
  //   - secondary → square home-grid logo; falls back to the primary when unset,
  //     so a sponsor only needs the one logo to be published.
  final primaryUrl = s.primaryLogoUrl.trim();
  final secondaryUrl = s.secondaryLogoUrl.trim();

  // Display logos are served straight from the public bucket (webp). We no longer
  // re-rasterize padded PNG variants — breathing room, rounded corners, and the
  // circular crop for individual sponsors are all handled in CSS at render time.
  s.wideLogo = primaryUrl;
  s.squareLogo = secondaryUrl.isNotEmpty ? secondaryUrl : primaryUrl;

  // ── OGP card ──
  // The one image we still build server-side: the branded 1200x630 base with the
  // logo composited onto its white card — this can't be assembled at display
  // time. Needs a decodable raster; an SVG/unreachable primary falls back.
  final primaryLogo = await _tryDecodeLogo(primaryUrl, s.slug);
  if (primaryLogo != null) {
    final ogp = _composeOgp(ogpBase, primaryLogo);
    _writePng('${s.slug}-ogp.png', ogp);
    s.ogpImage = '$_assetPrefix/${s.slug}-ogp.png';
  } else {
    s.ogpImage = _defaultOgp;
  }
}

/// Fetches and decodes a raster logo, returning null (with a warning) when the
/// URL is empty, unreachable, or not a decodable raster (e.g. an SVG).
Future<img.Image?> _tryDecodeLogo(String url, String slug) async {
  if (url.isEmpty) return null;
  try {
    final logo = img.decodeImage(await _fetchBytes(url));
    if (logo == null) {
      stderr.writeln('warning: could not decode logo for sponsor $slug ($url)');
    }
    return logo;
  } catch (e) {
    stderr.writeln('warning: could not fetch logo for sponsor $slug ($url): $e');
    return null;
  }
}

Future<Uint8List> _fetchBytes(String url) async {
  // Inline `data:` URI (base64) — lets offline fixtures carry a real logo
  // without a network round-trip or a committed binary asset.
  if (url.startsWith('data:')) {
    final comma = url.indexOf(',');
    if (comma < 0) throw const FormatException('malformed data: URI');
    final isBase64 = url.substring(0, comma).contains(';base64');
    final payload = url.substring(comma + 1);
    return Uint8List.fromList(
      isBase64 ? base64Decode(payload) : utf8.encode(Uri.decodeComponent(payload)),
    );
  }
  final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
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
  final scale = (maxW / src.width) < (maxH / src.height) ? maxW / src.width : maxH / src.height;
  final w = (src.width * scale).round().clamp(1, maxW);
  final h = (src.height * scale).round().clamp(1, maxH);
  return img.copyResize(
    src,
    width: w,
    height: h,
    interpolation: img.Interpolation.cubic,
  );
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

// ── Dart emission ───────────────────────────────────────────────────────────

void _writeDart(List<_Sponsor> sponsors) {
  final out = StringBuffer()
    ..writeln('// GENERATED FILE — do not edit by hand and do not commit.')
    ..writeln('// Source of truth: the `sponsors` Firestore collection (packages/data),')
    ..writeln('// or tool/sponsors/sample_sponsors.json when Firestore is unreachable.')
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
      ..writeln('    name: LocalizedText(ja: ${_str(s.nameJa)}, en: ${_str(s.nameEn)}),')
      ..writeln('    prText: LocalizedText(ja: ${_str(s.prTextJa)}, en: ${_str(s.prTextEn)}),')
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
    required this.nameJa,
    required this.nameEn,
    required this.primaryLogoUrl,
    required this.secondaryLogoUrl,
    required this.prTextJa,
    required this.prTextEn,
    required this.links,
    required this.benefits,
    required this.year,
  });

  /// Maps a decoded `packages/data` `Sponsor` document to the website model.
  ///
  /// The Firestore model differs from the site model: names/descriptions are
  /// [LocaleMap]s (kept as ja/en pairs here and emitted as `LocalizedText`, so
  /// the site resolves them per locale) and links are discrete URL fields
  /// rather than a list. The detail-page slug prefers the admin-entered `slug`
  /// field and falls back to one derived from the opaque Firestore document id
  /// (see [_resolveSlug]); the fallback is deliberately name-free so the
  /// sponsor's name never leaks into URLs, routing tables, or CI build logs
  /// (a privacy requirement: leave no name trace once the event is over).
  factory _Sponsor.fromModel(Map<String, dynamic> m) {
    final id = (m['id'] ?? '').toString();
    final name = _localeMap(m['name']);
    // Fall back across locales so a sponsor with only one language still has
    // both fields populated (the site's per-locale resolve also falls back).
    final nameJa = _firstNonEmpty([name['ja'], name['en']]);
    final nameEn = _firstNonEmpty([name['en'], name['ja']]);
    final description = _localeMap(m['description']);
    final prTextJa = _firstNonEmpty([description['ja'], description['en']]);
    final prTextEn = _firstNonEmpty([description['en'], description['ja']]);

    final links = <_Link>[];
    void addLink(Object? url, String title, _LinkType type) {
      final u = (url ?? '').toString().trim();
      if (u.isNotEmpty) links.add(_Link(url: u, title: title, type: type));
    }

    // Order mirrors the detail page's expected priority: site, social, careers.
    addLink(m['websiteUrl'], 'Web', _LinkType.other);
    addLink(m['xUrl'], 'X', _LinkType.x);
    addLink(m['recruitUrl'], '採用情報', _LinkType.recruit);
    addLink(m['jobBoardUrl'], '採用一覧', _LinkType.jobBoard);

    return _Sponsor(
      id: id,
      slug: _resolveSlug(m['slug'], id),
      tier: _Tier.parse((m['tier'] ?? '').toString()),
      nameJa: nameJa,
      nameEn: nameEn,
      primaryLogoUrl: (m['primaryLogoUrl'] ?? '').toString(),
      secondaryLogoUrl: (m['secondaryLogoUrl'] ?? '').toString(),
      prTextJa: prTextJa,
      prTextEn: prTextEn,
      links: links,
      benefits: const [],
      year: _yearOf(m['createdAt']),
    );
  }

  final String id;
  String slug;
  final _Tier tier;
  final String nameJa;
  final String nameEn;
  final String primaryLogoUrl;
  final String secondaryLogoUrl;
  final String prTextJa;
  final String prTextEn;
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
  individual('Individual')
  ;

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
enum _LinkType { x, recruit, jobBoard, other }

/// Detail-page slug: prefers the admin-entered `slug` field, falling back to
/// one derived from the opaque document id. Both are run through [_slugFromId]
/// so the result is always URL-safe.
String _resolveSlug(Object? slug, String id) {
  final provided = (slug ?? '').toString().trim();
  return _slugFromId(provided.isNotEmpty ? provided : id);
}

/// Sanitizes a slug source to a URL-safe slug. Auto-generated Firestore ids are
/// already URL-safe (`[A-Za-z0-9]`); case is preserved so distinct ids never
/// collide. Any stray character is replaced with `-`. The document-id fallback
/// is deliberately name-free — see [_Sponsor.fromModel].
String _slugFromId(String id) {
  final s = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  return s.isNotEmpty ? s : 'sponsor';
}

/// Coerces a value into a `{ja, en}` string map (Firestore `LocaleMap`).
Map<String, String> _localeMap(Object? value) {
  final m = (value as Map?) ?? const {};
  return {
    for (final e in m.entries) e.key.toString(): (e.value ?? '').toString(),
  };
}

String _firstNonEmpty(List<String?> candidates) =>
    candidates.firstWhere((c) => c != null && c.trim().isNotEmpty, orElse: () => '')!.trim();

/// Year derived from an ISO-8601 `createdAt` timestamp; defaults to 2026.
int _yearOf(Object? createdAt) {
  if (createdAt is String) {
    final dt = DateTime.tryParse(createdAt);
    if (dt != null) return dt.year;
  }
  return 2026;
}
