# Firebase の本番・stg 配布

`Deploy Firebase` は `main` の Rules・Indexes と任意の Functions を、選択した環境へ手動で適用する。
アプリの配布 Workflow が使う読み取り専用のサービスアカウントとは分離する。

| 環境 | Firebase Project | Remote Config 初期値 |
| --- | --- | --- |
| prod | `flutterkaigi-2026-283db` | `event_features_enabled=true`、強制更新なし |
| stg | `flutterkaigi-2026-stg` | `event_features_enabled=true`、強制更新なし |

## 初回設定

既存の `STG_FIREBASE_PROJECT_ID`、`PROD_FIREBASE_PROJECT_ID` と
`GCP_WORKLOAD_IDENTITY_PROVIDER_STG` / `_PROD` を使用する。追加する Repository Variables は次の2つ。

- `GCP_FIREBASE_DEPLOY_SERVICE_ACCOUNT_STG`
- `GCP_FIREBASE_DEPLOY_SERVICE_ACCOUNT_PROD`

各値は対象プロジェクトに作成した Firebase 配布専用サービスアカウントのメールアドレスとする。
既存の `github-actions-website` アカウントへ書き込み権限を追加しない。
WIF の許可元を `FlutterKaigi/2026` の `main` に制限し、GitHub Environment
`firebase-stg` / `firebase-prod` の deployment branch policy も `main` に制限する。
本番の運用に合わせて Environment に required reviewers を設定する。

配布に必要な権限は対象プロジェクトに限定して設定する。

- Rules: `roles/firebaserules.admin`
- Firestore Indexes: `roles/datastore.indexAdmin`
- Firebase のプロジェクト情報参照: `roles/firebase.viewer`
- Remote Config の明示的な初期値適用: `roles/cloudconfig.admin`
- Functions: `roles/cloudfunctions.developer` と、使用する runtime / build サービスアカウントへの `roles/iam.serviceAccountUser`

Firebase CLI の preflight や Storage の既定バケット参照で不足する権限は、失敗ログの対象操作を確認して追加する。
Owner / Editor をまとめて付与しない。API の初回有効化、課金設定、Storage バケット作成、
Functions のビルド実行サービスアカウントの設定はプロジェクト管理者が行う。
これは未設定のプロジェクトを自動作成する Workflow ではない。

両環境に `EXCHANGE_TOKEN_SECRET` の有効な Secret Manager バージョンが必要。
既存の署名鍵は変更せず、初回のみ管理者が作成する。
`SYNC_TARGET_PROJECT_ID` は本番プロジェクトIDを環境別 `.env` に書き込む。
本番では `syncCollectionsToProd` の既存の同一プロジェクトガードにより同期を拒否する。
この Workflow はコレクション同期を呼び出さない。

## 実行

1. GitHub Actions の `Deploy Firebase` → `Run workflow` を開く。
2. Branch を `main`、environment を `stg` にする。
3. `deploy_functions=true` で Rules・Indexes・Functions を揃える。
4. 初回の Remote Config 整備時だけ `apply_remote_config_defaults=true` にする。
5. stg の結果とアプリ動作を確認後、同じ main のリビジョンを prod へ適用する。

デプロイ対象は `firestore:rules,firestore:indexes,storage` と任意の `functions`。
Hosting は含まない。CLI に `--force` は渡さず、関数やインデックスの削除確認が必要な場合は停止する。
新しいインデックスが使用可能になったことを Firebase Console で確認してからアプリを配布する。

## Remote Config

初期値は `packages/data/firebase/remoteconfig.prod.json` / `remoteconfig.stg.json` にある。
`force_update.minimum_version` は両OSとも `0.0.0` で、強制更新は発動しない。
iOS のストアURLは公開先を確認してから設定する。

`tool/remote_config.mjs` は現在のテンプレートを取得し、対象の2キーだけの既定値を更新する。
他のキー、グループ、条件を保持する。対象キーに条件付きの値がある場合は上書きせず停止する。
検証後、取得時の ETag で公開し、他の編集と競合した場合も強制上書きしない。
更新前テンプレートは指定パスに保存する。バックアップに非公開設定が含まれ得るため Git に入れない。

ローカルでの差分確認（対象プロジェクトにアクセスできる gcloud アカウントを使用）:

```bash
FIREBASE_ACCESS_TOKEN="$(gcloud auth print-access-token)" \
  node tool/remote_config.mjs --environment=stg
```

公開する場合は `--apply --backup=/private/tmp/remote-config-stg-before.json` を追加する。
既存のバックアップファイルは上書きしない。APIキーやアクセストークンをチャット・ログへ貼り付けない。
通常のデプロイでは `apply_remote_config_defaults=false` のままにし、手動で切り替えた値を戻さない。
公開後は Firebase Console のバージョン履歴とクライアントの取得結果を確認する。

アプリ内の `event_features_enabled` の既定値は現在 `true`。
本番の Remote Config を `false` にしても、初回取得前や取得失敗時には当日機能が表示されることがある。
このフラグは表示制御であり、認可は Rules と Functions で行う。

## 参照

- [Firebase CLI と CI 認証](https://firebase.google.com/docs/cli#use_the_cli_with_ci_systems)
- [Remote Config のテンプレートとバージョン管理](https://firebase.google.com/docs/remote-config/templates)
- [Functions の実装とセットアップ](../functions/README.md)
