# FlutterKaigi 2026 App

FlutterKaigi 2026のiOS、Android、Web公式アプリです。

## 環境

| Flavor | 設定ファイル             | 接続先                    |
| ------ | ------------------------ | ------------------------- |
| `dev`  | `environments/.env.dev`  | Firebase Emulator Suite   |
| `stg`  | `environments/.env.stg`  | `flutterkaigi-2026-stg`   |
| `prod` | `environments/.env.prod` | `flutterkaigi-2026-283db` |

例:

```bash
fvm flutter run \
  --dart-define-from-file=environments/.env.dev
```

devでanalyze/testする場合は、実値を含まないStubをGit管理外の生成先へコピーします。

```bash
cp lib/firebase_options.stub.dart lib/firebase_options.dart
```

stg/prodの配布Workflowは`apps/app`でFlutterFire CLIを実行し、Git管理外の`firebase_options.dart`とNative設定ファイルをFirebase Projectからビルド時に生成します。Firebase OptionsをRepositoryやGitHub Secretには保存しません。ローカルでstg/prodへ接続する場合のコマンドとCI認証設定は[App delivery setup](../../.github/APP_DELIVERY.md#firebase-sdk-settings)を参照してください。

## 配布

GitHub Actionsによる配布先、Repository Variables／Secretsの設定は[App delivery setup](../../.github/APP_DELIVERY.md)を参照してください。
