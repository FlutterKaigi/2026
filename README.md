# FlutterKaigi 2026

Monorepo for the FlutterKaigi 2026 website and app.

- `apps/website/` — jaspr static site
- `apps/app/` — Flutter app (added later by the mobile maintainer)
- `packages/` — shared Dart packages (none yet)

## Requirements

- [FVM](https://fvm.app/) — pins the Flutter version used by this repo
- [jaspr_cli](https://pub.dev/packages/jaspr_cli) — needed only if you regenerate or inspect the website scaffold outside melos

All other Dart/Flutter tooling is provided by FVM once installed.

## First-time setup

```bash
# 1. Install FVM (one-time, global)
dart pub global activate fvm

# 2. Install the Flutter version pinned in .fvmrc
fvm install

# 3. Fetch root dev dependencies (installs melos)
fvm dart pub get

# 4. Bootstrap all workspace packages
fvm dart run melos bootstrap
```

The pinned Flutter version is `3.41.7` (see `.fvmrc`).

## Common commands

| Command | What it does |
| --- | --- |
| `fvm dart run melos website:serve` | Run the jaspr website dev server |
| `fvm dart run melos website:build` | Build the jaspr website to `apps/website/build/jaspr/` |
| `fvm dart run melos analyze` | `dart analyze` across all packages |
| `fvm dart run melos format` | `dart format` across all packages |
| `fvm dart run melos test` | Run tests in every package that has a `test/` directory |

## Layout conventions

- `apps/**` and `packages/**` are globbed by melos; any new package added under those directories is picked up automatically after `melos bootstrap`.
- The Flutter app lives at `apps/app/` once the mobile maintainer creates it (`cd apps && fvm flutter create app`). No action is required here to reserve that path.
