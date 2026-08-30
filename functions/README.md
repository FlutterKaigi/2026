# Cloud Functions

FlutterKaigi 2026 の Cloud Functions。STG → 本番のデータ反映用の
`syncCollectionsToProd` に加えて、プロフィール交換機能（`users/{uid}/exchanges`）用の
関数を提供する。

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

## プロフィール交換 (`users/{uid}/exchanges`)

参加者同士が QR コード（または 6 桁コードのフォールバック）でプロフィールを
交換する機能のサーバー側。詳細な設計はプロフィール交換機能の Issue を参照。

### `issueExchangeToken`（onCall・認証必須）

自分の QR コード表示用に、署名付き交換トークン `v1.<uid>.<exp>.<sig>`
（HMAC-SHA256、有効期限 24 時間）を発行する。端末にキャッシュしておけば、
期限内はオフラインでも QR を表示し続けられる。

QR ペイロードはこのトークンをそのまま使う。`users/{uid}` はサインイン済みなら
誰でも read できるため、トークンの中身は秘密情報ではない。目的は uid を
そのまま QR 化しないことと、期限切れ・改ざんされたトークンでの交換を防ぐこと。

### `issueExchangeCode` / `redeemExchangeCode`（onCall・認証必須）

カメラが使えない参加者向けの、6 桁コードによるフォールバック。

- `issueExchangeCode`: 5 分間だけ有効な使い捨てコードを発行し、発行者の uid を
  Admin 専用コレクション `exchangeCodes`（firestore.rules のデフォルト拒否で
  クライアントからは読み書き不可）に保存する。
- `redeemExchangeCode`: `{ code: "123456" }` を受け取り、コードを検証（存在・
  期限・自分自身のコードでないこと）した上で **削除**（使い捨て）し、発行者の
  `issueExchangeToken` と同形式のトークンを `{ uid, token }` で返す。クライアントは
  これを使って QR スキャン時と同じ経路（`users/{me}/exchanges/{発行者のuid}` の
  作成）で交換を成立させる。
- 総当たり対策として、呼び出し元 uid ごとに `exchangeCodeRedeemAttempts` で
  試行回数を記録し、5 分間に 10 回を超えたら `resource-exhausted` を返す
  （コード単位ではなく呼び出し元単位にすることで、別々のコードを次々に試す
  攻撃も抑える）。

### `onProfileExchangeCreated`（Firestore トリガー: `users/{uid}/exchanges/{otherUid}` の作成）

1. `origin == 'mirror'`（このトリガー自身が作った側）なら何もしない（ループ防止）
2. `token` の署名・期限・uid 一致（`otherUid` と一致するか）を検証し、不正なら
   作成されたドキュメントを削除する
3. 相手側 `users/{otherUid}/exchanges/{uid}` を `origin: 'mirror'` で作成する
   （既に存在する場合は触らない = 同じ相手を再スキャンしても重複しない）
4. 自分側の `token` を null 化して残さない
5. 新しいペアが成立した時だけ `counters/profileExchanges` を increment する

### `onUserProfileDeleted`（Firestore トリガー: `users/{uid}` の削除）

退会時に、本人の `exchanges` サブコレクションと、相手側に残ったミラーの両方を
削除する。プロフィール本体が消えて表示できなくなるため、相手の一覧にも残さない。

> 既知の制約: 本人が事前に `exchanges` から削除していた相手（＝退会時点で本人の
> サブコレクションに残っていない相手）については、相手側のミラーは検出できず
> 孤児として残る。

### セットアップ（トークン署名鍵）

```bash
# 本番 / STG（デプロイ時に使う値。Secret Manager に保存される）
firebase functions:secrets:set EXCHANGE_TOKEN_SECRET --project <プロジェクトID>

# エミュレータ（Git 管理外の functions/.secret.local に書く）
echo "EXCHANGE_TOKEN_SECRET=dev-secret" >> functions/.secret.local
```

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

## テスト

Firestore/Functions を使わない純粋ロジック（トークンの発行・検証、6 桁コードの
生成・形式チェック、レート制限）のみを Node 組み込みの
[`node:test`](https://nodejs.org/api/test.html) で検証する。jest 等は導入していない。

```bash
npm test   # tsc でビルドしてから node --test lib/exchange/*.test.js を実行
```

トリガー・onCall 本体（Firestore / App Check に依存する部分）はテスト基盤がないため、
デプロイ後にエミュレータまたは STG で手動確認する。
