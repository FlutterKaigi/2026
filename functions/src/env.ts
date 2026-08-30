/** Firestore/Functions エミュレータ上で実行中かどうか。 */
export const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";
