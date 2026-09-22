# Firebase の本番・stg 配布

`Deploy Firebase` は Firebase 関連の変更が `main` に入ると、テスト後に Rules・Indexes・Functions を stg へ適用する。
prod への適用は `main` からの手動実行に限定する。手動実行では環境と Functions の適用有無を選択でき、環境の初期値は `stg`。
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

各値は対象プロジェクトの `github-actions-firebase@<project-id>.iam.gserviceaccount.com` とする。
既存の `github-actions-website` アカウントへ書き込み権限を追加しない。
WIF に `attribute.firebase_deploy_repository` を追加し、OIDC の `assertion.ref` が
`refs/heads/main` の場合だけ `assertion.repository` を割り当てる。それ以外の ref は空文字にする。
専用アカウントの `roles/iam.workloadIdentityUser` は、この属性が `FlutterKaigi/2026` と一致する
principalSet だけに付与する。既存の `google.subject`、`attribute.repository`、リポジトリ制限は維持する。
main 制限は Google Cloud 側で強制し、GitHub Environment の作成権限には依存しない。
サービスアカウントキーは発行せず、Actions の短期 OIDC 認証を使用する。

配布に必要な権限は対象プロジェクトに限定して設定する。

- Rules: `roles/firebaserules.admin`
- Firestore Indexes: `roles/datastore.indexAdmin`
- Firebase のプロジェクト情報参照: `roles/firebase.viewer`
- API 使用とビルド結果参照: `roles/serviceusage.serviceUsageConsumer`、`roles/cloudbuild.builds.viewer`
- Remote Config の明示的な初期値適用: `roles/cloudconfig.admin`
- Functions: `roles/cloudfunctions.developer` と、使用する runtime / build サービスアカウントへの `roles/iam.serviceAccountUser`
- Secret Manager: 使用する Secret に限定した `roles/secretmanager.viewer`。配布アカウントには秘密値の取得権限を付与しない。

新規 HTTP 関数の呼び出し権限を設定するため、`firebaseFunctionsDeploymentIam` カスタムロールには
`cloudfunctions.functions.setIamPolicy`、`run.services.getIamPolicy`、`run.services.setIamPolicy` の3権限だけを含める。
これを対象プロジェクトの配布アカウントへ付与する。プロジェクト全体の IAM 変更権限は付与しない。

Firebase CLI の preflight や Storage の既定バケット参照で不足する権限は、失敗ログの対象操作を確認して追加する。
Owner / Editor をまとめて付与しない。API の初回有効化、課金設定、Storage バケット作成、
Functions のビルド実行サービスアカウントの設定はプロジェクト管理者が行う。
これは未設定のプロジェクトを自動作成する Workflow ではない。

両環境に `EXCHANGE_TOKEN_SECRET` の有効な Secret Manager バージョンが必要。
既存の署名鍵は変更せず、初回のみ管理者が作成する。
実行アカウントには、この Secret に限定して `roles/secretmanager.secretAccessor` を付与する。
`SYNC_TARGET_PROJECT_ID` は本番プロジェクトIDを環境別 `.env` に書き込む。
本番では `syncCollectionsToProd` の既存の同一プロジェクトガードにより同期を拒否する。
この Workflow はコレクション同期を呼び出さない。

## 実行

通常は `main` マージ後の自動実行を確認する。Functions の lint・単体テスト・Emulator 結合テストが成功すると、
stg へ適用する。stg で動作確認した後、本番への適用は手動で実行する。
Firebase 設定の適用結果は Actions のジョブとサマリーで確認する。
2025 のデータベース設定適用と同じく、GitHub Deployments には記録しない。

本番へ適用、または再適用する場合:

1. GitHub Actions の `Deploy Firebase` → `Run workflow` を開く。
2. Branch は `main`、environment は `stg` / `prod` / `all` を選ぶ。初期値は `stg`。本番のみへの適用は `prod`、両環境への適用は `all`。
3. 通常は `deploy_functions=true` とする。
4. Remote Config の初期値を適用すると明示的に決めた場合だけ `apply_remote_config_defaults=true` にする。

手動実行も実行要求時点の `main` のコミットをテストして適用する。stg で確認した後に `main` が更新された場合は、
新しいコミットの stg への適用と動作確認を済ませてから本番へ適用する。

自動実行は、`functions/**`、`packages/data/firebase/**`、`firebase.json`、`tool/remote_config*.mjs`、
Firebase 配布・Functions CI の Workflow に変更がある場合が対象。これらのパス内の README やテストだけの変更も対象となる。
判定対象は push に含まれるファイルの変更であり、Firebase に適用済みの内容との差分ではない。
手動実行では変更がなくてもテストと `firebase deploy` を実行する。
デプロイ対象ごとの変更検出や更新の省略は Firebase CLI に委ねる。

デプロイ対象は `firestore:rules,firestore:indexes,storage` と任意の `functions`。
Hosting は含まない。CLI に `--force` は渡さず、関数やインデックスの削除確認が必要な場合は停止する。
新規関数のリトライ設定などで CLI が確認を要求する場合も、管理者が対象関数を限定して初回適用する。
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
