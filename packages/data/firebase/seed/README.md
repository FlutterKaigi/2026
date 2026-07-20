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

`firestore/default.json` seeds one sample document set per editable collection:
`news`, `venues`, `speakers`, `sessions`, `timelineEvents`, `sponsors`,
`staffMembers`, and `live_captions` (rooms plus a few segments). References
between documents use the target document id, so the seeded `sessions` point at
the seeded `venues` (`venueId`) and `speakers` (`speakerIds`), and the seeded
`live_captions` room ids equal venue ids; keep those ids in sync when editing.

Run:

```bash
fvm dart run melos firebase:schema:validate
fvm dart run melos firebase:seed
```
