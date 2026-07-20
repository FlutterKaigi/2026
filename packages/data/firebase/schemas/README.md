# Firebase Schemas

This directory keeps JSON Schema files for Firestore document shapes. Each
schema describes the document fields only — the document id is not a field and
is therefore not part of the schema. Timestamp fields (`createdAt`,
`updatedAt`, `startsAt`, …) are written as Firestore timestamps and documented
here as ISO-8601 `date-time` strings.

Schemas committed so far, one per editable collection used by the dashboard:

- `firestore/live_caption_room.schema.json` (`live_captions`)
- `firestore/live_caption_segment.schema.json` (`live_captions/{roomId}/segments`)
- `firestore/news.schema.json` (`news`)
- `firestore/session.schema.json` (`sessions`)
- `firestore/speaker.schema.json` (`speakers`)
- `firestore/sponsor.schema.json` (`sponsors`)
- `firestore/staff_member.schema.json` (`staffMembers`)
- `firestore/timeline_event.schema.json` (`timelineEvents`)
- `firestore/venue.schema.json` (`venues`)

Each file mirrors the matching model under `../../lib/src/model/`. When a model
changes, update its schema in the same change.

When a new collection becomes necessary:

1. Add one schema under `firestore/`, named after the model (e.g. `venue.schema.json`).
2. Add or update seed data under `../seed/firestore/` (a seed document references
   its schema by file name via the `schema` field).
3. Update `../firestore.rules` and `../firestore.indexes.json` only for the collection being introduced.
4. Run `fvm dart run melos firebase:schema:validate`.

Keep schemas small and concrete. Avoid defining collections before product code needs them.
