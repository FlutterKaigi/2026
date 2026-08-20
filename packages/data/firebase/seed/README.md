# Firebase Seed Data

Seed files are small, reviewable fixtures for local development.

`firestore/default.json` uses this shape:

```json
{
  "projectId": "dev-flutterkaigi-2026",
  "documents": [
    {
      "path": "news/example",
      "schema": "news",
      "data": {}
    }
  ]
}
```

The `schema` value maps to `packages/data/firebase/schemas/firestore/{schema}.schema.json`.

`firestore/default.json` seeds one sample document set per collection this repo
owns: `news`, `venues`, `sponsors` and `staffMembers`.

`sessions`, `speakers` and `timelineEvents` are deliberately **not** seeded.
Sessionize owns them, and `tool/import_sessions.dart` writes them under
Sessionize's own document ids — seeding fixtures under different ids would leave
both copies in the emulator and render every slot twice. Populate them the same
way STG does:

```bash
SESSIONIZE_ENDPOINT_ID=xxxxxxxx fvm dart run melos sessions:import
```

The import matches Sessionize rooms against `venues` by name, so seed first.

Run:

```bash
fvm dart run melos firebase:schema:validate
fvm dart run melos firebase:seed
```
