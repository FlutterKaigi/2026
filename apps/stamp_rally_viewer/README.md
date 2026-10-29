# FlutterKaigi 2026 スタンプラリー状況確認

参加者がログインし、自分がスタンプを獲得したスポンサーと景品の交換履歴を確認する Flutter Web アプリです。
公式アプリ `apps/app` と同じ Firebase Authentication と Firestore を使用します。

## 表示する記録

- スタンプを獲得したスポンサーと獲得日時
- チェックポイントごとの景品の交換状況と交換日時
- サンクスカードの交換状況と交換日時

参照先は `stampRallyCards/{ログインユーザーのUID}`、`stampRallySettings/current`、`stampRallySponsors`、`sponsors` です。
`packages/data` の `AuthRepository`、`StampRallyRepository`、`SponsorRepository` を再利用します。
履歴の追加・景品交換の確定は公式アプリで行います。このアプリは履歴を変更しません。

既存データには景品名が保存されていないため、景品は「景品 #1」「景品 #2」のようにチェックポイント番号で表示します。
Firestore Rules が本人のカードだけを取得できるよう制限しているため、ログイン画面の表示制御に加え、データの取得自体にも認証が必要です。

## ログイン

公式アプリでスタンプを集めたときと同じ Apple アカウント、Google アカウント、またはメールアドレス・パスワードでログインします。
Firebase のプロジェクト・ユーザー UID が同じため、既存の記録をそのまま参照できます。
ブラウザのログイン状態はホストごとに保持されるため、公式アプリや別のサブドメインでログイン済みでも、初回はこのサイトでのログインが必要です。
[Firebase の認証状態の永続化](https://firebase.google.com/docs/auth/web/auth-state-persistence)を参照してください。

Apple / Google は Firebase のポップアップ認証を使用します。Apple は iOS の Chrome / Safari を含む Web ブラウザで利用でき、OS によるボタンの表示制限はありません。
ポップアップがブロックされた場合はブラウザで許可し、再度ログインしてください。
別のアカウントを作成しても元の履歴にはアクセスできません。

### Apple Web 認証の設定

iOS ネイティブの Apple 認証が有効でも、Web 用の OAuth 設定が別途必要です。

1. Apple Developer で Services ID を用意し、公式 iOS アプリと同じ Sign in with Apple の primary App ID に関連付けます。
2. Services ID に Firebase の認証ドメインと Return URL `https://<Firebase authDomain>/__/auth/handler` を登録します。
   本番の既定値は `https://flutterkaigi-2026-283db.firebaseapp.com/__/auth/handler` です。
3. Firebase Authentication の Apple provider に Services ID、Team ID、Key ID、Sign in with Apple 用秘密鍵を設定します。
   秘密鍵をソースコードや Repository Variables に保存しないでください。
4. 配布後、公式アプリで使用済みの Apple アカウントでログインし、同じ UID のスタンプ・交換履歴を表示できることを確認します。

設定手順は [Firebase の Apple Web 認証](https://firebase.google.com/docs/auth/web/apple) と
[Apple の Services ID 設定](https://developer.apple.com/help/account/capabilities/configure-sign-in-with-apple-for-the-web/)を参照してください。

## ローカル開発

Repository ルートで実行します。

```bash
cp apps/stamp_rally_viewer/lib/firebase_options.stub.dart apps/stamp_rally_viewer/lib/firebase_options.dart
fvm flutter pub get
fvm dart run melos run firebase:start
```

別のターミナルで起動します。

```bash
fvm dart run melos run stamp_rally_viewer:run:dev
```

dev は `dev-flutterkaigi-2026` の Auth Emulator (`localhost:9099`) と Firestore Emulator (`localhost:8080`) に接続します。
Emulator UI (`http://localhost:4000`) でメール・パスワードのテストユーザーを作り、その UID の `stampRallyCards` を用意すると履歴を確認できます。
公式アプリと Functions Emulator でスタンプ獲得から確認する場合は、[公式アプリの開発手順](../app/README.md)に従ってください。
スタブはメール認証・analyze・test・ビルド用です。Apple / Google の擬似 IdP を検証する場合は、既存アプリと同様にメンテナーが有効な Web SDK 設定を生成してから Emulator へ接続します。

```bash
fvm dart run melos run analyze:stamp_rally_viewer
fvm dart run melos run test:stamp_rally_viewer
fvm dart run melos run stamp_rally_viewer:build:dev
```

stg / prod のローカル起動では、対象プロジェクトの設定を `flutterfire configure --platforms=web --web-app-id=... --out=lib/firebase_options.dart` で生成したうえで、
`stamp_rally_viewer:run:stg` または `stamp_rally_viewer:run:prod` を使用します。
Debug の App Check トークンを対象 Firebase Web App に登録してください。
Release ビルド用の `stamp_rally_viewer:build:stg` / `stamp_rally_viewer:build:prod` では、環境変数 `APP_CHECK_SITE_KEY` に対応する reCAPTCHA Enterprise Site Key を指定します。

## 配布

| 環境 | Firebase Project | 公開先 |
| --- | --- | --- |
| dev | `dev-flutterkaigi-2026` | localhost |
| stg | `flutterkaigi-2026-stg` | `https://flutterkaigi-2026-stamp-rally-viewer-stg.flutterkaigi.workers.dev` |
| prod | `flutterkaigi-2026-283db` | `https://2026-stamp-rally-viewer.flutterkaigi.jp` |

[Deploy Stamp Rally Viewer](../../.github/workflows/deploy_stamp_rally_viewer.yaml) を `main` から手動実行し、`stg` / `prod` を選択します。
自動配布は行いません。先に [Stamp Rally Viewer CI](../../.github/workflows/ci_stamp_rally_viewer.yaml) で整形、解析、テスト、dev ビルドを確認し、
配布時に既存の公式アプリ用 Firebase Web App から SDK 設定を生成します。
生成した Project ID・Web App ID の検証後、Cloudflare Workers の Static Assets へ配布します。
stg は `deploy --env stg`、prod は `deploy` を使用するため、どちらの環境も初回の配布で Worker を作成できます。
stg は独立した Worker `flutterkaigi-2026-stamp-rally-viewer-stg` に配布します。
`env.stg` の `routes = []` と `workers_dev = true` で、STG の公開先を上記の `workers.dev` ホストに限定しています。
Firebase Hosting の既存ダッシュボードとは別の配布先です。

使用する Repository Variables / Secret は既存アプリと共通です。

| 種類 | 名前 |
| --- | --- |
| Variables | `STG_FIREBASE_PROJECT_ID` / `PROD_FIREBASE_PROJECT_ID` |
| Variables | `STG_APP_FIREBASE_WEB_APP_ID` / `PROD_APP_FIREBASE_WEB_APP_ID` |
| Variables | `STG_APP_CHECK_SITE_KEY` / `PROD_APP_CHECK_SITE_KEY` |
| Variables | `GCP_WORKLOAD_IDENTITY_PROVIDER_STG` / `GCP_WORKLOAD_IDENTITY_PROVIDER_PROD` |
| Variables | `GCP_SERVICE_ACCOUNT_STG` / `GCP_SERVICE_ACCOUNT_PROD` |
| Variable | `CLOUDFLARE_ACCOUNT_ID` |
| Secret | `CLOUDFLARE_API_TOKEN` |

初回配布前に、対象環境へホストを登録します。
本番は `2026-stamp-rally-viewer.flutterkaigi.jp`、STG は `flutterkaigi-2026-stamp-rally-viewer-stg.flutterkaigi.workers.dev` です。

1. Firebase Console → Authentication → Settings → Authorized domains に、本番または STG のホストを追加します。
2. 既存の公式アプリ用 reCAPTCHA Enterprise Key の許可ドメインにも、対応するホストを追加します。Firestore は App Check enforcement が有効です。
3. Firebase Web API Key に HTTP リファラー制限を設定している場合、対応するホストからの利用を許可します。
4. Cloudflare の `flutterkaigi.jp` Zone と Workers Custom Domain を操作できる既存 Token を使用します。
   本番配布では `wrangler.toml` の Custom Domain が設定され、DNS と TLS 証明書が Cloudflare により作成されます。

新しいサブドメインには旧アプリからの自動ログインやネイティブアプリへの Universal Link を設定していません。
ドメインを変える場合は `wrangler.toml`、この README、Workflow の URL と、上記の許可ドメイン設定を合わせて更新してください。

Firebase Options と FlutterFire の生成ファイルは Git 管理外です。設定値をこの README や PR に貼り付けず、
[既存アプリの配布設定](../../.github/APP_DELIVERY.md#firebase-sdk-settings)と同じ運用を使用します。
Cloudflare の設定については [Static Assets の SPA 設定](https://developers.cloudflare.com/workers/static-assets/routing/single-page-application/)、
[Custom Domains](https://developers.cloudflare.com/workers/configuration/routing/custom-domains/)、
[Wrangler Environments](https://developers.cloudflare.com/workers/wrangler/environments/) を参照してください。
