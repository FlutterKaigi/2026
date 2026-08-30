# Cloud Functions

FlutterKaigi 2026 の Cloud Functions。STG → 本番のデータ反映用の
`syncCollectionsToProd` と、プロフィール交換用の各種関数を提供する。

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
  暗号論的乱数の 6 桁コードを発行し `exchangeCodes/{code}` に
  `{ uid, expiresAt }`（有効期限 5 分）で保存する。同一ユーザーが発行済みの
  古いコードは新規発行時に削除する。カメラ権限が使えない端末向けの QR の
  フォールバック。
- `redeemExchangeCode`（onCall）: 6 桁コードを検証し、有効なら
  `issueExchangeToken` と同じ形式の署名付きトークンを返す。クライアントは
  この後 QR スキャンと同じ `users/{me}/exchanges/{otherUid}` の create() に
  載せる（交換の作成経路は 1 つだけ）。使用済み・期限切れのコードは削除する。
  呼び出し元 uid ごとに失敗試行回数を `exchangeCodeAttempts/{uid}` で数え、
  10 回失敗すると 10 分間拒否する（自分自身のコードを入力した場合は
  総当たりの兆候ではないため失敗回数に数えない）。
- `onProfileExchangeOwnerDeleted`（Firestore トリガー、`users/{uid}` の削除時）:
  本人の `exchanges` サブコレクション全件と、相手側に残ったミラー
  `users/{otherUid}/exchanges/{uid}` を削除する。`AuthRepository.deleteAccount`
  の `beforeDelete` が `users/{uid}` を削除する運用と組み合わせて動く。
  500 件ずつのバッチ削除で、削除対象がなければ何もしない（re-run しても安全）。

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
