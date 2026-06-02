# Firebase

This directory contains Firebase files owned by `packages/data`.

The repository root still has `firebase.json` because Firebase CLI discovers
configuration from the working directory. That file points back into this
directory for rules, indexes, schemas, and seed data.

## Scope

This setup is intentionally local/dev only for now.

- Local project ID: `dev-flutterkaigi-2026`
- Firestore Emulator: `localhost:8080`
- Emulator UI: `localhost:4000`
- App environment file: `apps/app/environments/.env.dev`

Production and staging are expected later, but should be added as separate
environment files and commands when real Firebase projects exist.

## Layout

```text
packages/data/firebase/
  firestore.rules
  firestore.indexes.json
  storage.rules
  schemas/
    firestore/
      news.schema.json
  seed/
    firestore/
      default.json
```

## Local Startup

Run commands from the repository root.

```bash
fvm dart run melos firebase:emulators
```

In another terminal, seed Firestore.

```bash
fvm dart run melos firebase:seed
```

Then start the Flutter app with the dev environment.

```bash
cd apps/app
fvm flutter run -d chrome --dart-define-from-file environments/.env.dev
```

To load seed data into a fresh Firestore Emulator:

```bash
fvm dart run melos firebase:test
```

This starts Firestore Emulator and applies the seed data. The data path itself
is exercised by running the Flutter app against the emulator.

## Schemas

Schemas document Firestore document shapes and validate local seed data. They
are not Firestore runtime enforcement.

Only one sample schema is committed for now:

- `schemas/firestore/news.schema.json`

Add new schemas only when product code actually needs a new collection. Avoid
pre-building a full database model before the app has those use cases.

## Seed Data

`seed/firestore/default.json` contains small, reviewable local fixtures.

Each document has:

- `path`: Firestore document path, such as `news/sponsorship-guide`
- `schema`: schema name under `schemas/firestore/{schema}.schema.json`
- `data`: plain JSON data that gets converted into Firestore REST values

Validate seed data without starting the emulator:

```bash
fvm dart run melos firebase:schema:validate
```

## Data Package Boundary

`packages/data/lib` owns the Dart API used by the app.

The intended flow is:

```text
Firestore Emulator
  -> cloud_firestore (FirebaseFirestore)
  -> repository
  -> app-facing model
```

Keep app-facing models small. A model does not need to mirror every field in the
seed/schema if the app does not use that field yet. Use schemas and seed data to
document Firestore shape; use Dart models to expose what product code reads.

## Rules And Indexes

- `firestore.rules` should only expose collections that are needed.
- `firestore.indexes.json` should only include indexes required by implemented queries.
- `storage.rules` exists for future local Storage work, but the current sample reads Firestore only.

## Git Management

Commit these files:

- `firebase.json`
- `packages/data/firebase/firestore.rules`
- `packages/data/firebase/firestore.indexes.json`
- `packages/data/firebase/storage.rules`
- `packages/data/firebase/schemas/**`
- `packages/data/firebase/seed/**`
- `packages/data/lib/**`
- `tool/firebase_seed.dart`

Do not commit local runtime state or credentials:

- `.firebase/`
- `.firebaserc`
- `packages/data/firebase/emulator-data/`
- `*-debug.log`
- service account JSON files
- `.env` files containing secrets

The local commands pass the dev project ID explicitly instead of relying on
`.firebaserc`.
