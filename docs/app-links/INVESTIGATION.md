# Web アプリの Universal Links / App Links 調査記録

調査日: 2026-09-22。対象: `apps/app` の Web / iOS / Android と `apps/website` の共有リンク。

## 調査後の実装差分

以下の対応をコードへ追加した。配布完了・OS実機での検証完了を示すものではない。現在の設定手順は [APP_DELIVERY.md](../../.github/APP_DELIVERY.md#universal-links--app-links) を参照。

- 本番は `2026-app.flutterkaigi.jp` とsuffixなしアプリ、stgは固定alias `stg-flutterkaigi-2026-conference-app.flutterkaigi.workers.dev` と `.stg` アプリを関連付ける。ネイティブのホスト設定には `.env.*` の `APP_LINK_HOST` を使用する。
- PR固有URLはWeb確認用とし、生成する交換QRは固定stg URLを使用する。PR配布物の検証JSONも `.stg` 用だが、PR固有ホスト自体の直接起動には対応しない。
- [generate_app_links.dart](../../tool/generate_app_links.dart) とWeb配布Workflowで環境別の検証ファイルを生成し、必須値の欠落・不正をアップロード前に検出する。Apple Team IDは登録済み。調査時に未登録だったstg / prod双方のAndroid SHA-256 Variablesも、2026-09-22にPlay Consoleで取得した値を登録した。本番は1件、stgは新旧の署名証明書3件を含む。
- 配布は検証ファイルを含むWebアプリを先行させる。Web失敗時は同時指定のネイティブ配布を停止し、websiteも転送先の本番AASAを確認してから公開する。stg固定aliasはPR配布では更新しない。
- Webをパス形式へ変更し、旧 `/#/route` を起動時に変換する。本番QR scannerは新旧本番URL、stg scannerは固定stg URLを受理し、他環境のURLは拒否する。devでは生トークンを表示する。
- 旧websiteの `/x/<token>` と `/en/x/<token>` は本番Webアプリへ302転送する。tokenなし・余分な階層は従来の案内ページを維持する。
- ログイン・プロフィール作成をまたぐpending処理とイベント機能フラグは維持する。pendingは永続化しておらず、Web→ネイティブでは完全な共有URLを渡す必要がある。

本番・stg両App IDのAssociated Domains / Provisioning Profileと、各PlayアプリのApp Signing SHA-256を設定し、ネイティブを再配布する必要がある。Safariの同一ドメイン制約も残る。実機・公開環境の検証結果は別途記録する。

## 実装の検証結果

- 関連するFlutterテスト88件、関連付けファイル生成のDartテスト43件、website WorkerのNodeテスト12件が成功した。
- Dart解析、変更したWorkflowのactionlint、フォーマット確認が成功した。dev設定によるFlutter Webのreleaseビルドも成功した。
- ローカルのWrangler配信で、両関連付けファイルのHTTP 200・`application/json`・生成内容との一致と、`/x/<token>` のSPA fallback・`Referrer-Policy: no-referrer` を確認した。
- ブラウザで旧 `/#/x/<token>` から `/x/<token>` への移行と、パスURLの再読み込み後にもプロフィール交換画面が表示されることを確認した。検証用の無効トークンでは、意図どおり無効リンクの案内が表示された。
- 登録した署名フィンガープリントをGitHubから読み戻して一致を確認し、実際のGitHub設定から本番・stg両方のAASA / assetlinksを生成できることを確認した。

公開環境へのデプロイ、署名付きネイティブビルド、およびOSによるリンク起動の実機検証は未実施。

---

**以下は実装前の調査記録。** 「現状」「現在」は初回調査時点を指し、ファイルの行番号も当時のもの。上記の実装後の状態とは区別する。

## 結論

`apps/app` の Web URL を、アプリがあればネイティブアプリ、なければ同じ URL の Web アプリで開く構成にできる。ただし現在の関連付けは `2026.flutterkaigi.jp/x/*` 用であり、Web アプリのホスト `2026-app.flutterkaigi.jp` は対象になっていない。

プロフィール交換は「Web の HTTP リダイレクトでネイティブアプリに渡す」実装ではない。`/x/:token` を直接アプリが受け取り、ログイン・プロフィール作成の画面遷移中にトークンをメモリへ保持し、条件がそろうと交換を再開する実装である。ブラウザへ到達した場合の現行 website は案内ページを返すだけで、Web アプリで交換を続ける導線がない。

推奨は、`https://2026-app.flutterkaigi.jp/x/<token>` などの HTTPS パスを Web / ネイティブ共通 URL とし、既存 `2026.flutterkaigi.jp/x/<token>` の互換性を残す構成。関連付け設定に加えて、Flutter Web の URL strategy と既存リンクの引き継ぎをそろえる必要がある。

## 現状の URL と配信設定

| 対象 | 現状 | コード根拠 |
| --- | --- | --- |
| QR / 共有 URL | `https://2026.flutterkaigi.jp/x/<token>` | [exchange_token.dart](../../apps/app/lib/feature/exchange/data/exchange_token.dart):10,28 |
| iOS | Associated Domains は `applinks:2026.flutterkaigi.jp` | [Runner.entitlements](../../apps/app/ios/Runner/Runner.entitlements):9–12 |
| Android | `autoVerify=true`、HTTPS の同ホスト、`pathPrefix=/x/` | [AndroidManifest.xml](../../apps/app/android/app/src/main/AndroidManifest.xml):32–43 |
| AASA | 対象パスは `/x/*`、出力先は website の `web/.well-known` | [generate_well_known.dart](../../tool/generate_well_known.dart):27–32,62–72 |
| assetlinks | package name と SHA-256 を環境変数から生成 | [generate_well_known.dart](../../tool/generate_well_known.dart):78–97 |
| website デプロイ | 関連付けファイルの生成あり。必要な変数が未設定なら生成をスキップし、デプロイ自体は成功し得る | [deploy_website.yaml](../../.github/workflows/deploy_website.yaml):104–117、[generate_well_known.dart](../../tool/generate_well_known.dart):34–51 |
| Web アプリ | ホストは `2026-app.flutterkaigi.jp`。SPA fallback 設定あり | [wrangler.toml](../../apps/app/wrangler.toml):6–12 |
| Web アプリのデプロイ | Web build / 配布はあるが、上記関連付けファイルの生成処理はない | [deploy_app_web.yaml](../../.github/workflows/deploy_app_web.yaml):95–112 |

`apps/app/lib` に `usePathUrlStrategy` / `setUrlStrategy` の設定は見当たらず、[main.dart](../../apps/app/lib/main.dart):18–74 も URL strategy を変更していない。Flutter の既定値は hash 形式なので、現状は `https://2026-app.flutterkaigi.jp/#/x/<token>` のような URL を扱う構成と判断できる。パス形式へ統一する場合、`runApp` 前の `usePathUrlStrategy` と、直接アクセス時の `index.html` fallback が必要になる。[Flutter URL strategy](https://docs.flutter.dev/ui/navigation/url-strategies)

## プロフィール交換と「リダイレクト」の実態

`/x/:token` はアプリのトップレベルルートとして定義されている。[routes.dart](../../apps/app/lib/core/router/routes.dart):12–24

```text
外部の共有リンク /x/<token>
  ├─ OS の関連付けが有効 → ネイティブアプリの /x/:token
  └─ ブラウザで開く → 現状は website の案内ページ

アプリの /x/:token
  → トークン形式・期限を確認
  → 認証状態の初回解決を待つ
  → (その時点の uid, token) を pending に保存
  → ログイン・プロフィールの条件を確認
  → 条件がそろえば交換処理
```

形式・期限チェック、認証待機、pending 保存、交換処理は [exchange_share_link_page.dart](../../apps/app/lib/feature/exchange/ui/page/exchange_share_link_page.dart):32–49,65–95,123–145 にある。

未ログイン時は `AccountRoute.go`、プロフィール未作成時は `ProfileEditRoute.push` で画面移動する。プロフィール保存後は `pop` する。[exchange_access_gate.dart](../../apps/app/lib/feature/exchange/ui/widget/exchange_access_gate.dart):90,105、[profile_edit_page.dart](../../apps/app/lib/feature/profile/ui/page/profile_edit_page.dart):168–176

ログインの寄り道から元の共有画面へ戻らなくても、`AccountPage` が pending を監視して交換を再開する。別アカウントへの切り替え等を考慮した UID の照合もある。[account_page.dart](../../apps/app/lib/feature/auth/ui/page/account_page.dart):47–119

ただし pending は Riverpod のメモリ上の状態であり、永続化されていない。Web → ネイティブの切り替え、ページリロード、プロセス終了をまたいでこの状態が移るわけではない。切り替え時には `/x/<token>` 全体を渡す必要がある。元の共有 URL を再度開けばトークンは再入力できる。[pending_exchange_token_provider.dart](../../apps/app/lib/feature/exchange/data/provider/pending_exchange_token_provider.dart):29–33

Google 認証は Web では popup、ネイティブでは provider を使っており、交換機能が Web の HTTP OAuth リダイレクトを前提にしているわけではない。[auth_repository.dart](../../packages/data/lib/src/repository/auth_repository.dart):67–77

なお `event_features_enabled=false` のときは、ルーターが `/x/*` を共有画面表示前に `/account` へ移す。この経路では共有画面による pending 保存は実行されない。イベント機能を無効化した場合の意図された制限として、動作確認時にも区別する必要がある。[router.dart](../../apps/app/lib/core/router/router.dart):69–95

このフラグのコード上の既定値は `true`。本番 Remote Config の値は今回確認していない。[remote_config_keys.dart](../../apps/app/lib/core/remote_config/remote_config_keys.dart):27–28

QR parser は現行の `exchangeShareBaseUrl` に一致する URL と生トークンを受け付ける。共有 URL のホストを変える場合、定数の置き換えだけでは旧 URL を読み取れなくなるため、新旧両方の受理が必要。[exchange_token.dart](../../apps/app/lib/feature/exchange/data/exchange_token.dart):41–54

6 桁コードによる交換は URL 起点ではなく、callable によるコード引き換え後にトークンを使う別の入口である。[exchange_code_redeem_handler.dart](../../apps/app/lib/feature/exchange/data/exchange_code_redeem_handler.dart):61

## website に到達した場合

`apps/website/worker.js` は `/x/<token>` のリクエストに対し、内部で `/x/` の静的アセットを取得して返す。`Location` を返す HTTP リダイレクトではなく、案内ページを共通化する内部 rewrite である。英語版 `/en/x/*` にも対応している。[worker.js](../../apps/website/worker.js):12–25,37–44

案内ページはトークンを読み取らず、案内文、設定済みの場合のストアリンク、ホームへのリンクを表示する。Web アプリへのリンクはない。現在ストア URL は iOS / Android ともに `null` なので、ストアボタンも出ない。[share_link_fallback.dart](../../apps/website/lib/pages/share_link_fallback.dart):8–25,33–46、[app_delivery.dart](../../apps/website/lib/constants/app_delivery.dart):10–12

このページはトークンを分析ログや Referer に載せない方針を持つ。Web アプリへの fallback を追加する場合も、その方針を維持しながらトークンを渡す必要がある。[share_link_fallback.dart](../../apps/website/lib/pages/share_link_fallback.dart):20–25

## 公式仕様からの設計上の注意

| 項目 | 確認した仕様 | 公式資料 |
| --- | --- | --- |
| アプリ / Web の分岐 | 関連付けされた URL をタップすると、アプリがあればアプリへ、なければ Web へ進む | [Apple TN3155](https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links)、[Android App Links](https://developer.android.com/training/app-links/about) |
| Web 処理の実行 | Universal Link はブラウザ / website を経由せずアプリへ直接渡る。Web 側の redirect 処理が毎回実行される前提にはできない | [Apple TN3155](https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links) |
| Safari の同一ホスト | 同じドメイン内のリンクはブラウザでの移動として扱う。Web 内に「アプリで開く」を設けるなら別サブドメインを使う方法が案内されている | [Apple TN3155](https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links) |
| iOS の直入力 / 選択 | アドレスバーへの URL 直入力はアプリを開かない。ユーザーが選んだリンクの開き方も影響する | [Apple TN3155](https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links) |
| redirect の区別 | 他アプリで非 Universal Link をタップして Universal Link へ redirect する形は、非推奨だが対応する。AASA 自体の配信は redirect 不可 | [Apple TN3155](https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links) |
| iOS の設定 | Associated Domains / `applinks:<host>` と、ホスト上の AASA に App ID・対象 URL を設定する | [Flutter iOS 設定](https://docs.flutter.dev/cookbook/navigation/set-up-universal-links) |
| Android の設定 | Manifest の intent filter / `autoVerify` と、ホスト上の `assetlinks.json` を設定する | [Android intent filters](https://developer.android.com/training/app-links/add-applinks) |
| assetlinks 配信 | `/.well-known/assetlinks.json` を HTTPS、`application/json`、301/302 なしで公開する。Play App Signing 使用時は配布アプリの署名 SHA-256 を用いる | [Android website associations](https://developer.android.com/training/app-links/configure-assetlinks) |
| Flutter の受信 | Flutter 3.27 以降は標準 deep-link handler が既定で有効。`go_router` で受け取れる。別プラグインを使う場合は標準 handler との競合に注意する | [Flutter iOS 設定](https://docs.flutter.dev/cookbook/navigation/set-up-universal-links)、[Flutter Android 設定](https://docs.flutter.dev/cookbook/navigation/set-up-app-links) |
| アプリ内 redirect | `go_router.redirect` はナビゲーションに対するアプリ内コールバック。HTTP redirect とは別で、ネイティブでも動作する | [go_router Redirection](https://pub.dev/documentation/go_router/latest/topics/Redirection-topic.html) |

したがって、要件は「インストール済みなら常に強制起動」ではなく「OS / ブラウザのリンク処理とユーザー設定が許す場合にアプリへ、その他は Web でも成立する」と捉える必要がある。

## 推奨する対応範囲

1. `2026-app.flutterkaigi.jp` を iOS / Android の関連付けへ追加し、同ホストでも AASA / assetlinks を配信する。既存 website ホストの関連付けは残す。
2. Flutter Web を `/x/<token>` のようなパス形式へ統一する。既存 hash URL の移行と、直接アクセス・再読み込み時の挙動を確認する。SPA fallback と関連付け JSON の配信を両立させる。
3. 今後生成する共有リンクを共通 URL にそろえ、QR parser は新旧ホストを受け付ける。一般画面も対象にする場合は、アプリが実際に扱えるパスを関連付けの対象として決める。
4. 旧 website URL がブラウザで開かれたときは、トークンを維持して Web アプリへ進める fallback を追加する。ネイティブが旧 URL を直接受け取る経路も維持する。
5. ログイン・プロフィール作成をまたぐ再開は現行の pending 処理を活用する。Web → ネイティブ移動時には pending の共有を期待せず、完全な共有 URL を渡す。
6. 同一ホストの Web 画面内に「アプリで開く」を追加する場合は、Safari の制約を踏まえた別ホストの明示リンクを検討する。自動 redirect の成功だけに依存しない。

## 検証状況と未確認事項

2026-09-22 に以下の公開エンドポイントを読み取り GET で確認したが、調査環境からは全件 `403`、`Content-Type: text/plain`、本文 `error code: 1010` が返った。

| ホスト | 確認したパス |
| --- | --- |
| `2026.flutterkaigi.jp` | `/.well-known/apple-app-site-association`、`/.well-known/assetlinks.json`、`/x/investigation-invalid-token` |
| `2026-app.flutterkaigi.jp` | `/.well-known/apple-app-site-association`、`/.well-known/assetlinks.json`、`/x/investigation-invalid-token` |

この応答だけから、実際の公開ファイルの有無、Apple / Android による取得可否、端末上のリンク起動可否は断定できない。Repository Variables、署名済みアプリの配布設定、公開レスポンスの内容は別途確認が必要。

既存の交換関連テストは fake を使った unit / widget テストで、OS のリンク起動を含む E2E の確認にはならない。今回テスト実行と実機確認は行っていない。

実装時には最低限、以下を確認する。

- iOS / Android のインストール有無、終了状態 / 起動中、外部アプリからのリンク、Safari の同一 / 別ホストリンク。
- 新旧 URL、QR スキャン、Web への直接アクセスと再読み込み、旧 hash URL。
- 認証済み、未ログイン、プロフィール未作成、アカウント切り替え、画面移動中の再読み込み。
- 期限切れ・不正トークン、連続した別トークン、イベント機能の有効 / 無効。
- 配布署名と関連付けファイルの一致、および関連付け JSON が HTML fallback / redirect / アクセス制限へ流れないこと。
