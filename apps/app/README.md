# FlutterKaigi 2026 App

FlutterKaigi 2026のiOS、Android、Web公式アプリです。

## 環境

外部Contributorを含むローカル開発では、`dev`フレーバーとFirebase Emulator Suiteを使用します。stg／prodのFirebase Projectや配布サービスへのアクセス権限は不要です。以下はWeb（Chrome）での起動手順です。

| Flavor | 設定ファイル             | 接続先                    |
| ------ | ------------------------ | ------------------------- |
| `dev`  | `environments/.env.dev`  | Firebase Emulator Suite   |
| `stg`  | `environments/.env.stg`  | `flutterkaigi-2026-stg`   |
| `prod` | `environments/.env.prod` | `flutterkaigi-2026-283db` |

Repositoryルートで、実値を含まないStubをGit管理外の生成先へコピーし、Emulatorを起動します。

```bash
cp apps/app/lib/firebase_options.stub.dart apps/app/lib/firebase_options.dart
fvm dart run melos run firebase:start
```

別のTerminalで次を実行します。

```bash
cd apps/app
fvm flutter run \
  -d chrome \
  --dart-define-from-file=environments/.env.dev
```

StubでWebの起動、analyze、test、メールアドレス認証の動作確認ができます。iOS／Androidの実行にはPlatformに対応するFirebase Optionsが必要ですが、接続先には引き続き`dev`フレーバーとEmulatorを使用します。FlutterKaigiのstg／prod設定は使用しません。

WebでGoogleのEmulator擬似IdPまで確認する場合だけ、Firebase Web SDKのOAuth helperが有効な`apiKey`と`authDomain`を必要とします。この確認は、メンテナーがFlutterFire CLIでローカル生成した`firebase_options.dart`を使用して行います。生成された設定値はRepository、Issue、PRへ記載しません。devフレーバーでは、アプリ起動時にAuth / FirestoreをEmulatorへ接続します。

stg/prodの設定生成と配布はメンテナー向けWorkflowで行います。詳細は[App delivery setup](../../.github/APP_DELIVERY.md#firebase-sdk-settings)を参照してください。

## 認証

Google / メールアドレス+パスワードのサインインに対応し、本番版のiOSだけAppleサインインも表示します。リポジトリ実装は`packages/data`の`AuthRepository`、UIはアカウントタブ(`/account`)です。アカウントタブからはサインアウトと、再認証をともなうアカウント削除(App Store Review Guideline 5.1.1(v)対応)ができます。Appleユーザーの削除ではiOSのFirebase SDKでAppleのトークンを失効させてから削除します(Emulator接続時は失効をスキップ)。

devフレーバーはAuth Emulator(port 9099)へ自動接続します。

Emulator接続時は次のように動作します。

- Google: Webでは、有効なOAuth helper設定を使用するメンテナー確認で、Emulatorの擬似IdP画面から任意のダミーアカウントでサインインできます(実プロバイダの認証情報は不要)。
- Apple: dev / stgでは表示しません。本番版のiOSではネイティブのSign in with Appleを使用します。
- メール+パスワード: アカウント作成・サインイン・パスワード再設定を利用できます。再設定メールのリンクはEmulatorを起動したターミナルのログに出力されます。
- 登録されたユーザーはEmulator UI(`http://localhost:4000/auth`)で確認できます。

iOSのGoogleサインインはブラウザ経由(`signInWithProvider`)で行われ、`Info.plist`のコールバックスキームでアプリへ戻ります。本番版iOSのAppleサインインはSign in with Apple Capabilityを使用します。配布に必要なコールバックスキーム、Entitlements、Provisioning Profileはメンテナー向けWorkflowとApple Developer Portalで管理します。dev / stgのApp IDにSign in with Appleを有効化する必要はありません。Web OAuthを提供しないため、AppleのServices IDも使用しません。

## プロフィール

サインイン後、アカウントタブからプロフィール(`/account/profile`)を作成・編集できます。プロフィールはFirestoreの`users/{uid}`に保存され、サインイン済みの他の参加者から参照できます(プロフィール交換ミッション用)。項目は次のとおりです。

- 表示名(必須、30文字まで)
- 出身国・地域(必須、ISO 3166-1 alpha-2コードで保存)。`packages/data`の`countries`(Unicode CLDR由来、`fvm dart run melos countries:generate`で再生成)から地域別・英語名順で選択します。国旗は`country_flags`パッケージ(MIT、flag-iconsのSVG)で表示します(絵文字の国旗はiOSのFlutterで地域指示子が結合されず豆腐になるため不採用)
- SNSリンク(任意、10件まで。`SnsLink.type`はダッシュボードのスタッフ編集と同じキー)
- 自己紹介(任意、300文字まで)

プロフィール画像はサインインプロバイダの`photoURL`を初回作成時に保存し、アプリ内でのアップロードには未対応です。アカウント削除では、再認証後・ユーザー削除前に`users/{uid}`も削除します。参加者種別と初参加フラグはネームプレートで把握する運用のため、プロフィールには持ちません。

## 配布

GitHub Actionsによる配布先、Repository Variables／Secretsの設定は[App delivery setup](../../.github/APP_DELIVERY.md)を参照してください。
