# FlutterKaigi 2026

Monorepo for the FlutterKaigi 2026 website and app.

- `apps/website/` — jaspr static site
- `apps/app/` — Flutter app (added later by the mobile maintainer)
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

## Adding the Flutter app

When the Flutter maintainer joins, they need to:

1. **Create the app** in the correct location:

    ```bash
    cd apps
    fvm flutter create app
    ```

2. **Declare the app as a workspace member**. Edit the top-level `pubspec.yaml` and add `apps/app` to the `workspace:` list:

    ```yaml
    workspace:
      - apps/website
      - apps/app
    ```

3. **Mark the app package as a workspace resolution target**. Edit `apps/app/pubspec.yaml` and add `resolution: workspace` near the top (Dart pub workspaces requirement):

    ```yaml
    name: app
    resolution: workspace
    environment:
      sdk: ">=3.11.0 <4.0.0"
      flutter: ">=3.41.0"
    # ...
    ```

4. **Delete the generated `pubspec.lock` inside `apps/app/`** — there is only one shared lockfile at the repo root with Dart pub workspaces.

5. **Re-run** `fvm dart pub get` at the repo root. `fvm dart run melos analyze` and `fvm dart run melos test` will now include the app automatically.

## Layout notes

- **Melos config lives in the root `pubspec.yaml`** under the `melos:` key (melos 7 convention). Package membership is controlled by the root `workspace:` list, and scripts are defined under `melos.scripts:`. There is intentionally no separate `melos.yaml`.
- **`analysis_options.yaml` at the repo root** declares analyzer plugins (e.g., `jaspr_lints`). Dart pub workspaces require plugins at the workspace root, not inside sub-packages.
- **`pubspec.lock` is a single file at the repo root** (pub workspaces merges resolution). Sub-packages should not have their own `pubspec.lock`; delete it if one gets generated.
