# FlutterKaigi 2026

Monorepo for the FlutterKaigi 2026 website and app.

- `apps/website/` — jaspr static site
- `apps/app/` — Flutter app (iOS / Android)
- `apps/broadcaster/` — Flutter desktop tool that streams venue audio to the captions server
- `packages/` — shared Dart packages
- `services/captions_server/` — pure Dart live-captions server (WebSocket audio in, translated captions out)

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
| `fvm dart run melos firebase:emulators` | Run Firebase Emulator Suite for local development |
| `fvm dart run melos firebase:schema:validate` | Validate Firebase seed data against the sample schema |
| `fvm dart run melos firebase:seed` | Seed the running Firestore emulator with sample data |
| `fvm dart run melos firebase:test` | Start Firestore Emulator and load local seed data |
| `fvm dart run melos captions:serve` | Run the captions server locally on port 8082 (fake transcriber + echo translator) |
| `fvm dart run melos captions:serve:live` | Run the captions server with real Gemini transcription + translation (set `GEMINI_API_KEY` via env or `services/captions_server/config.local.json`) |
| `fvm dart run melos captions:smoke` | Stream synthetic audio to the running captions server and check captions are returned (pass a PCM16/16kHz/mono WAV path for real speech) |
| `cd apps/app && fvm flutter run -d chrome --dart-define-from-file environments/.env.dev` | Run the Flutter app with dev environment variables |
| `fvm dart run melos gen` | Regenerate Freezed/build_runner outputs for `apps/app` and `packages/data` |
| `fvm dart run melos analyze` | Analyze all packages (website with `dart analyze`; app and `packages/data` with `flutter analyze`) |
| `fvm dart run melos format` | `dart format` across all packages |
| `fvm dart run melos test` | Run tests across all packages (website with `dart test`; app and `packages/data` with `flutter test`) |

Per-target variants are also available: `analyze:website`, `analyze:app`, `test:website`, `test:app`.

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
