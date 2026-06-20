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

