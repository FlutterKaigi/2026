# App delivery setup

`apps/app`のCI/CDは次のworkflowで構成します。

| Workflow | Trigger | Delivery target |
| --- | --- | --- |
| `App CI` | app関連のPR、`main` push、手動 | format/analyze/test、dprint |
| `Preview App Web` | app関連のPR、手動 | Cloudflare Workers Version |
| `Deploy App Web` | app関連の`main` push、手動（現在は明示的に有効化するまでJobをskip） | Cloudflare Workers Production |
| `Deploy App iOS` | GitHub Releaseのpublish、手動、PRへの`deploy-app-ios`ラベル付与 | App Store Connect / TestFlight |
| `Deploy App Android` | GitHub Releaseのpublish、手動 | Google Play Internal Testing |

## GitHub側の登録場所

2025年版と同様にGitHub Environmentsは使用しません。環境差分はRepository Variableの接頭辞（`STG`／`PROD`）と`apps/app/environments/.env.stg`／`.env.prod`で管理します。Firebase OptionsはコミットやSecret登録をせず、各ビルドでFlutterFire CLIから生成します。

### Repository Variables

Repositoryの`Settings > Secrets and variables > Actions > Variables > New repository variable`から登録します。Variablesはログでマスクされないため、秘密鍵やTokenは登録しません。詳細は[GitHubのVariables設定手順](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-variables)を参照してください。

| Variable | 設定値 | 取得元・取得方法 |
| --- | --- | --- |
| `CLOUDFLARE_ACCOUNT_ID` | `cdd8f59359fe226645e7b541cdc53b57` | Cloudflare Dashboardの`Workers & Pages > Overview > Account details`で`Account ID`をコピーします。Accountホームのメニューから`Copy account ID`でも取得できます。現在値は`apps/website/wrangler.toml`でも確認できます。[Cloudflare: Find account and zone IDs](https://developers.cloudflare.com/fundamentals/account/find-account-and-zone-ids/) |
| `STG_FIREBASE_PROJECT_ID` | `flutterkaigi-2026-stg` | Firebase Consoleでstg Projectを開き、歯車アイコンの`Project settings > General > Project ID`を確認します。これはProject作成時に決まる公開識別子です。 |
| `PROD_FIREBASE_PROJECT_ID` | `flutterkaigi-2026-283db` | Firebase Consoleでprod Projectを開き、`Project settings > General > Project ID`を確認します。 |
| `STG_APP_FIREBASE_WEB_APP_ID` | stg AppのWeb App ID | stg Firebase Projectの`Project settings > General > Your apps > 対象Web App > App ID`から、`1:...:web:...`形式の値をコピーします。 |
| `PROD_APP_FIREBASE_WEB_APP_ID` | prod AppのWeb App ID | prod Firebase Projectの同じ画面から取得します。Dashboard用Web Appではなく、公式App用Web AppのIDを使用します。 |
| `STG_APP_CHECK_SITE_KEY` | stg App Web用reCAPTCHA Enterprise Site Key | stg Firebase Projectの`App Check > Apps > 公式App用Web App`を登録し、reCAPTCHA Enterprise Providerへ設定したSite Keyをコピーします。Dashboard用Web Appではなく、公式App用Web Appの登録内容を使用します。 |
| `PROD_APP_CHECK_SITE_KEY` | prod App Web用reCAPTCHA Enterprise Site Key | prod Firebase Projectの同じ画面で公式App用Web Appを登録し、設定したSite Keyをコピーします。Site Keyはブラウザへ配布される公開識別子であり、Secretには登録しません。 |
| `GCP_WORKLOAD_IDENTITY_PROVIDER_STG` | stg WIF Provider resource name | 既存Website Workflowと共用します。Google Cloud Consoleの`IAM & Admin > Workload Identity Federation > 対象Pool > 対象Provider`で、`projects/.../locations/global/workloadIdentityPools/.../providers/...`を確認します。 |
| `GCP_SERVICE_ACCOUNT_STG` | stg CI Service Account email | Google Cloud Consoleの`IAM & Admin > Service Accounts`で、stg WIFから権限借用するService Accountのメールアドレスを確認します。 |
| `GCP_WORKLOAD_IDENTITY_PROVIDER_PROD` | prod WIF Provider resource name | prod ProjectのWorkload Identity Federation画面から取得します。既存Website Workflowと共用します。 |
| `GCP_SERVICE_ACCOUNT_PROD` | prod CI Service Account email | prod Projectの`IAM & Admin > Service Accounts`から取得します。 |
| `APPLE_TEAM_ID` | Apple Developer Team ID | [Apple Developer Account](https://developer.apple.com/account/)へサインインし、`Membership details > Team ID`に表示される10文字のIDをコピーします。[Apple: Team ID](https://developer.apple.com/help/glossary/team-id/) |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect Team Key ID | App Store Connectの`Users and Access > Integrations > App Store Connect API > Team Keys`でCI用Keyを生成し、Key一覧の`Key ID`をコピーします。生成手順は後述します。 |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | App Store Connect Issuer ID | 同じ`App Store Connect API > Team Keys`画面に表示される`Issuer ID`をコピーします。Key固有ではなくTeam側の識別子です。 |
| `IOS_BUNDLE_ID` | `jp.flutterkaigi.conf2026` | 外部サービスから取得する値ではなく、このProjectで決めた本番Bundle IDです。Apple DeveloperのApp ID、App Store Connectのアプリ、Xcode設定をこの値に揃えます。 |
| `ANDROID_PACKAGE_NAME` | `jp.flutterkaigi.conf2026` | 外部サービスから取得する値ではなく、`apps/app/android/app/build.gradle.kts`の`applicationId`です。Google Play Consoleへ同じPackage Nameでアプリを登録します。 |
| `GOOGLE_PLAY_TRACK` | `internal` | Codemagic CLIがGoogle Play Internal Testingを指定するためのTrack名です。このworkflowでは`internal`を使用します。Play Consoleでは`Testing > Internal testing`で対象Trackを確認します。 |
| `ENABLE_APP_WEB_PRODUCTION_DEPLOY` | 未登録または`false`で停止、`true`で有効化 | `apps/app`のProduction Web配布だけを一時停止する制御値です。現在は登録しないか`false`にします。`apps/website`の配布とApp Web Previewには影響しません。 |

### Repository Secrets

Repositoryの`Settings > Secrets and variables > Actions > Secrets > New repository secret`から登録します。Web UIのほか、GitHub CLIへ再認証済みならRepositoryルートで`gh secret set SECRET_NAME`でも登録できます。詳細は[GitHubのActions Secrets設定手順](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)を参照してください。

| Secret | 使用先 | 取得元・取得方法 |
| --- | --- | --- |
| `CLOUDFLARE_API_TOKEN` | Web Preview／Production共通 | Cloudflare Dashboardの`Manage Account > Account API Tokens`から作成します。既存Tokenが後述の権限を満たす場合は再利用できます。 |
| `APP_STORE_CONNECT_API_KEY_BASE64` | iOS Production | App Store ConnectからダウンロードしたTeam Key（`.p8`）をBase64化します。 |
| `ANDROID_SIGNING_KEYSTORE_BASE64` | Android Production | チームで生成・保管するAndroid Upload Key（`release.jks`）をBase64化します。 |
| `ANDROID_KEY_PROPERTIES_BASE64` | Android Production | Upload Keyのaliasとパスワードを記載した`key.properties`をBase64化します。 |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_BASE64` | Android Production | Google Cloudで発行したGoogle Play配布用Service Account JSONをBase64化します。 |

## Cloudflare

### `CLOUDFLARE_ACCOUNT_ID`

取得場所は`Workers & Pages > Overview > Account details > Account ID`です。このRepositoryでは`cdd8f59359fe226645e7b541cdc53b57`を使用します。Wranglerによる非対話CIにはAccount IDとAPI Tokenが必要です。[CloudflareのGitHub Actions手順](https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/)も参照してください。

### `CLOUDFLARE_API_TOKEN`

PreviewとProductionで同じRepository Secretを使用します。既存の`CLOUDFLARE_API_TOKEN`が次の権限とResource範囲を満たす場合は、そのTokenをそのまま使用できます。

1. Cloudflare Dashboardで`Manage Account > Account API Tokens`を開きます。Account Tokenを作れない場合は`My Profile > API Tokens`からUser Tokenを作成します。
2. `Create Token`を選択します。
3. TemplateまたはCustom permissionsで`Edit Cloudflare Workers`を選択します。
4. Account resourceをFlutterKaigiの対象Accountだけに限定します。
5. Custom Domainを操作するため、Zone resourceを`flutterkaigi.jp`だけに限定し、Workers Routesの更新権限も付与します。
6. `Continue to summary > Create Token`を選び、作成直後に一度だけ表示されるTokenをコピーします。
7. TokenをRepository Secretの`CLOUDFLARE_API_TOKEN`へ登録します。

TokenはGit、Issue、Slackへ貼り付けません。権限と対象Resourceは必要最小限にします。詳細は[CloudflareのAPI Token作成手順](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)を参照してください。

## Apple Developer / App Store Connect

PRマージ前にApp Store Connectへのアップロードまで確認する場合は、同一Repository内のPRへ`deploy-app-ios`ラベルを付与します。Fork由来のPRでは実行されません。通常のPR作成やpushではiOS配布を開始しません。

### App IDとApp Store Connectアプリ

1. Apple Developerの`Certificates, Identifiers & Profiles > Identifiers > + > App IDs`を開きます。
2. `Explicit App ID`を選び、本番は`jp.flutterkaigi.conf2026`、stg実機を使う場合は`jp.flutterkaigi.conf2026.stg`を登録します。XcodeのBundle IDと完全一致させます。[AppleのApp ID登録手順](https://developer.apple.com/help/account/identifiers/register-an-app-id/)を参照してください。
3. App Store Connectの`Apps > + > New App`を開き、Bundle IDに`jp.flutterkaigi.conf2026`を選んでアプリレコードを作成します。

### `APPLE_TEAM_ID`

[Apple Developer Account](https://developer.apple.com/account/)の`Membership details > Team ID`から取得します。2025年と同じTeamを使う場合でも、現在のMembership detailsで値を再確認してください。

### App Store Connect API Key一式

Team Keyを使用します。生成には通常Account HolderまたはAdmin権限が必要です。

1. App Store Connectで`Users and Access > Integrations > App Store Connect API > Team Keys`を開きます。
2. 初回でAPI accessが未有効の場合は、Account Holderが`Request Access`を実行します。
3. `Generate API Key`または`+`を選択します。
4. Key名を`github-actions-app-delivery`などとし、まず`Developer` roleで作成します。署名・アップロード権限で不足する場合だけ`App Manager`を検討します。
5. 画面の`Key ID`を`APP_STORE_CONNECT_API_KEY_ID`へ登録します。
6. 同じ画面の`Issuer ID`を`APP_STORE_CONNECT_API_KEY_ISSUER_ID`へ登録します。
7. `Download API Key`から`AuthKey_<KEY_ID>.p8`をダウンロードします。秘密鍵は一度しかダウンロードできないため、安全なPassword Managerにも保存します。

Apple公式の手順は[App Store Connect API](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api/)を参照してください。

`.p8`をGitHub Secret用にBase64化します。

```bash
base64 < AuthKey_XXXXXXXXXX.p8 | tr -d '\n'
```

出力全体をRepository Secretの`APP_STORE_CONNECT_API_KEY_BASE64`へ登録します。元の`.p8`はRepositoryへ追加しません。

## Android署名

### `ANDROID_SIGNING_KEYSTORE_BASE64`

Google Playからダウンロードする値ではなく、チームでUpload Keyを生成します。安全な管理端末で次を実行します。

```bash
keytool -genkeypair \
  -v \
  -keystore release.jks \
  -alias flutterkaigi2026 \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

生成した`release.jks`はPassword ManagerやSecrets Managerにもバックアップします。GitHub登録用の値は次で作ります。

```bash
base64 < release.jks | tr -d '\n'
```

出力全体をRepository Secretの`ANDROID_SIGNING_KEYSTORE_BASE64`へ登録します。

### `ANDROID_KEY_PROPERTIES_BASE64`

Keystore作成時のaliasとパスワードを使って、次の`key.properties`をローカルで作ります。

```properties
storeFile=release.jks
storePassword=<Keystoreのパスワード>
keyAlias=flutterkaigi2026
keyPassword=<Keyのパスワード>
```

`storeFile=release.jks`はworkflowが復元する`apps/app/android/app/release.jks`から見た相対パスです。次でBase64化します。

```bash
base64 < key.properties | tr -d '\n'
```

出力全体をRepository Secretの`ANDROID_KEY_PROPERTIES_BASE64`へ登録します。`release.jks`と`key.properties`はRepositoryへ追加しません。

## Google Play / Google Cloud

### Google Playアプリ

1. Google Play Consoleで新規アプリを作成します。
2. 最初のAABでPackage Nameが`jp.flutterkaigi.conf2026`になることを確認します。最初のArtifact upload後はPackage Nameを変更できません。
3. `Testing > Internal testing`でテスターリストを作成します。Internal Testingの設定方法は[Google PlayのInternal testing手順](https://support.google.com/googleplay/android-developer/answer/9845334)を参照してください。

### `GOOGLE_PLAY_SERVICE_ACCOUNT_BASE64`

1. Google Cloud ConsoleでCI用Projectを選び、`APIs & Services > Library > Google Play Android Developer API > Enable`を実行します。
2. `IAM & Admin > Service Accounts > Create service account`から、`github-actions-play-publisher`などのService Accountを作成します。Cloud ProjectのOwnerやEditorは通常不要です。
3. Google Play Consoleの`Users and permissions > Invite new users`で、Service Accountのメールアドレスを招待します。
4. 対象アプリを`jp.flutterkaigi.conf2026`だけに限定し、`Release apps to testing tracks`権限を付与します。Production公開権限は付与しません。[Google Play Developer APIの開始手順](https://developers.google.com/android-publisher/getting_started)を参照してください。
5. Google Cloud Consoleへ戻り、`IAM & Admin > Service Accounts > 対象Service Account > Keys > Add key > Create new key > JSON`を選択します。
6. ダウンロードされたJSONは再ダウンロードできないため、安全に保存します。組織ポリシーでService Account Key作成が禁止されている場合は管理者へ相談します。[Google CloudのService Account Key手順](https://docs.cloud.google.com/iam/docs/keys-create-delete)を参照してください。
7. JSONをBase64化します。

```bash
base64 < play-service-account.json | tr -d '\n'
```

出力全体をRepository Secretの`GOOGLE_PLAY_SERVICE_ACCOUNT_BASE64`へ登録します。

## Firebase SDK settings

FirebaseのAPI KeyやApp IDは、それ自体がFirebase Consoleやデータへの管理権限を与える秘密鍵ではありません。Firebaseの認可はIAM、Security Rules、Authentication、App Checkで行います。ただし、このRepositoryでは既存Dashboardと同じくFirebase OptionsをGitへコミットしない運用に揃えます。[FirebaseのAPI Key管理](https://firebase.google.com/docs/projects/api-keys)と[Firebase Security Rules](https://firebase.google.com/docs/rules/get-started)も参照してください。

配布Workflowは`apps/app`でFlutterFire CLIを実行し、Firebase Projectの現在の登録内容から次を生成してからビルドします。

- `apps/app/lib/firebase_options.dart`
- `apps/app/android/app/google-services.json`（Androidのみ）
- `apps/app/ios/Runner/GoogleService-Info.plist`（iOSのみ）
- `apps/app/firebase.json`

すべて`.gitignore`対象で、Firebase Options用のRepository Secretは使用しません。

再現性のため、Firebase CLIは`13.35.1`、FlutterFire CLIは`1.4.0`をWorkflowで明示してインストールします。FlutterFire CLIはAppの`intl`と依存制約が競合するため、Appのdev dependencyには追加せずglobal activateします。`flutterfire configure`には`--yes`、Project ID、Platform、Web App IDまたはPackage／Bundle ID、出力先を明示します。[FlutterFire CLIの非対話設定](https://github.com/invertase/flutterfire_cli#readme)を参照してください。

### 登録するFirebase Apps

| Project | Web | Android | Apple |
| --- | --- | --- | --- |
| `flutterkaigi-2026-stg` | `FlutterKaigi 2026 App Staging` | `jp.flutterkaigi.conf2026.stg` | `jp.flutterkaigi.conf2026.stg` |
| `flutterkaigi-2026-283db` | `FlutterKaigi 2026 App Production` | `jp.flutterkaigi.conf2026` | `jp.flutterkaigi.conf2026` |

各ProjectについてFirebase ConsoleのProject Overviewから`Add app`を選び、Web、Android、Appleを事前登録します。CI用Service Accountには読み取り権限だけを与えるため、CIがFirebase Appを新規作成することはありません。登録漏れやID不一致はビルドを失敗させます。

### Web App ID

1. Firebase Consoleで対象Projectを開き、`Project settings > General > Your apps > Web app`を選択します。
2. 対象Web Appの`App ID`を確認します。`1:<project-number>:web:<hash>`形式です。
3. stgは`STG_APP_FIREBASE_WEB_APP_ID`、prodは`PROD_APP_FIREBASE_WEB_APP_ID`へ登録します。

WebはPackage／Bundle IDによる一意照合ができないため、App IDを必ず明示します。これにより、複数のWeb AppがあるProjectでも先頭のAppが偶然選ばれることを防ぎます。

### App Check

FirestoreではApp Check enforcementが有効なため、公式Appを各PlatformのApp Checkへ登録します。AppはFirebase初期化後、Firestoreへアクセスする前に次のProviderを有効化します。

| Platform／Build | Provider | 追加設定 |
| --- | --- | --- |
| Web Debug | Debug Provider | 起動時にブラウザConsoleへ表示されるDebug Tokenを、Firebase Consoleの`App Check > Apps > 公式App用Web App > Manage debug tokens`へ登録します。 |
| Web Release | reCAPTCHA Enterprise | stg／prodのSite Keyをそれぞれ`STG_APP_CHECK_SITE_KEY`／`PROD_APP_CHECK_SITE_KEY`へ登録します。CloudflareのProduction DomainとPreview DomainをreCAPTCHA Enterprise Keyの許可Domainへ追加します。 |
| Android Debug | Debug Provider | 実機／EmulatorのLogcatへ表示されるDebug Tokenを、Android Appの`Manage debug tokens`へ登録します。 |
| Android Release | Play Integrity | Firebase Consoleの`App Check > Apps`で本番Android AppをPlay Integrityへ登録します。 |
| iOS Debug | Debug Provider | Xcode Logへ表示されるDebug Tokenを、Apple Appの`Manage debug tokens`へ登録します。 |
| iOS Release | App Attest（DeviceCheck fallback） | Firebase Consoleの`App Check > Apps`で本番Apple AppをApp Attestへ登録します。App Attest非対応端末ではDeviceCheckを使用します。 |

Site KeyとDebug Tokenは別物です。Site KeyはWeb配布物に含まれる公開値なのでRepository Variableで管理します。Debug Tokenは開発端末を信頼するための値なのでGitHubやRepositoryへ登録しません。App Checkの設定方法は[Flutter向けApp Check](https://firebase.google.com/docs/app-check/flutter/default-providers)と[Debug Provider](https://firebase.google.com/docs/app-check/flutter/debug-provider)を参照してください。

### CI認証

Firebase CLIは、既存Website Workflowと同じWorkload Identity Federationを使用します。`gcloud`コマンドやService Account JSON Keyは使用しません。`google-github-actions/auth`がGitHub OIDCからApplication Default Credentialsを作成し、Firebase CLIがその認証を自動検出します。[Firebase CLIのCI認証](https://firebase.google.com/docs/cli#use_the_cli_with_ci_systems)を参照してください。

stg／prodのCI Service Accountへ、対象Projectで次の読み取り専用Roleを付与します。

- `Firebase Viewer`（`roles/firebase.viewer`）
- `API Keys Viewer`（`roles/serviceusage.apiKeysViewer`）

取得・設定場所はGoogle Cloud Consoleの`IAM & Admin > IAM`です。対象Service Accountを選択し、`Grant access`／`Edit principal`から上記Roleを追加します。Firebase Appの作成権限を含む`Firebase Admin`や`Firebase Editor`は付与しません。

### CIで実行する構成

| 配布 | Project／Appの固定方法 | 生成対象 |
| --- | --- | --- |
| Web Preview | stg Project ID＋`STG_APP_FIREBASE_WEB_APP_ID` | Web Options |
| Web Production | prod Project ID＋`PROD_APP_FIREBASE_WEB_APP_ID` | Web Options |
| Android | prod Project ID＋`ANDROID_PACKAGE_NAME` | Dart Options＋`google-services.json` |
| iOS | prod Project ID＋`IOS_BUNDLE_ID`＋`Release` | Dart Options＋`GoogleService-Info.plist` |

生成直後にDart OptionsとNative設定ファイルのProject ID／App ID／Package Name／Bundle IDを指定値と照合し、一致しない場合はビルドを停止します。

App CIは実Projectへ接続しません。`firebase_options.stub.dart`をGit管理外の`firebase_options.dart`へコピーし、`apps/app`と`packages/data`だけを対象にformat/analyze/test、dprintを実行します。Firebase設定ファイルが未整備の`apps/dashboard`は、workflowの変更検知と各品質チェックの両方から明示的に除外しています。実行時はdev FlavorのFirebase Emulatorへ接続します。

OptionsをGit管理外にしても、それだけをデータ保護の境界にはできません。クライアント配布物からSDK設定を取得できるため、Firestore／Storage Rulesのテスト、API KeyのAPI・Application restrictions、App Check enforcementを配布前に確認します。[Firebase App Check](https://firebase.google.com/docs/app-check)はAuthenticationとSecurity Rulesを補完する仕組みです。

## 最終チェック

- Repository Variablesを17件登録した（既存Website用WIF 4件を共用）
- `ENABLE_APP_WEB_PRODUCTION_DEPLOY`を未登録または`false`にし、`apps/app`のProduction Web配布を停止した
- Repository Secretsを5件登録した
- Web PreviewとProductionで共用するCloudflare Tokenの権限を確認した
- Apple Team Keyの3値を登録し、`.p8`原本を安全に保管した
- Android Upload Keyの2つのBase64値を登録し、原本を安全に保管した
- Google Play Service AccountへTesting Trackだけの権限を付与した
- Firebaseへstg/prodそれぞれ3プラットフォームのAppを登録した
- Firebase App Checkへstg/prodの公式Appを登録し、WebのSite Keyと許可Domainを設定した
- stg/prodのCI Service AccountへFirebase ViewerとAPI Keys Viewerを付与した
- `firebase_options.dart`、`google-services.json`、`GoogleService-Info.plist`がGit管理外であることを確認した
- Firestore／Storage Rules、API Key restrictions、App Check enforcementを確認した
- RepositoryのBranch protectionで`App CI / spelling`、`App CI / style`、`App CI / validate`を必須Checkに設定した
