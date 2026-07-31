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

WebでGoogle / AppleのEmulator擬似IdPまで動作確認する場合は、Firebase Web SDKのOAuth helperが有効な`apiKey`と`authDomain`を必要とするため、StubではなくFlutterFire CLIで生成された`firebase_options.dart`を使用してください。devフレーバーはそのSDK設定で初期化した後、Auth / Firestore / Functionsの接続先をEmulatorへ切り替えるため、認証データが実Projectへ書き込まれることはありません。

stg/prodの配布Workflowは`apps/app`でFlutterFire CLIを実行し、Git管理外の`firebase_options.dart`とNative設定ファイルをFirebase Projectからビルド時に生成します。Firebase OptionsをRepositoryやGitHub Secretには保存しません。ローカルでstg/prodへ接続する場合のコマンドとCI認証設定は[App delivery setup](../../.github/APP_DELIVERY.md#firebase-sdk-settings)を参照してください。

## 認証

Google / Apple / メールアドレス+パスワードのサインインに対応しています。リポジトリ実装は`packages/data`の`AuthRepository`、UIはアカウントタブ(`/account`)です。アカウントタブからはサインアウトと、再認証をともなうアカウント削除(App Store Review Guideline 5.1.1(v)対応)ができます。Appleユーザーの削除ではAppleのトークンを失効させてから削除します(iOS / AndroidはFirebase SDK、WebはCloud Functionsの`revokeAppleToken`経由。Emulator接続時は失効をスキップ)。

devフレーバーはAuth Emulator(port 9099)へ自動接続します。リポジトリルートでEmulatorを起動してからアプリを実行してください。

```bash
fvm dart run melos run firebase:start
```

Emulator接続時は次のように動作します。

- Google: Emulatorの擬似IdP画面が開き、任意のダミーアカウントでサインインできます(実プロバイダの認証情報は不要)。
- Apple: Android / WebはGoogleと同じ擬似IdP画面です。iOSはネイティブのSign in with Appleが開くため、シミュレータ/実機にApple IDでサインインしている必要があります。
- メール+パスワード: アカウント作成・サインイン・パスワード再設定を利用できます。再設定メールのリンクはEmulatorを起動したターミナルのログに出力されます。
- 登録されたユーザーはEmulator UI(`http://localhost:4000/auth`)で確認できます。

iOSのGoogleサインインはブラウザ経由(`signInWithProvider`)で行われ、`Info.plist`のコールバックスキームでアプリへ戻ります。dev用スキームは登録済みで、本番の`REVERSED_CLIENT_ID`は配布Workflowがアーカイブ前に挿入・検証します。iOSのAppleサインインはSign in with Apple Capabilityを使うため、`Runner.entitlements`に設定済みです。App ID側のCapability有効化とProvisioning Profileの更新はApple Developer Portal(自動署名では配布Workflowの`-allowProvisioningUpdates`)で行われます。

## 配布

GitHub Actionsによる配布先、Repository Variables／Secretsの設定は[App delivery setup](../../.github/APP_DELIVERY.md)を参照してください。
