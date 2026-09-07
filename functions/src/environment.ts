/** Whether the current process is the Firebase Emulator Suite. */
export const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";

/**
 * Region for every function in this codebase. `index.ts`'s `setGlobalOptions`
 * also sets this, but `export ... from "./profile_exchange"` is evaluated as
 * a dependency before `index.ts`'s own module body runs, so the functions
 * defined in `profile_exchange.ts` would otherwise be created with `onCall` /
 * `onDocumentCreated` / `onDocumentDeleted`'s default region (`us-central1`)
 * rather than this one. Each function there sets `region: FUNCTIONS_REGION`
 * explicitly to avoid depending on that evaluation order.
 */
export const FUNCTIONS_REGION = "asia-northeast1";
