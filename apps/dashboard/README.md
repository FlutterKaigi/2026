# dashboard

FlutterKaigi 2026 管理ダッシュボード（Flutter Web）。

## セットアップ

stg / prod に接続するには `flutterfire configure` で設定ファイルを生成する必要がある（gitignore されているため各自実行が必要）。

```bash
cd apps/dashboard
flutterfire configure
```

dev 環境はエミュレータに接続するため設定ファイル不要。`fvm dart run melos dashboard:run:dev` でそのまま起動できる。

## 環境

| FLAVOR | 接続先 |
| --- | --- |
| `dev` | Firebase エミュレータ（ローカル） |
| `stg` | Firebase Staging プロジェクト |
| `prod` | Firebase Production プロジェクト |

## よく使うコマンド

モノレポルートから実行する。

| コマンド | 用途 |
| --- | --- |
| `fvm dart run melos dashboard:run:dev` | Chrome で起動（dev / エミュレータ） |
| `fvm dart run melos dashboard:run:stg` | Chrome で起動（stg） |
| `fvm dart run melos dashboard:run:prod` | Chrome で起動（prod） |
| `fvm dart run melos dashboard:build:dev` | web 向けにビルド（dev） |
| `fvm dart run melos dashboard:build:stg` | web 向けにビルド（stg） |
| `fvm dart run melos dashboard:build:prod` | web 向けにビルド（prod） |
| `fvm dart run melos dashboard:deploy:stg` | ビルド → Firebase Hosting へデプロイ（stg） |
| `fvm dart run melos dashboard:deploy:prod` | ビルド → Firebase Hosting へデプロイ（prod） |

## デプロイ

Firebase Hosting へのデプロイは `dashboard:deploy:stg` / `dashboard:deploy:prod` スクリプトで行う。
内部でビルドと `firebase deploy --only hosting` を順に実行する。

事前に Firebase CLI でログインしていること。

```bash
firebase login
```

## スポンサーデータの本番反映

スポンサー一覧画面の「本番環境へ反映」ボタンで、STG の `sponsors` コレクションを
本番環境へワンクリックで完全ミラーできる（作成・上書きに加えて、STG に存在しない
本番側ドキュメントの**削除**も行う）。

- 実体は STG プロジェクトの Cloud Functions `syncSponsorsToProd`（[functions/README.md](../../functions/README.md) 参照）
- 実行前に dry run の結果（作成/更新/削除の件数）が確認ダイアログに表示される
- ボタンは stg / dev フレーバーでのみ表示（prod では非表示）
- dev フレーバーでは `localhost:5001` の Functions エミュレータに接続する

## スポンサー一覧の操作

スポンサー情報の**原本はスプレッドシート（GAS 連携）**。ダッシュボードで編集できるのは
**ロゴ 2 種（プライマリー/セカンダリー）と slug のみ**で、それ以外は参照用の表示。
新規作成もスプレッドシート側で行うため、作成ボタンは無い。

- ロゴ・slug のセルを**ダブルクリック**するとその場で編集できる（Enter / フォーカス移動で確定、Esc でキャンセル）。編集可能列はヘッダーに ✎ アイコンが付く
- 空文字で確定すると未設定 (null) として保存される
- 閲覧状態でもセルのテキストはドラッグで選択・コピーできる
- 上部のフィルタチップで「ロゴ未設定」「slug未設定」の入力漏れを絞り込める（複数選択は AND、空文字も未設定扱い）
- ヘッダークリックでソート（昇順 → 降順 → 解除）
- 未設定だと Web サイト表示に影響する項目（slug・プライマリーロゴ）は赤色でハイライトされる

