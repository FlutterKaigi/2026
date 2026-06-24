# Firebase Schemas

This directory keeps JSON Schema files for Firestore document shapes.

Only one sample schema is committed for now:

- `firestore/news.schema.json`

When a new collection becomes necessary:

1. Add one schema under `firestore/`.
2. Add or update seed data under `../seed/firestore/`.
3. Update `../firestore.rules` and `../firestore.indexes.json` only for the collection being introduced.
4. Run `fvm dart run melos firebase:schema:validate`.

Keep schemas small and concrete. Avoid defining collections before product code needs them.
