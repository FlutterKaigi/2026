# Cloud Functions

FlutterKaigi 2026 の Cloud Functions。現在は STG → 本番のデータ反映用に
`syncCollectionsToProd` を提供する。

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
