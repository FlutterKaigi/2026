# Firebase Schemas

This directory keeps JSON Schema files for Firestore document shapes. Each
schema describes the document fields only — the document id is not a field and
is therefore not part of the schema. Timestamp fields (`createdAt`,
`updatedAt`, `startsAt`, …) are written as Firestore timestamps and documented
here as ISO-8601 `date-time` strings.

Schemas committed so far, including server-managed collections:

- `firestore/counters.schema.json` (`counters`, written by Cloud Functions, not the app or the dashboard)
- `firestore/news.schema.json` (`news`)
- `firestore/profile_exchange.schema.json` (`users/{uid}/exchanges`, written by the app, not the dashboard)
- `firestore/session.schema.json` (`sessions`)
- `firestore/speaker.schema.json` (`speakers`)
- `firestore/sponsor.schema.json` (`sponsors`)
- `firestore/staff_member.schema.json` (`staffMembers`)
- `firestore/support_lt_settings.schema.json` (`supportLtSettings/current`, written only by `issueSupportLtCode`)
- `firestore/support_lt_registration.schema.json` (`supportLtRegistrations/{uid}`, written only by `registerSupportLt`)
- `firestore/support_lt_registration_attempts.schema.json` (`supportLtRegistrationAttempts/{uid}` and `supportLtSettings/attempts`, server-only rate limits)
- `firestore/timeline_event.schema.json` (`timelineEvents`)
- `firestore/user_profile.schema.json` (`users`, written by the app, not the dashboard)
- `firestore/venue.schema.json` (`venues`)

Each file mirrors the matching model under `../../lib/src/model/`. When a model
changes, update its schema in the same change. Server-only fields and collections
also document their Cloud Functions contract. Support LT uses Firestore timestamps
in documents and epoch milliseconds in callable responses; its code is a string
so leading zeroes survive. Registration does not require a user profile. Codes,
registrations, and attempts have no seed data: issue and register through the
local callables so code validation and attendee identity are exercised.

When a new collection becomes necessary:

1. Add one schema under `firestore/`, named after the model (e.g. `venue.schema.json`).
2. Add or update seed data under `../seed/firestore/` (a seed document references
   its schema by file name via the `schema` field).
3. Update `../firestore.rules` and `../firestore.indexes.json` only for the collection being introduced.
4. Run `fvm dart run melos firebase:schema:validate`.

Keep schemas small and concrete. Avoid defining collections before product code needs them.
