# App delivery setup

> [!NOTE]
> この文書は、公開リポジトリで管理するメンテナー向けの配布Runbookです。
> Secret、Token、秘密鍵、パスワード、Service Account JSON、Debug Tokenの実値は記載しません。
> 外部Contributorのローカル開発には、ここで説明するstg／prodの権限や設定は不要です。

`apps/app`のCI/CDは次のworkflowで構成します。公式サイト `apps/website` の本番・プレビューは、それぞれ
`deploy_website.yaml` / `preview_website.yaml` として独立させます。
app・website は本番の変更検知、PRプレビューの変更検知、配布先、PRコメントの更新先を分けます。
各アプリだけの変更は対応するworkflowで処理し、SDKや共有データモデルの変更は両方で検証します。

| Workflow | Trigger | Delivery target |
| --- | --- | --- |
| `Workflows CI` | workflow・共通action・配布script関連のPR、手動 | actionlint、配布scriptのテスト（main pushでの単独実行なし） |
| `App CI` | app関連のPR、配布Workflowからの呼び出し、手動 | format/analyze/test、dprint |
| `Deploy App` | app関連の `main` push、正式なGitHub Releaseの公開、手動 | iOS / Android / Web を stg と prod へ配布 |
| `Preview App Web` | app関連のPR、手動 | stg に接続するPR別のWebプレビュー |
| `Deploy Firebase` | Firebase関連の `main` push、`main` から手動 | Rules・Indexes・Functions。stg は自動、prod は手動のみ |
| `Dashboard CI` | dashboard関連のPR、配布Workflowからの呼び出し、手動 | format/analyze/test、dev の Web ビルド |
| `Deploy Dashboard` | dashboard関連の `main` push、`main` から手動 | dashboard の Firebase Hosting。stg は自動、prod は手動のみ |

`Workflows CI` はPRでworkflowと配布scriptを検証します。mainでは各 `Deploy` が必要なアプリのCIを呼んでから配布するため、検証だけのworkflowを別途起動しません。依存バージョンだけの変更も取りこぼさないよう、`pubspec.lock` を変更検知に含めます。

CIの自動キャンセルは同じPRの古い検証に限定します。手動CIや配布から呼び出すCIは実行IDごとに分け、同じmainを使う別の配布をキャンセルしないようにします。実際の配布は対象環境ごとの排他制御を使います。

2025 と同じく、公開URLを持つ本番Webの配布を Deployments に記録します。
Webアプリは `app-website`、公式サイトは `website` とし、コミット・配布先URL・成功/失敗を記録します。
stg・PRプレビュー・ストアへのアップロード・Firebase設定の適用はActionsの実行結果で確認します。
環境名を空にせず、[Environment の `deployment` 設定](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments#using-environments-without-deployments)で、本番への配布時だけ記録を有効にします。

配布の入口は `deploy_app.yaml` に集約しています。iOS / Android / Web の実装は
`workflow_call` で呼び出す専用ファイルに分け、Flutter SDK と Firebase 認証・CLI の準備は
`.github/actions` の共通アクションを使います。Web の配布処理は PR プレビューでも共用します。
手動実行では対象OSと環境を選択でき、環境の初期値は `all`（stg と prod）です。
環境ごとの `fail-fast: false` と排他制御により、一方の失敗で他方を中断せず、同じアプリの採番・配布は直列化します。

Firebase配布の準備と実行手順は[Firebase 配布手順](FIREBASE_DELIVERY.md)を参照してください。

### 自動配布の起点

[FlutterKaigi 2025](https://github.com/FlutterKaigi/2025/blob/main/.github/workflows/deploy-app.yaml)と同じく、
app関連の `main` 更新または正式リリースの `released` イベントで、iOS / Android / Web を同じコミットから **stg と prod の両方**へ配布します。
iOS は TestFlight、Android は Google Play の内部テストまでを自動化します。
ストア審査への提出と一般公開はストア管理画面から行います。
PR は Web Preview で確認し、ネイティブアプリの確認は手動実行で prod / stg を選択します。
Web の stg は既存の Workers プレビューへ `stg` エイリアスを付けて配布し、固定のプレビューURLを更新します。
prod は既存のカスタムドメインへ配布します。各環境のビルド番号・排他制御・Firebase 設定は独立しています。
アプリ Web 本番の一時停止フラグ `ENABLE_APP_WEB_PRODUCTION_DEPLOY` は廃止します。

自動配布を有効にする PR のマージ前に、Android の初回登録、必要な Variables / Secrets、
Web 本番用 App Check の設定を完了してください。

## 初回配布とstg

Androidの初回は `Deploy App` で Android のみを選び、 `upload_to_play=false` で実行し、
Artifactsから署名済みAABを取得してPlay Consoleの内部テストへ手動アップロードします。
このモードはGoogle Play APIの認証を要求しません。2回目以降は
`upload_to_play=true` で内部テストへアップロードできます。
`main` push と正式リリースでは `upload_to_play=true` として stg / prod の両方を内部テストへ配布します。

手動実行の `environment=stg` は `.env.stg`、stgのFirebase/WIF、
`jp.flutterkaigi.conf2026.stg` を使用します。本番とは別のApp Store Connect / Play Console
アプリレコードが必要で、Androidのstgも初回アップロードを行います。
既存のAppleチームキーとAndroidアップロード鍵を使用するため、
その権限・証明書がstgにも適用されていることを確認してください。
stgのAndroidでもPlay Integrityを使用するため、ストア外へのAPK配布はこのWorkflowの対象ではありません。

### ビルド番号

iOSは App Store Connect の同じ公開バージョン・同じ環境の最新ビルド番号に1を加算します。
期限切れのビルドも含めて取得し、未アップロードの場合のみ1から開始します。
API の認証失敗を0扱いにせず停止し、アップロード後は登録反映を確認してから次の実行に進みます。
本番の `1.0.0 (401)` は旧式 `GITHUB_RUN_NUMBER * 100 + GITHUB_RUN_ATTEMPT` による番号でした。
以後はストアに登録された最新番号から402、403、404と増加します。
次の公開バージョン（例: `1.0.1`）へ上げた際は、そのバージョンのビルドを **1** から開始します。
アプリ内に表示するビルド番号も、App Store Connect に登録する実際の番号と揃えます。
Androidは FlutterKaigi 2025 と同じく Google Play の最新番号に1を加算します。
取得に失敗した場合は番号を推測せず停止します。初回の手動アップロード用AABは1です。
Android の `versionCode` は公開バージョンを上げてもリセットせず、アプリ全体で増やし続けます。
`upload_to_play=false` は初回専用とし、登録後は `true` で既存番号を取得してください。
Xcode Export時の番号自動変更を無効にし、IPA内のBundle ID・公開バージョン・ビルド番号を
アップロード前に検証します。番号、環境、コミットはActionsのSummaryに記録されます。

同じ公開バージョン内では小さい番号へ戻さず、既存ストアの番号を継続してください。
ストアが表示するバージョン（`1.0.0`）とビルド番号（例: `401`）は別の値です。

### iOS の輸出コンプライアンス

2025年と同じく `Info.plist` に `ITSAppUsesNonExemptEncryption=false` を含めます。
現在のクライアントの暗号化用途は HTTPS/TLS と認証で、独自の暗号化機能は提供していません。
iOS の配布ジョブは、書き出した IPA にもこの値が含まれることをアップロード前に検証します。
設定が反映されるのは、この変更を含む新しいビルドからです。
暗号化機能・依存ライブラリの利用用途を変更するときは、
[Apple の輸出コンプライアンス手順](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations)
に沿って申告内容も見直してください。

## GitHub側の登録場所

環境差分はRepository Variableの接頭辞（`STG`／`PROD`）と`apps/app/environments/.env.stg`／`.env.prod`で管理します。Firebase OptionsはコミットやSecret登録をせず、各ビルドでFlutterFire CLIから生成します。

### Repository Variables

Repositoryの`Settings > Secrets and variables > Actions > Variables > New repository variable`から登録します。Variablesはログでマスクされないため、秘密鍵やTokenは登録しません。詳細は[GitHubのVariables設定手順](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-variables)を参照してください。

| Variable | 設定値 | 取得元・取得方法 |
| --- | --- | --- |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare Account ID | Cloudflare Dashboardの`Workers & Pages > Overview > Account details`で`Account ID`をコピーします。Repositoryに記録された値は`apps/website/wrangler.toml`でも確認できます。[Cloudflare: Find account and zone IDs](https://developers.cloudflare.com/fundamentals/account/find-account-and-zone-ids/) |
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
| `STG_ANDROID_SHA256_FINGERPRINTS` | stg Android Appの署名証明書SHA-256フィンガープリント（カンマ区切り、複数可） | `.stg` アプリのPlay App Signing証明書を指定します。stg／PRプレビューの `assetlinks.json` 生成に必須です。取得手順は後述の「Universal Links / App Links」を参照してください。 |
| `PROD_ANDROID_SHA256_FINGERPRINTS` | 本番Android Appの署名証明書SHA-256フィンガープリント（カンマ区切り、複数可） | 本番アプリのPlay App Signing証明書を指定します。Webアプリ本番の `assetlinks.json` 生成に必須で、旧共有リンク用の `apps/website` でも使用します。 |

### Repository Secrets

Repositoryの`Settings > Secrets and variables > Actions > Secrets > New repository secret`から登録します。Web UIのほか、GitHub CLIへ再認証済みならRepositoryルートで`gh secret set SECRET_NAME`でも登録できます。詳細は[GitHubのActions Secrets設定手順](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)を参照してください。

Base64から復元した秘密鍵やパスワードは、配布ツールへ渡す前に`.github/scripts/mask_credentials.py`でログのマスク対象へ登録します。
Base64のSecretだけでは復元後の値のマスクは保証されません。マスク登録に失敗した場合は、機密値を表示せず配布を停止します。

| Secret | 使用先 | 取得元・取得方法 |
| --- | --- | --- |
| `CLOUDFLARE_API_TOKEN` | Web Preview／Production | Cloudflare Dashboardの`Manage Account > Account API Tokens`から、後述の権限とResource範囲に限定して作成します。 |
| `APP_STORE_CONNECT_API_KEY_BASE64` | iOS prod / stg | App Store Connect APIの認証・ビルド番号取得・アップロードに使用するTeam Key（`.p8`）をBase64化します。 |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | iOS prod / stg | CIで再利用するApple Distribution証明書と秘密鍵を含む`.p12`をBase64化します。両環境で同じ証明書を使います。 |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | iOS prod / stg | `.p12`を書き出した際のパスワードをそのまま登録します。Base64化しません。 |
| `STG_IOS_PROVISIONING_PROFILE_BASE64` | iOS stg | 共通の配布証明書を含む`jp.flutterkaigi.conf2026.stg`用のApp Store Connect配布プロファイルをBase64化します。 |
| `PROD_IOS_PROVISIONING_PROFILE_BASE64` | iOS prod | 共通の配布証明書を含む`jp.flutterkaigi.conf2026`用のApp Store Connect配布プロファイルをBase64化します。 |
| `ANDROID_SIGNING_KEYSTORE_BASE64` | Android prod / stg | チームで生成・保管するAndroid Upload Key（`release.jks`）をBase64化します。 |
| `ANDROID_KEY_PROPERTIES_BASE64` | Android prod / stg | Upload Keyのaliasとパスワードを記載した`key.properties`をBase64化します。 |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_BASE64` | Android prod / stg | Google Cloudで発行したGoogle Play配布用Service Account JSONをBase64化します。 |

## Cloudflare

### `CLOUDFLARE_ACCOUNT_ID`

取得場所は`Workers & Pages > Overview > Account details > Account ID`です。Repositoryに記録された値は`apps/website/wrangler.toml`を参照してください。Wranglerによる非対話CIにはAccount IDとAPI Tokenが必要です。[CloudflareのGitHub Actions手順](https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/)も参照してください。

### `CLOUDFLARE_API_TOKEN`

Web配布WorkflowはRepository Secretの`CLOUDFLARE_API_TOKEN`を使用します。Tokenの権限とResource範囲は次のとおりです。

1. Cloudflare Dashboardで`Manage Account > Account API Tokens`を開きます。Account Tokenを作れない場合は`My Profile > API Tokens`からUser Tokenを作成します。
2. `Create Token`を選択します。
3. TemplateまたはCustom permissionsで`Edit Cloudflare Workers`を選択します。
4. Account resourceをFlutterKaigiの対象Accountだけに限定します。
5. Custom Domainを操作するため、Zone resourceを`flutterkaigi.jp`だけに限定し、Workers Routesの更新権限も付与します。
6. `Continue to summary > Create Token`を選び、作成直後に一度だけ表示されるTokenをコピーします。
7. TokenをRepository Secretの`CLOUDFLARE_API_TOKEN`へ登録します。

TokenはGit、Issue、Slackへ貼り付けません。権限と対象Resourceは必要最小限にします。詳細は[CloudflareのAPI Token作成手順](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)を参照してください。

## Apple Developer / App Store Connect

PRマージ前にApp Store Connectへのアップロードまで確認する場合は、`Deploy App` で iOS のみを選んで手動実行し、対象ブランチと `environment=stg` を選択します。本番接続版が必要な場合は `prod` を選択します。`main` 更新と正式リリースでは stg / prod の両方を自動アップロードします。

### App IDとApp Store Connectアプリ

1. Apple Developerの`Certificates, Identifiers & Profiles > Identifiers > + > App IDs`を開きます。
2. `Explicit App ID`を選び、本番は`jp.flutterkaigi.conf2026`、stg実機を使う場合は`jp.flutterkaigi.conf2026.stg`を登録します。XcodeのBundle IDと完全一致させます。[AppleのApp ID登録手順](https://developer.apple.com/help/account/identifiers/register-an-app-id/)を参照してください。
3. App Store Connectの`Apps > + > New App`を開き、Bundle IDに`jp.flutterkaigi.conf2026`を選んでアプリレコードを作成します。
4. Sign in with Appleは環境に関係なくiOSアプリで使用します。本番・stgを含む署名対象の各App IDでCapabilityを有効化し、対応するProvisioning Profileを用意します。Firebase Authenticationでも対象プロジェクトのAppleプロバイダを有効化します。Web OAuthを提供しないため、Services IDの作成は不要です。

### `APPLE_TEAM_ID`

[Apple Developer Account](https://developer.apple.com/account/)の`Membership details > Team ID`から取得し、現在のMembership detailsに表示される値を使用してください。

### App Store Connect API Key一式

Team Keyを使用します。生成には通常Account HolderまたはAdmin権限が必要です。
この`.p8`はApp Store Connect APIの認証・ビルド番号取得・アップロード用です。
アプリへの署名には、後述する配布証明書・秘密鍵・プロファイルを別途使用します。

1. App Store Connectで`Users and Access > Integrations > App Store Connect API > Team Keys`を開きます。
2. 初回でAPI accessが未有効の場合は、Account Holderが`Request Access`を実行します。
3. `Generate API Key`または`+`を選択します。
4. Key名を`github-actions-app-delivery`などとし、まず`Developer` roleで作成します。APIの読み取り・アップロード権限で不足する場合だけ`App Manager`を検討します。
5. 画面の`Key ID`を`APP_STORE_CONNECT_API_KEY_ID`へ登録します。
6. 同じ画面の`Issuer ID`を`APP_STORE_CONNECT_API_KEY_ISSUER_ID`へ登録します。
7. `Download API Key`から`AuthKey_<KEY_ID>.p8`をダウンロードします。秘密鍵は一度しかダウンロードできないため、安全なPassword Managerにも保存します。

Apple公式の手順は[App Store Connect API](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api/)を参照してください。

macOSでは、`.p8`をGitHub Secret用にBase64化して、ターミナルへ表示せずクリップボードへコピーできます。

```bash
base64 < AuthKey_XXXXXXXXXX.p8 | tr -d '\n' | pbcopy
```

Repository Secretの`APP_STORE_CONNECT_API_KEY_BASE64`へ貼り付けます。元の`.p8`はRepositoryへ追加しません。

### iOS配布用の証明書とプロファイル

CI専用のApple Distribution証明書と、その秘密鍵を含む`.p12`をstg／prodで共用します。
`.p8`は署名用の秘密鍵の代わりにはなりません。既存証明書を再利用する場合も、
その証明書に対応する秘密鍵が必要です。

1. Apple Developerの対象TeamでApple Distribution証明書を用意し、秘密鍵と合わせてパスワード付き`.p12`へ書き出します。
2. stg／prodそれぞれのApp IDに対して、同じ配布証明書を含むApp Store Connect配布用の`.mobileprovision`を用意します。両方のApp IDでSign in with Appleなど、アプリが使うCapabilityを有効にします。
3. `.p12`・パスワード・各環境のプロファイルを、上記4つのRepository Secretsへ登録します。原本は安全なPassword Managerなどへ保管し、Repositoryへ追加しません。
4. `Deploy App`をiOSのみ・`environment=stg`で手動実行し、Archive・IPA書き出し・TestFlightへの登録を確認します。その後、`environment=prod`でも同じ確認を行います。

macOSで、準備したファイルを置いたディレクトリから次を**1つずつ**実行し、
その都度対応するSecretへ貼り付けます。秘密値はターミナルへ表示しません。

```bash
# IOS_DISTRIBUTION_CERTIFICATE_BASE64
base64 < distribution.p12 | tr -d '\n' | pbcopy

# IOS_DISTRIBUTION_CERTIFICATE_PASSWORD
pbcopy < p12-password.txt

# STG_IOS_PROVISIONING_PROFILE_BASE64
base64 < stg.mobileprovision | tr -d '\n' | pbcopy

# PROD_IOS_PROVISIONING_PROFILE_BASE64
base64 < prod.mobileprovision | tr -d '\n' | pbcopy
```

配布ジョブは実行ごとの専用キーチェーンへ`.p12`を取り込み、選択した環境のプロファイルをインストールします。
Runnerターゲットが読み込む`apps/app/ios/Flutter/Signing.xcconfig`を一時生成して手動署名を指定し、
依存するSwift Packageへプロファイルの指定を広げません。
Archive・IPA書き出しのどちらでも自動プロビジョニングを許可せず、CIから証明書を新規発行しません。
処理の成功・失敗にかかわらず、最後に専用キーチェーン・プロファイル・一時ファイルを削除します。
ローカル開発では`Signing.xcconfig`を用意する必要はありません。

証明書とプロファイルには有効期限があり、CIで自動更新しません。
期限前に新しい配布証明書・秘密鍵を用意し、**その証明書を含むstg／prod両方のプロファイル**を作り直します。
配布が実行されていない間に`.p12`・パスワード・両方のプロファイルのSecretsをまとめて差し替え、
stg → prodの順で配布を確認します。証明書だけを変更すると、旧証明書に紐づくプロファイルでは署名できません。
App IDのCapabilityを変更した場合も、対応するプロファイルを再生成します。
不要になった旧証明書は、他の配布処理で使用していないことを確認してから整理します。

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

## Universal Links / App Links

Webアプリとネイティブアプリは同じ `/account` や `/x/<token>` などのパスを使います。OSが関連付けを有効と判断するとアプリへ、アプリがない場合などはWebへ進みます。

| 環境 | アプリ起動用のホスト | iOS Bundle ID / Android Package Name |
| --- | --- | --- |
| prod | `2026-app.flutterkaigi.jp` | `jp.flutterkaigi.conf2026` |
| stg | `stg-flutterkaigi-2026-conference-app.flutterkaigi.workers.dev` | `jp.flutterkaigi.conf2026.stg` |
| PRプレビュー | Webの確認にはPR固有URL、生成するQRには上記stg固定ホスト | `jp.flutterkaigi.conf2026.stg` |

ネイティブ設定は `apps/app/environments/.env.*` の `APP_LINK_HOST` を使用します。ホストを追加・変更した場合はネイティブの再ビルド・再配布が必要です。iOSでは本番・stg両方のApp IDにAssociated Domains Capabilityを設定し、対応するProvisioning Profileを使用してください。[Flutter iOS設定](https://docs.flutter.dev/cookbook/navigation/set-up-universal-links)

PR固有の `workers.dev` URL自体はネイティブへの直接起動対象ではありません。各プレビューに `.stg` 用の検証ファイルを含めても、未登録のホストが自動で関連付けられるわけではありません。stg固定URLは最新stg版を表示し、PR固有版を表示するURLとは異なります。固定aliasは `main` または手動のstg Web配布で更新し、PRプレビューの配布では更新しません。[Cloudflare Preview URLs](https://developers.cloudflare.com/workers/versions-and-deployments/preview-urls/)

### 検証ファイルの生成と公開

`Deploy App Web` は [tool/generate_app_links.dart](../tool/generate_app_links.dart) に `--environment=prod|stg` を渡し、AASAとassetlinksを生成します。PRプレビューはstg限定です。以下の環境変数はすべて必須で、未設定・形式不正・環境とApp IDの不一致はアップロード前に失敗します。

| 生成CLIの環境変数 | Workflowでの設定 |
| --- | --- |
| `APPLE_TEAM_ID` | 同名のRepository Variable |
| `IOS_BUNDLE_ID` | prodは同名Variable、stgは `jp.flutterkaigi.conf2026.stg` |
| `ANDROID_PACKAGE_NAME` | prodは同名Variable、stgは `jp.flutterkaigi.conf2026.stg` |
| `ANDROID_SHA256_FINGERPRINTS` | prodは `PROD_ANDROID_SHA256_FINGERPRINTS`、stg／PRは `STG_ANDROID_SHA256_FINGERPRINTS` |

ローカルでは上記4変数に対象環境の値を設定して、Repositoryルートで実行します。

```bash
fvm dart tool/generate_app_links.dart --environment=stg --output-dir=/tmp/flutterkaigi-stg-app-links
```

`--output-dir` を省略すると `apps/app/build/web/.well-known` へ出力するため、Webビルド後に実行します。Workflowは先に一時ディレクトリへ生成し、ビルド後にコピーします。配信後は対象URLの `/.well-known/apple-app-site-association` と `/.well-known/assetlinks.json` がredirectなしのHTTP 200・`application/json`で取得でき、内容が生成結果と一致することを確認します。

[配信確認スクリプト](scripts/verify_app_links.py) は、公開直後の反映を最大5分待ちます。HTTPエラーだけでなく、HTML応答・Content-Type不一致・古いJSON・redirectも10秒間隔で再検証し、期限まで一致しなければ配布を失敗にします。各試行のHTTPステータス・Content-Type・不一致理由をログへ記録し、レスポンス本文は出力しません。

旧 `2026.flutterkaigi.jp/x/<token>` の本番関連付けは残します。ブラウザに到達した旧リンクは、トークンを保持した302で本番Webアプリへ進みます。website側は従来の `tool/generate_well_known.dart` を引き続き使い、未設定のプラットフォームは生成をスキップするため、Webアプリ側の必須チェックとは挙動が異なります。

### Androidの署名フィンガープリント

Google PlayのInternal TestingからインストールしたアプリはPlay App Signingの証明書で検証されます。CIのUpload Keyだけでは一致しません。本番とstgのアプリごとに、Play ConsoleのApp integrity / App signingで `App signing key certificate` のSHA-256を取得し、それぞれ `PROD_ANDROID_SHA256_FINGERPRINTS` / `STG_ANDROID_SHA256_FINGERPRINTS` へ登録してください。値は32バイトのコロン区切り16進数で、複数ある場合はカンマ区切りです。[Androidの関連付け設定](https://developer.android.com/training/app-links/configure-assetlinks)

2026-09-22にPlay Consoleの署名設定から値を取得し、両環境の `*_ANDROID_SHA256_FINGERPRINTS` をRepository Variablesへ登録しました。本番は1件、stgは以前の鍵・現行の従来鍵・ポスト量子暗号鍵の3件です。アップロード鍵は含めていません。登録値を読み戻し、`app-website` Environmentの設定も含めた実際のGitHub設定から、両環境のAASA / assetlinksを生成できることを確認しました。署名鍵の更新時には、配布対象の新旧証明書が含まれるようVariableも更新してください。

### 初回の配布順序

1. stg / prodの署名フィンガープリントを登録し、iOS両App IDのCapabilityとProvisioning Profileを準備します。
2. `Deploy App` をWebのみ・両環境で実行し、本番ホストとstg固定aliasのアプリ・検証ファイルを先に公開します。PRプレビューの配布だけではstg固定aliasは更新されません。
3. ネイティブをビルド・配布し、websiteの配布を実行します。先行して停止したwebsiteのジョブは、Webアプリ公開後に再実行します。

`Deploy App` でWeb配布も指定した場合、iOS / AndroidはWebの成功後に進み、Webが失敗するとネイティブ配布も停止します。手動の `web=false` はネイティブだけの配布を許可しますが、関連付けファイルが事前公開済みであることが前提です。websiteのWorkflowも、旧リンクの転送を公開する前に本番WebアプリのAASAがHTTP 200・JSON・本番App IDで取得できることを確認します。初回にappとwebsiteの配布が並行する場合に備え、website側は最大10分待ってから失敗にします。

### 動作確認時の注意

- iOS / Androidの関連付けと、インストール済み・未インストール、アプリ終了中・起動中を実機で確認します。実装変更だけで端末上の成功を確認したことにはなりません。
- Safariの同一ドメイン内リンクやアドレスバーへの直入力はブラウザに残る場合があります。[Apple TN3155](https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links)
- 旧 `/#/route` は起動時にパス形式へ変換します。本番scannerは新本番URLと旧website URL、stg scannerはstg固定URLを受け付け、他環境のURLを拒否します。devのQRはEmulator用の生トークンです。
- 交換のpending状態はメモリ内です。Webからネイティブへの切り替えには `/x/<token>` 全体を渡し、ログイン途中の再読み込み・プロセス終了後は元リンクから再開します。`event_features_enabled=false` の交換機能制限は維持します。

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
| Android | 選択環境のProject ID＋Package Name | Dart Options＋`google-services.json` |
| iOS | 選択環境のProject ID＋Bundle ID＋`Release` | Dart Options＋`GoogleService-Info.plist` |

生成直後にDart OptionsとNative設定ファイルのProject ID／App ID／Package Name／Bundle IDを指定値と照合し、一致しない場合はビルドを停止します。

App CIは実Projectへ接続しません。`firebase_options.stub.dart`をGit管理外の`firebase_options.dart`へコピーし、`apps/app`と`packages/data`だけを対象にformat/analyze/test、dprintを実行します。`apps/dashboard`はApp CIの変更検知と品質チェックの対象外で、独立した`Dashboard CI`で検証します。dashboardのHosting配布は`Deploy Dashboard`が担当します（[配布手順](FIREBASE_DELIVERY.md#dashboard-の配布)）。実行時はdev FlavorのFirebase Emulatorへ接続します。

OptionsをGit管理外にしても、それだけをデータ保護の境界にはできません。クライアント配布物からSDK設定を取得できるため、Firestore／Storage Rulesのテスト、API KeyのAPI・Application restrictions、App Check enforcementを配布前に確認します。[Firebase App Check](https://firebase.google.com/docs/app-check)はAuthenticationとSecurity Rulesを補完する仕組みです。

## 設定チェックリスト

- 配布に必要なRepository Variablesを登録している
- 上記のRepository Secretsを登録し、実値をRepository、Issue、PR、ログへ出力していない
- Cloudflare Tokenの権限とResource範囲を必要最小限にしている
- Apple Team Keyの3値を登録し、`.p8`原本を安全に保管している
- 共通のApple Distribution証明書・秘密鍵の`.p12`とパスワード、stg/prodそれぞれの配布プロファイルをSecretsへ登録し、原本と有効期限を管理している
- Android Upload Keyの2つのBase64値を登録し、原本を安全に保管している
- Google Play Service AccountへTesting Trackだけの権限を付与している
- Firebaseへstg/prodそれぞれ3プラットフォームのAppを登録している
- Firebase App Checkへstg/prodの公式Appを登録し、WebのSite Keyと許可Domainを設定している
- stg/prodのCI Service AccountへFirebase ViewerとAPI Keys Viewerを付与している
- `firebase_options.dart`、`google-services.json`、`GoogleService-Info.plist`がGit管理外であることを確認している
- Firestore／Storage Rules、API Key restrictions、App Check enforcementを確認している
- RepositoryのBranch protectionで`App CI / style`と`App CI / validate`を必須Checkに設定している
- `STG_ANDROID_SHA256_FINGERPRINTS` / `PROD_ANDROID_SHA256_FINGERPRINTS`に各アプリのPlay App Signing証明書SHA-256を登録している
- iOSの両App IDでAssociated Domainsを有効にし、対応するProvisioning Profileでネイティブアプリを再配布している
- 本番・stg固定ホストと旧websiteホストで検証ファイルを公開し、実機でリンクの起動先とWeb fallbackを確認している
