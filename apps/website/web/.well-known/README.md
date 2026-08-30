# Universal Links / App Links — `.well-known` setup

These two files let iOS (Universal Links) and Android (App Links) hand a
`https://2026.flutterkaigi.jp/x/<token>` profile-exchange share link
(`apps/app/lib/feature/exchange/data/exchange_link.dart`) straight to the
FlutterKaigi 2026 app instead of opening it in a browser. The app-side
declarations are:

- iOS: `apps/app/ios/Runner/Runner.entitlements` and
  `Runner.prod.entitlements` — `com.apple.developer.associated-domains` =
  `applinks:2026.flutterkaigi.jp`.
- Android: `apps/app/android/app/src/main/AndroidManifest.xml` — the
  `android:autoVerify="true"` intent filter on `MainActivity` for
  `https://2026.flutterkaigi.jp/x/*`.

Both platforms independently fetch these two files over HTTPS (no app
involved) to verify the app is actually allowed to claim the domain, so they
must be reachable at exactly `/.well-known/apple-app-site-association` and
`/.well-known/assetlinks.json` with no redirects, and (for AASA specifically)
served as `application/json` — see `web/_headers`, which sets that
explicitly since the file itself has no extension for a static file server to
infer a content type from.

## Values that are placeholders in this repo

Neither value below exists anywhere in this repository (verified by
grepping for `DEVELOPMENT_TEAM` / `TeamID` / `sha256` / `keytool` across the
repo) — CI injects the real ones as GitHub Actions secrets/vars at
deploy time (`APPLE_TEAM_ID` in `.github/workflows/deploy_app_ios.yaml`,
`ANDROID_SIGNING_KEYSTORE_BASE64` in `deploy_app_android.yaml`), so they
cannot be filled in from the codebase alone.

### `apple-app-site-association`: `appIDs`

Replace `TEAMID` in `"TEAMID.jp.flutterkaigi.conf2026"` with the real Apple
Developer Team ID (10 characters, e.g. `ABCDE12345`) — the same value stored
in the `APPLE_TEAM_ID` GitHub Actions variable used by
`deploy_app_ios.yaml`. Find it at
<https://developer.apple.com/account/#/membership/> ("Team ID").

The bundle id here is the plain production one
(`PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj`,
`jp.flutterkaigi.conf2026${APP_ID_SUFFIX}` with an empty suffix for
release). If dev/stg build flavors ever need Universal Links too, add their
suffixed bundle ids (e.g. `TEAMID.jp.flutterkaigi.conf2026.dev`) as
additional entries in the `appIDs` array — one `details` entry can list
multiple app IDs sharing the same `components`.

### `assetlinks.json`: `sha256_cert_fingerprints`

Replace the zeroed-out placeholder with the SHA-256 fingerprint of the
signing certificate for the **release** keystore used by
`deploy_app_android.yaml` (`ANDROID_SIGNING_KEYSTORE_BASE64`). Compute it
from that same keystore with:

```sh
keytool -list -v -keystore <the-release-keystore>.jks | grep 'SHA256:'
```

Format it as continuous uppercase hex with colon separators (the format
`keytool` already prints), e.g.
`14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BB:F5:41:CC:9C:69:2F:CB:04:1E`.

If Google Play App Signing is enabled (recommended, and the default for new
Play Console apps), also add the **Play-side signing certificate**'s SHA-256
fingerprint from Play Console → *App integrity* → *App signing key
certificate* as a second entry in the array — the app is served to users
signed with that key, not the upload key, once Play re-signs it.

Also update `ANDROID_PACKAGE_NAME`-derived `package_name` above if the
production application id (`android/app/build.gradle.kts`, currently
`jp.flutterkaigi.conf2026`) ever changes.

## Verifying after deploy

- AASA: `curl -s https://2026.flutterkaigi.jp/.well-known/apple-app-site-association | jq .`
  should return the JSON above with the real Team ID, `Content-Type:
  application/json`, and no redirect (`curl -sI ... | grep -i location`
  should print nothing).
- assetlinks.json: Google's [Statement List Generator / validator]
  (https://developers.google.com/digital-asset-links/tools/generator) against
  `https://2026.flutterkaigi.jp` and the package name above.
- End-to-end: on a real device (Universal Links / App Links are not testable
  in the iOS Simulator or before the app has been installed at least once
  after the domain association is live), open a `https://2026.flutterkaigi.jp/x/...`
  link from Messages/Notes (iOS) or any app (Android) and confirm it opens
  FlutterKaigi 2026 directly rather than the browser fallback page
  (`apps/website/lib/pages/app_link_fallback.dart`).
- Re-verification can take a while to propagate (iOS refetches AASA on app
  install/update and periodically; Android verifies on install). Uninstalling
  and reinstalling the app forces a re-check on both platforms.
