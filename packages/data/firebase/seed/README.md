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

Run:

```bash
fvm dart run melos firebase:schema:validate
fvm dart run melos firebase:seed
```
