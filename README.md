# FlutterKaigi 2026

Monorepo for the FlutterKaigi 2026 website and app.

- `apps/website/` — jaspr static site
- `apps/app/` — Flutter app (iOS / Android, bundle ID `jp.flutterkaigi.conf2026`)
- `packages/` — shared Dart packages (none yet)

Managed with [melos](https://melos.invertase.dev/) (v7) on top of Dart pub workspaces, with Flutter pinned by [FVM](https://fvm.app/).

## Requirements

- [FVM](https://fvm.app/) — pins the Flutter version used by this repo
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
| `fvm dart run melos analyze` | Analyze all packages (website with `dart analyze`, app with `flutter analyze`) |
| `fvm dart run melos format` | `dart format` across all packages |
| `fvm dart run melos test` | Run tests across all packages (website with `dart test`, app with `flutter test`) |

Per-target variants are also available: `analyze:website`, `analyze:app`, `test:website`, `test:app`.

## Running the Flutter app

```bash
cd apps/app
fvm flutter run
```

iOS で初回ビルドする場合は `ios/` ディレクトリで `pod install` が必要になることがあります。

## Layout notes

- **Melos config lives in the root `pubspec.yaml`** under the `melos:` key (melos 7 convention). Package membership is controlled by the root `workspace:` list, and scripts are defined under `melos.scripts:`. There is intentionally no separate `melos.yaml`.
- **`analysis_options.yaml` at the repo root** declares analyzer plugins (e.g., `jaspr_lints`). Dart pub workspaces require plugins at the workspace root, not inside sub-packages.
- **`pubspec.lock` is a single file at the repo root** (pub workspaces merges resolution). Sub-packages should not have their own `pubspec.lock`; delete it if one gets generated.
- **New sub-packages must declare `resolution: workspace`** in their own `pubspec.yaml` (Dart pub workspaces requirement). Otherwise pub treats them as standalone and tries to write a per-package `pubspec.lock`.
