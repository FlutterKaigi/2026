# Cloud Functions

FlutterKaigi 2026 の Cloud Functions。STG → 本番のデータ反映用の
`syncSponsorsToProd` / `syncNewsToProd` と、公式アプリ（Web）のアカウント削除に
使う `revokeAppleToken` を提供する。

## revokeAppleToken

公式アプリの Web 版がアカウント削除の直前に呼び出す callable function。
Apple はアカウント削除時の Sign in with Apple トークン失効を要求しているが、
Web クライアントの SDK には失効 API がなく client secret も置けないため、
この function が Apple の REST API（`/auth/revoke`）でアクセストークンを
失効させる（iOS / Android は Firebase SDK で直接失効するため使わない）。

呼び出しにはサインイン済みの Firebase Auth と有効な App Check トークンが必要。

### 設定

プロジェクトごとの`.env.<project-id>`に以下を設定する（値はApple Developer / Firebase Consoleを参照）。
テンプレートは`.env.example`に含まれている。

- `APPLE_TEAM_ID`: Apple Developer の Team ID
- `APPLE_KEY_ID`: Sign in with Apple 用秘密鍵（.p8）の Key ID
- `APPLE_SIGN_IN_CLIENT_ID`: Firebase Console の Apple プロバイダーに設定した
  Web 用 Services ID

秘密鍵本体は Secret Manager に登録する:

```bash
firebase functions:secrets:set APPLE_SIGN_IN_PRIVATE_KEY --project <プロジェクトID>
# プロンプトに .p8 ファイルの PEM 全文を貼り付ける
```

設定後、失効Functionだけを各アプリ環境へデプロイする:

```bash
fvm dart run melos functions:deploy:auth:stg
fvm dart run melos functions:deploy:auth:prod
```

STG/本番の両方へデプロイしないと、それぞれのWebアプリからのAppleアカウント
削除が`not-found`で失敗する。

## syncSponsorsToProd / syncNewsToProd

STG プロジェクトにデプロイする callable function。管理ダッシュボード（STG）からの
呼び出しで、STG の `sponsors` / `news` コレクションをそれぞれ本番プロジェクトへ
**完全ミラー**する（両関数ともロジックは同一で、対象コレクションが異なるだけ）。

- STG に存在するドキュメントは同じ ID で本番へ作成・上書き（完全置換）
- STG に存在しない本番側のドキュメントは**削除**
- `{ dryRun: true }` を渡すと書き込みせずに予定件数（作成/更新/削除）のみ返す

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

## ローカル開発（エミュレータ）

```bash
fvm dart run melos firebase:start:functions
```

Functions を含むエミュレータスイートを起動する（事前に `npm install` が必要）。
エミュレータでは App Check 検証と「同期先 = デプロイ先」ガードを無効化している。
Firestore エミュレータは複数プロジェクト ID を扱えるため、`.env` の
`SYNC_TARGET_PROJECT_ID` に任意の ID を設定すればローカルで動作確認できる
（`firebase.json` の `singleProjectMode` の警告は無視してよい）。
