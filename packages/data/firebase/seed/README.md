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
owns: `news`, `venues`, `sponsors`, `staffMembers`, `users` and
`users/{uid}/exchanges`.

`users` documents are normally created by attendees from the app (the document
id is their Firebase Auth uid). The seeded `users/seed-user-*` profiles only
exist so other attendees' profiles can be viewed locally; they are not tied to
any Auth Emulator account.

`users/{uid}/exchanges/{otherUid}` documents are normally created by the app
(on scan) and mirrored by a Cloud Function trigger. The seed includes one
mutual exchange between `seed-user-001` and `seed-user-002` (one `scan` side
and one `mirror` side) so the exchange list can be viewed locally without
running the emulator's Functions trigger. `counters/profileExchanges` is
seeded to match.

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
