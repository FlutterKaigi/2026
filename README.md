# FlutterKaigi 2026

Monorepo for the FlutterKaigi 2026 website, attendee app, dashboard, and venue tooling.

- `apps/website/` — jaspr static site
- `apps/app/` — Flutter app (iOS / Android / Web)
- `apps/dashboard/` — Flutter web app (dashboard)
- `apps/venue_screen/` — prototype transparent Flutter web caption overlay for OBS
- `tools/caption_relay/` — prototype local-only caption ingest and WebSocket relay
- `packages/caption_protocol/` — shared versioned caption event contract
- `packages/` — shared Dart packages

Managed with [melos](https://melos.invertase.dev/) (v7) on top of Dart pub workspaces, with Flutter pinned by [FVM](https://fvm.app/).

## Requirements

- [FVM](https://fvm.app/) — pins the Flutter version used by this repo
- Node.js/npm — used to run Firebase Emulator Suite through `npx`
- [jaspr_cli](https://pub.dev/packages/jaspr_cli) — needed only if you regenerate the website scaffold outside melos

All other Dart/Flutter tooling is provided by FVM once installed.

## First-time setup

```bash
# 1. Install FVM (one-time, global)
dart pub global activate fvm

# 2. Install the Flutter version pinned in .fvmrc
fvm install

# 3. Resolve workspace dependencies (installs melos + all package deps)
fvm dart pub get

# 4. Bootstrap melos (generates IDE files; dependency resolution is already done by step 3)
fvm dart run melos bootstrap
```

The pinned Flutter version is `3.41.7` (see `.fvmrc`).

## Common commands

| Command | What it does |
| --- | --- |
| `fvm dart run melos website:serve` | Run the jaspr website dev server on `http://localhost:8080` |
| `fvm dart run melos website:build` | Build the jaspr website to `apps/website/build/jaspr/` |
| `fvm dart run melos dashboard:run:dev` | Run the dashboard app in Chrome (dev / emulator) |
| `fvm dart run melos dashboard:run:stg` | Run the dashboard app in Chrome (stg) |
| `fvm dart run melos dashboard:run:prod` | Run the dashboard app in Chrome (prod) |
| `fvm dart run melos dashboard:build:dev` | Build the dashboard app for web (dev / emulator) |
| `fvm dart run melos dashboard:build:stg` | Build the dashboard app for web (stg) |
| `fvm dart run melos dashboard:build:prod` | Build the dashboard app for web (prod) |
| `fvm dart run melos venue-screen:build` | Build the venue caption overlay |
| `fvm dart run melos caption-relay:serve` | Serve the built overlay and local caption relay |
| `fvm dart run melos caption-relay:replay` | Replay anonymous rehearsal captions through the relay |
| `fvm dart run melos firebase:emulators` | Run Firebase Emulator Suite for local development |
| `fvm dart run melos firebase:schema:validate` | Validate Firebase seed data against the sample schema |
| `fvm dart run melos firebase:seed` | Seed the running Firestore emulator with sample data |
| `fvm dart run melos firebase:test` | Start Firestore Emulator and load local seed data |
| `cp apps/app/lib/firebase_options.stub.dart apps/app/lib/firebase_options.dart` | Prepare the ignored Web Firebase stub for local app development |
| `cd apps/app && fvm flutter run -d chrome --dart-define-from-file environments/.env.dev` | Run the Flutter app with dev environment variables |
| `fvm dart run melos gen` | Regenerate Freezed/build_runner outputs for `apps/app` and `packages/data` |
| `fvm dart run melos analyze` | Analyze all packages (website with `dart analyze`; app, dashboard, and `packages/data` with `flutter analyze`) |
| `fvm dart run melos format` | `dart format` across all packages |
| `fvm dart run melos test` | Run tests across all packages (website with `dart test`; app, dashboard, and `packages/data` with `flutter test`) |

Per-target variants are also available for the website, attendee app, dashboard, venue screen, caption protocol, caption relay, and data package.

Venue caption setup and OBS operating procedures are documented in
[apps/venue_screen/README.md](apps/venue_screen/README.md) and
[docs/venue-subtitles/RUNBOOK.md](docs/venue-subtitles/RUNBOOK.md).

The venue-screen implementation is a technical prototype, not an approved
production system. Production use requires the organizational, equipment,
readability, recording, and fallback gates in
[docs/venue-subtitles/ACCEPTANCE.md](docs/venue-subtitles/ACCEPTANCE.md). The
attendee-app subtitle path remains mandatory parallel work owned by the app
team; it is intentionally outside the scope of this branch and must be ready
as an independent fallback.

## Firebase local development

Firebase configuration lives at the repository root and under `packages/data/firebase/`.

- `.firebaserc` is intentionally not committed. Local emulator commands pass the dev project ID explicitly.
- `firebase.json` is kept at the repository root for Firebase CLI discovery.
- Firestore/Storage rules, indexes, schemas, and seed data live under `packages/data/firebase/`.
- App dev environment variables live in `apps/app/environments/.env.dev` and are passed with `--dart-define-from-file`.
- VS Code launch/tasks live in `.vscode/` and only define local/dev commands.
- `packages/data/firebase/schemas/firestore/news.schema.json` is the only sample schema for now. Add more schemas only when product code needs them.
- `packages/data/firebase/seed/firestore/default.json` contains reviewable local sample data.

See [packages/data/firebase/README.md](packages/data/firebase/README.md) for emulator, schema, and seed details.

## Layout notes

- **Melos config lives in the root `pubspec.yaml`** under the `melos:` key (melos 7 convention). Package membership is controlled by the root `workspace:` list, and scripts are defined under `melos.scripts:`. There is intentionally no separate `melos.yaml`.
- **`analysis_options.yaml` at the repo root** declares analyzer plugins (e.g., `jaspr_lints`). Dart pub workspaces require plugins at the workspace root, not inside sub-packages.
- **`pubspec.lock` is a single file at the repo root** (pub workspaces merges resolution). Sub-packages should not have their own `pubspec.lock`; delete it if one gets generated.
- **Firebase local state is not committed.** Rules, indexes, schemas, and seed fixtures are committed; `.firebaserc`, emulator exports, debug logs, `.env` files, and service account JSON files are not.
