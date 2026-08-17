# Staff Firestore Import GAS

Google Forms の回答シートから、スタッフ画像を Firebase Storage へ、スタッフ情報を Firestore の `staffMembers` へ取り込むコンテナバインド型 Google Apps Script です。

実際の氏名、SNS アカウント、Drive ファイル ID、Firebase project ID はこのディレクトリへ保存しません。氏名対応は対象スプレッドシートの `StaffNameMap`、環境値は Apps Script の Script Properties で管理します。

## 前提

- GAS は対象スプレッドシートから「拡張機能 → Apps Script」で作成したコンテナバインド型にする
- GAS を標準 Google Cloud project に関連付ける
- 対象 project で Firestore API と Cloud Storage JSON API を有効化する
- 実行ユーザーへ次の IAM 権限を付与する
  - Firestore のドキュメント取得・作成・更新（例: `roles/datastore.user`）
  - 対象 bucket のオブジェクト取得・作成・上書き・メタデータ更新（例: `roles/storage.objectAdmin`）
- 実行ユーザーが回答内の Drive 画像を閲覧できるように共有する

Firebase のクライアント向け Security Rules と、GAS の REST 呼び出しに使う IAM は別物です。Rules で管理者になっていても IAM がなければ REST API は 403 になります。

## ソースの反映

Apps Script エディタへ各 `.gs` と `appsscript.json` を作成して貼り付けるか、`clasp` を使います。`clasp` を使う場合はこのディレクトリに次の `.clasp.json` をローカルだけで作成してください。このファイルは `.gitignore` 済みです。

`.claspignore` により、`clasp push` の対象はルート直下の `.gs` と `appsscript.json` だけです。Node.js 用の `test/` は Apps Script へ送信されません。

```json
{
  "scriptId": "対象のApps Script ID",
  "rootDir": "."
}
```

```sh
cd tool/staff/import_gas
clasp push
```

## Script Properties

Apps Script の「プロジェクトの設定 → スクリプト プロパティ」に設定します。

| キー | 値 |
| --- | --- |
| `STG_FIREBASE_PROJECT_ID` | STG の Firebase project ID |
| `STG_FIREBASE_STORAGE_BUCKET` | STG の bucket 名 |
| `PROD_FIREBASE_PROJECT_ID` | 本番の Firebase project ID |
| `PROD_FIREBASE_STORAGE_BUCKET` | 本番の bucket 名 |

秘密鍵やサービスアカウント JSON は不要です。実行ユーザーの OAuth token を使用します。

## 初期セットアップ

1. Google Forms の回答シートを開く
2. スプレッドシートを再読み込みし、「スタッフ取込 → 初期セットアップ」を実行する
3. 回答シート末尾に `name / documentId / importTarget / importStatus / importedAt / error` が追加されたことを確認する
4. 作成された `StaffNameMap` に実際の対応表を入力する

`StaffNameMap` の列は次のとおりです。

| 列 | 内容 |
| --- | --- |
| `staffKey` | 不変の小文字英数字・ハイフンキー。Firestore ID は `staff-{staffKey}` になる |
| `name` | Website に表示する名前 |
| `aliasType` | `x / bluesky / mixi2 / medium / qiita / zenn / note` |
| `alias` | アカウント名またはプロフィール URL |
| `enabled` | 使用する行だけチェック |
| `note` | 任意メモ。処理には使わない |

1 人が複数のアカウントを持つ場合、同じ `staffKey` と `name` で行を分けます。本番投入後は `staffKey` を変更せず、表示名だけを変更してください。

## 実行順序

1. 「スタッフ取込 → セルフテスト」
2. 「スタッフ取込 → STG 事前検証」
3. 回答シートの `importStatus` と `error` を確認
4. 「スタッフ取込 → STG インポート」
5. STG の Firestore、画像 URL、Website 表示を確認
6. 「スタッフ取込 → 本番インポート」で `PROD` と入力

本番インポートは、最後に全件成功した STG と現在の回答・対応表・画像メタデータの SHA-256 が一致する場合だけ実行できます。STG 後に入力やコードの変換バージョンが変わった場合は、STG からやり直します。

## 主な動作

- 未対応者はアカウント名を名前に流用せず `SKIPPED_UNMAPPED`
- 同じ `staffKey` の複数回答は最新タイムスタンプを採用。同時刻なら下の行を採用
- 採用行へシート順で `order: 1..N` を付与
- 画像は Drive のサムネイル生成で長辺 320px の正方形へ縮小し、webp を優先して取得
- 画像は `public/staff/{staffKey}/avatar` へ上書きし、既存のダウンロードトークンを再利用
- Firestore は `staffMembers/staff-{staffKey}` へ条件付き upsert
- 既存更新では `createdAt` を保持し、`updatedAt` をサーバー時刻で更新
- Drive 画像の検証失敗や非致命的な Storage アップロード失敗は行単位でスキップ
- 1 行の失敗後も他行を継続。画像アップロードの 401 / 403 など全体認証エラーは中断
- Firestore にあるが回答シートにないドキュメントは削除しない

## ステータス

- `READY`: 事前検証を通過
- `SUCCESS`: Storage と Firestore の更新成功
- `SUCCESS_WITH_WARNING`: 更新成功。ただしワンフレーズが20文字超など
- `SKIPPED_UNMAPPED`: 対応表にないため除外
- `SKIPPED_DUPLICATE`: 同一スタッフの旧回答
- `SKIPPED_IMAGE`: Drive 画像の検証または非致命的な Storage アップロードに失敗したため除外
- `ERROR_VALIDATION`: 入力・対応・URLエラー
- `ERROR_IMAGE`: Storage の認証・権限エラーなど、全体を中断する致命的な画像エラー
- `ERROR_FIRESTORE`: Firestore エラー

## ローカルテスト

Node.js 20 以上で、Apps Script に依存しない純粋関数を検証できます。

```sh
node --test test/core.test.js
```

Apps Script 上の「セルフテスト」も外部への書き込みを行いません。Sheets / Drive / Storage / Firestore の結合確認は STG で行います。

## 既知の制約

Apps Script にはネイティブの画像リサイズと webp エンコードがありません。スポンサーロゴの `convert-sponsor-logos.sh` が使う `cwebp` / `rsvg-convert` は GAS 上で実行できないため、アバターの縮小と webp 化は Drive のサムネイル生成 (`thumbnailLink` に `=s320-c-rw` を指定) に委譲しています。

`-rw` による webp 応答は Drive 側の非公開動作です。応答の Content-Type を確認し、webp 以外なら縮小済みの png / jpeg として、サムネイル生成自体が失敗した場合は原本としてアップロードします。**実際に webp が返るかは STG インポート後に Storage 上のオブジェクトの Content-Type で確認してください。**

オブジェクトパス `public/staff/{staffKey}/avatar` は拡張子を持たないため、形式が変わっても公開 URL は変わりません。

現行 Dashboard のスタッフ編集画面は `github` と `web` を入力項目として保持しません。GAS が登録した該当リンクを Dashboard で編集・保存すると失われる可能性があるため、対応までは該当レコードを GAS 経由で更新してください。
