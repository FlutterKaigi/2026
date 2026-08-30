/// Warns — by default, does not fail — when the Universal Links / App Links
/// `.well-known` files (`apps/website/web/.well-known/`) still carry the
/// placeholder Apple Team ID / SHA-256 fingerprint checked in by PR3 (see
/// issue-594.md and `apps/website/web/.well-known/README.md`'s "本番反映
/// チェックリスト" section).
///
/// Without this check, shipping the placeholders to production is silent:
/// the build and deploy both succeed, and visitors just fall through to the
/// website's `/x/` fallback page instead of the app opening directly — a
/// broken feature with no CI signal. This makes that state visible.
///
/// Run via:
///
/// ```sh
/// fvm dart run melos well-known:check
/// # or directly:
/// dart run tool/check_well_known_placeholders.dart
/// ```
///
/// CI (`deploy_website.yaml` / `preview_website.yaml`) runs this right
/// before the `jaspr build` step on every website deploy, so an unresolved
/// placeholder shows up as a non-blocking GitHub Actions `::warning::`
/// annotation on the run.
///
/// This intentionally warns rather than fails: whether an unresolved
/// placeholder should instead fail CI outright is left as a team decision
/// (see the README) rather than decided unilaterally here. To flip it,
/// set `FAIL_ON_WELL_KNOWN_PLACEHOLDER=true` in the environment (e.g. add
/// `env: FAIL_ON_WELL_KNOWN_PLACEHOLDER: 'true'` to the workflow step) —
/// no code change needed.
library;

import 'dart:io';

const _aasaPath = 'apps/website/web/.well-known/apple-app-site-association';
const _assetlinksPath = 'apps/website/web/.well-known/assetlinks.json';

void main() {
  final failOnPlaceholder = Platform.environment['FAIL_ON_WELL_KNOWN_PLACEHOLDER'] == 'true';
  var foundAny = false;

  final aasa = File(_aasaPath).readAsStringSync();
  // The placeholder appIDs entry is "TEAMID.jp.flutterkaigi.conf2026" — a
  // real 10-character Apple Team ID would never literally read "TEAMID".
  if (aasa.contains('TEAMID.')) {
    _warn(
      _aasaPath,
      'Placeholder Apple Team ID ("TEAMID.") is still present — Universal '
      'Links will not verify until it is replaced with the real Team ID. '
      'See apps/website/web/.well-known/README.md.',
    );
    foundAny = true;
  }

  final assetlinks = File(_assetlinksPath).readAsStringSync();
  // 32 all-zero bytes, colon-separated — the placeholder fingerprint. A real
  // SHA-256 cert fingerprint is for all practical purposes never all zeros.
  if (RegExp(r'(00:){31}00').hasMatch(assetlinks)) {
    _warn(
      _assetlinksPath,
      'Placeholder all-zero SHA-256 fingerprint is still present — App '
      'Links will not verify until it is replaced with the real '
      'release-keystore fingerprint. See apps/website/web/.well-known/README.md.',
    );
    foundAny = true;
  }

  if (!foundAny) {
    stdout.writeln('No Universal Links / App Links placeholders found in apps/website/web/.well-known/.');
    return;
  }

  if (failOnPlaceholder) {
    stderr.writeln(
      'error: Universal Links / App Links placeholders are still present '
      '(FAIL_ON_WELL_KNOWN_PLACEHOLDER=true).',
    );
    exitCode = 1;
  }
}

/// Emits a GitHub Actions `::warning::` annotation when running in Actions
/// (`GITHUB_ACTIONS=true`), or a plain stderr warning otherwise (local runs).
void _warn(String path, String message) {
  if (Platform.environment['GITHUB_ACTIONS'] == 'true') {
    stdout.writeln('::warning file=$path::$message');
  } else {
    stderr.writeln('warning: $path: $message');
  }
}
