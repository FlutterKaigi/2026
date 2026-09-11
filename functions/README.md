# Cloud Functions

FlutterKaigi 2026 の Cloud Functions。STG → 本番のデータ反映用の
`syncCollectionsToProd`、プロフィール交換用の各種関数、応援 LT 参加登録を提供する。

## 応援 LT 参加登録

`src/support_lt.ts` が callable / Auth トリガーを公開し、
`src/support_lt_service.ts` が認可と Firestore トランザクションを実装する。
リージョンは `asia-northeast1`、本番の callable は App Check を必須にする。

- `issueSupportLtCode({ rotate?: boolean })` は確認済み `@flutterkaigi.jp` アカウントかつ
  `admins/{uid}` 登録済みの管理者のみ呼び出せる。先頭のゼロを保持する 6 桁の文字列を
  発行し、`{ code, issuedAt }` を返す。時刻は **Unix epoch ミリ秒**。
  コードに有効期限はなく、発行済みのコードがあれば同じコードを返す。`rotate: true` は
  必ず直前と異なるコードを発行し、旧コードを同じトランザクションで無効にする。
  コードは参加者ごとに消費せず、何人でも利用できる。管理者判定は
  `src/admin_auth.ts` の `assertAdmin` を `syncCollectionsToProd` と共有する。
- `registerSupportLt({ code: string })` は匿名認証以外のサインイン済みユーザーが
  利用できる。プロフィール作成は不要。現在のコードとの一致を検証し、
  `supportLtRegistrations/{uid}` を作成して `{ registeredAt, alreadyRegistered }` を返す。
  `registeredAt` は epoch ミリ秒。複数回・同時の呼び出しでも 1 人 1 件となり、
  既存の登録日時と名前を保持する。登録済みならコード更新後も成功を返す。
  表示名は登録時のプロフィール名 → Auth 名 → uid の順で選び、メールは保存しない。
- 失敗したコード検証は `supportLtRegistrationAttempts/{uid}` に保存し、10 分以内の
  10 回失敗で以後 10 分間拒否する。加えて全アカウント合計の失敗を
  `supportLtSettings/attempts` に 10 分単位のバケットごとに記録し、同じバケットで
  200 回失敗するとそのバケットが終わるまでコード自体をロックする（使い捨て
  アカウントによる総当たり対策）。ロックは `rotate: true` での再発行でも解除される。
  10 回目とロック中は `resource-exhausted`、不一致・未発行は `not-found`、
  入力形式不正は `invalid-argument`。uid 単位の失敗回数の更新は例外を投げる前に
  コミットし、並行リクエストでも制限を適用する。全体カウンタは単一のホットな
  ドキュメントなのでトランザクションには含めず、判定は通常の読み取り、更新は
  コミット後の `FieldValue.increment` で行う（ロック競合による ABORTED を防ぐ）。
  プロフィール `users/{uid}` はコード一致後にのみ読み取る。
- `onSupportLtUserDeleted` は Firebase Auth のアカウント削除時に登録と失敗試行を
  削除する。プロフィールがないユーザーも対象となる。Auth lifecycle のため
  第 1 世代 Function を使用し、失敗時の再試行を有効にする。

callable は削除・無効化済みアカウントの古い ID トークンを受け付けない。
`src/support_lt_auth.ts` で Auth アカウント状態を確認する。登録時は Firestore
トランザクションで登録ドキュメントを読み取った直後、ロックを保持して Auth を確認する。
Auth 削除トリガーのバッチはこのロックが解放されるまで待機するため、実行中の
リクエストと削除が競合しても登録・失敗試行を再作成したままにしない。
Auth の一時障害時は書き込み前にトランザクションを中止する。削除済みアカウントの
追加クリーンアップはロックを解放した後に行う。無効化（disable）されたアカウントは
拒否するが、再有効化に備えて登録は削除しない。コード発行も有効な Auth アカウントを要求する。

この順序保証には Firestore **Standard edition の `PESSIMISTIC` concurrency mode**
（既定値）が必要。`OPTIMISTIC` へ変更する場合は削除との排他設計を再検討すること。
根拠: [Firestore のトランザクションとデータ競合](https://firebase.google.com/docs/firestore/transaction-data-contention)。

Firestore では `supportLtSettings/current` を管理者のみ参照可能とし、参加登録は
本人の `get` または管理者の `get/list` のみ許可する。ダッシュボードは参加者一覧から
人数を求める。管理者を含むすべてのクライアントの直接書き込み・削除を禁止し、
失敗試行コレクションは読み取りも禁止する。スキーマは
`packages/data/firebase/schemas/firestore/support_lt_*.schema.json` を参照。

### 応援 LT のテスト

```bash
npm --prefix functions ci
npm --prefix functions test
npm --prefix functions run test:coverage
```

単体テストは認可、入力検証、有効期限、再発行、プロフィールなしの登録、再実行、
試行制限、削除と実行中のアカウント削除の競合を検証する。カバレッジの対象は
`support_lt_service.js` の業務ロジックと `support_lt_auth.js` のアカウント検証で、
行・分岐・関数ごとに 80% 以上をチェックする。

Auth / Firestore / Functions Emulator が起動している状態で以下を実行する。

```bash
npm --prefix functions run test:emulator
```

既定の接続先は `127.0.0.1:9099` / `8080` / `5001`、プロジェクトは
`dev-flutterkaigi-2026`。変更時は `FIREBASE_AUTH_EMULATOR_HOST`、
`FIRESTORE_EMULATOR_HOST`、`FUNCTIONS_EMULATOR_HOST`、
`SUPPORT_LT_TEST_PROJECT_ID` を指定する。接続先はループバックに限定する。
テストは実際の認証トークンで callable と Firestore REST API を呼び出し、
並行発行・並行登録・並行総当たり、ルールの拒否、Auth 削除トリガー、
削除・無効化後の古い ID トークンの拒否まで検証する。
専用のテストユーザーを作成・削除し、既存コードを保存・復元するため、
実行中はダッシュボードからコードを再発行しないこと。

## プロフィール交換

`functions/src/profile_exchange.ts` に実装がある（`index.ts` から re-export）。

- `issueExchangeToken`（onCall）: サインイン済みユーザー自身の uid について、
  署名付きトークン `v1.<uid>.<exp>.<sig>`（HMAC-SHA256、有効期限 24 時間）を発行する。
  アプリはこのトークンを QR コードの中身として使う。
- `onProfileExchangeCreated`（Firestore トリガー、`users/{uid}/exchanges/{otherUid}`
  の作成時）: `origin: 'scan'` のドキュメントについてトークンを検証し、
  相手側 `users/{otherUid}/exchanges/{uid}` を `origin: 'mirror'` で作成し、
  `counters/profileExchanges.count` を 1 増やしたうえで、自分側の `token` を
  null 化する。トークンが不正・期限切れ・uid 不一致の場合は作成された
  ドキュメントを削除する。`origin: 'mirror'` のドキュメントには反応しない
  （自分自身のミラー書き込みを再度ミラーする無限ループを防ぐため）。ミラー作成と
  カウンタ更新は 1 つのトランザクションにまとめてあり、ミラーが既に存在する
  場合（再実行や、相手側が同時に検証中の場合）はどちらも実行しない。
- `issueExchangeCode`（onCall）: サインイン済みユーザー自身の uid について、
  `exchangeCodes/{code}` に `{ uid, expiresAt }`（有効期限 5 分）で保存された
  6 桁コードを返す。有効なコードが残っていればそれをそのまま返し、無い場合だけ
  暗号論的乱数で新しいコードを発行する（アプリを再起動しても同じコードが返る）。
  `rotate: true` を渡すと現在のコードを削除して必ず発行し直す（アプリの
  「コードを再発行」）。期限切れおよび発行し直しで不要になったコードは、この
  呼び出しで削除する。カメラ権限が使えない端末向けの QR のフォールバック。
- `redeemExchangeCode`（onCall）: 6 桁コードを検証し、有効なら
  `issueExchangeToken` と同じ形式の署名付きトークンを返す。クライアントは
  この後 QR スキャンと同じ `users/{me}/exchanges/{otherUid}` の create() に
  載せる（交換の作成経路は 1 つだけ）。コードは redeem されても有効期限まで
  残り、何人でも入力できる（1 つの QR を複数人が順に読み取るのと同じ扱い）。
  期限切れのコードは削除する。
  呼び出し元 uid ごとに失敗試行回数を `exchangeCodeAttempts/{uid}` で数え、
  10 回失敗すると 10 分間拒否する（自分自身のコードを入力した場合は
  総当たりの兆候ではないため失敗回数に数えない）。
- `onProfileExchangeOwnerDeleted`（Firestore トリガー、`users/{uid}` の削除時）:
  本人の `exchanges` サブコレクション全件と、相手側に残ったミラー
  `users/{otherUid}/exchanges/{uid}` を削除する。`AuthRepository.deleteAccount`
  の `beforeDelete` が `users/{uid}` を削除する運用と組み合わせて動く。
  400 件ずつのバッチ削除で、削除対象がなければ何もしない（re-run しても安全）。

`exchangeCodes` と `exchangeCodeAttempts` は Firestore ルールでクライアントからの
read/write を一切禁止しており、これらの関数のみが Admin SDK 経由で読み書きする。

トークンの署名に使う関数（`issueExchangeToken` / `onProfileExchangeCreated` /
`redeemExchangeCode`）は、署名鍵を Firebase Functions のシークレット
`EXCHANGE_TOKEN_SECRET` から読む。

```bash
firebase functions:secrets:set EXCHANGE_TOKEN_SECRET --project flutterkaigi-2026-stg
```

エミュレータでは `functions/.secret.local`（Git 管理外）に
`EXCHANGE_TOKEN_SECRET=<任意の値>` を書いて実行する。

`functions/.env`（Git 管理外、後述の「セットアップ」参照）も必須。
`SYNC_TARGET_PROJECT_ID` が未設定だとエミュレータ起動時に対話プロンプトで
停止し、関数が 1 つも登録されない。

## syncCollectionsToProd

STG プロジェクトにデプロイする callable function。管理ダッシュボード（STG）からの
呼び出しで、指定された Firestore コレクションを本番プロジェクトへ**完全ミラー**する。

- STG に存在するドキュメントは同じ ID で本番へ作成・上書き（完全置換）
- STG に存在しない本番側のドキュメントは**削除**
- `{ dryRun: true }` を渡すと書き込みせずに予定件数（作成/更新/削除）のみ返す

### リクエスト

```jsonc
{
  "collections": ["venues", "speakers", "sessions", "timelineEvents"],
  "dryRun": true
}
```

`collections` に指定できるのは以下のみ（それ以外は `invalid-argument`）。

| コレクション | 備考 |
| --- | --- |
| `sponsors` | |
| `news` | |
| `venues` | `sessions` / `timelineEvents` から参照される |
| `speakers` | `sessions` から参照される |
| `sessions` | `venueId` / `speakerIds` を持つ |
| `timelineEvents` | `venueId` を持つ |

レスポンスは全体の合計に加えて、`collections` にコレクションごとの内訳を含む。

### 反映の順序

複数コレクションを指定した場合、参照切れの期間を作らないよう次の順で実行する。

1. 作成・上書きを**依存順**（参照される側が先: `venues` → `speakers` → `sessions` → `timelineEvents`）に実行
2. そのあと削除を**逆順**（参照する側が先）に実行

指定順は無視され、常に上記の依存順へ並べ替えられる。クロスプロジェクトのバッチは
張れないため、全体の原子性は保証されない（途中で失敗した場合は再実行する）。

### 認可

以下をすべて満たす呼び出しのみ受け付ける（Firestore ルールの管理者条件と同一）。

1. Firebase Auth でサインイン済み
2. メールアドレスが確認済みで `@flutterkaigi.jp` ドメイン
3. STG Firestore の `admins/{uid}` にドキュメントが存在する
4. App Check トークンが有効（エミュレータ実行時は無効化）

> STG フレーバーをローカル実行（`flutter run` = デバッグビルド）する場合、
> App Check は `WebDebugProvider` になる。コンソールに出力されるデバッグトークンを
> Firebase Console > App Check に登録しておくこと。

## セットアップ

```bash
cd functions
npm install
cp .env.example .env   # SYNC_TARGET_PROJECT_ID に本番プロジェクト ID を設定
```

接続情報（同期先プロジェクト ID）は `.env` に置き、Git 管理外とする。

### 本番プロジェクトへの書き込み権限（初回のみ）

サービスアカウントキーは使わず、クロスプロジェクト IAM で権限を付与する。
STG の Cloud Functions 実行サービスアカウント（デフォルトは Compute Engine の
デフォルト SA）に、本番プロジェクトの Datastore ユーザーロールを付与する:

```bash
gcloud projects add-iam-policy-binding <本番プロジェクトID> \
  --member="serviceAccount:<STGプロジェクト番号>-compute@developer.gserviceaccount.com" \
  --role="roles/datastore.user"
```

プロジェクト番号は `gcloud projects describe <STGプロジェクトID> --format='value(projectNumber)'` で確認できる。

## デプロイ

リポジトリルートから:

```bash
fvm dart run melos functions:deploy:stg
```

（内部で `firebase deploy --only functions --project flutterkaigi-2026-stg` を実行。
`predeploy` で TypeScript のビルドが走る）

> ダッシュボードは `syncCollectionsToProd` を呼ぶため、Functions を先にデプロイしてから
> Hosting をデプロイすること。逆順にすると新しいダッシュボードが呼ぶ関数が存在しない。

## ローカル開発（エミュレータ）

```bash
fvm dart run melos firebase:start:functions
```

Functions を含むエミュレータスイートを起動する（事前に `npm install` が必要）。
エミュレータでは App Check 検証と「同期先 = デプロイ先」ガードを無効化している。
Firestore エミュレータは複数プロジェクト ID を扱えるため、`.env` の
`SYNC_TARGET_PROJECT_ID` に任意の ID を設定すればローカルで動作確認できる
（`firebase.json` の `singleProjectMode` の警告は無視してよい）。
