/**
 * 全 Cloud Functions 共通のデプロイリージョン。
 *
 * `setGlobalOptions({ region: ... })`（`index.ts`）だけに頼らないのは、
 * TypeScript が CommonJS へトランスパイルする際に `import` 文が
 * ファイル本体の他の文より先に `require(...)` として実行されるため。
 * `exchange/callable.ts` や `exchange/triggers.ts` を `index.ts` が
 * `import` すると、それらのファイル内で `onCall(...)` /
 * `onDocumentCreated(...)` が**モジュール読み込み時に**即時評価され、
 * `setGlobalOptions` が呼ばれるより前に `__endpoint.region` が
 * 確定してしまう（実測: 対策前は region が `undefined` になっていた）。
 * そのため各関数の options に `region: REGION` を明示し、
 * import 順序に依存しないようにする。
 */
export const REGION = "asia-northeast1";
