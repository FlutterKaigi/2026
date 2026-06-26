# FlutterKaigi 2026 Public Buckets

R2 公開バケット `2026-public-production` への公開ファイル（スポンサーロゴ等）アップロードを管理します。

バケットとカスタムドメインは Terraform (`terraform/cloudflare`) で構築済みです。
**ファイルの投入は rclone** で行います。

## ディレクトリ構成

```
public-buckets/
└── sponsor-logos/
    ├── logos/                     # ★ ここにロゴ画像を置く（画像本体は Git 管理しない）
    │   └── .gitignore             # 画像をコミット対象外にする設定
    └── upload-sponsor-logos.sh    # アップロードスクリプト
```

> **ロゴ画像本体は Git 管理しません。** `logos/` 配下は `.gitignore` で除外されているため、
> 画像を置いてもコミットされません（各自ローカルに配置 → rclone でアップロード）。

## ロゴ画像の置き方・形式

- 画像を `public-buckets/sponsor-logos/logos/` 直下に置く（**コミットされない**）。
- 対応形式: **webp / png / jpg / jpeg / svg**（推奨は webp または svg）。
- **ファイル名がそのまま公開URLのキー**になります。
  - 例: `logos/example-corp.webp` → `https://2026-bucket.flutterkaigi.jp/sponsors/example-corp.webp`
- ファイル名は URL に使える文字（半角英数・ハイフン）にしておくと安全です。日本語やスペースは避ける。
- サブディレクトリを作ると、その階層もそのまま反映されます（例: `logos/platinum/foo.webp` → `.../sponsors/platinum/foo.webp`）。

## rclone のセットアップ

### 1. rclone をインストール

[公式手順](https://rclone.org/install/) もしくは `mise use rclone@latest` 等。

### 2. R2 用 API トークンを発行

Cloudflare ダッシュボード → R2 → API トークンで、
`2026-public-production` バケットに対する **Object Read & Write** 権限のトークンを発行し、
**Access Key ID** と **Secret Access Key** を控える。

> Terraform state 用に作った R2 トークンとは別に、公開バケット用を発行するのが安全（権限を最小化できる）。

### 3. リモート "r2" を設定

`~/.config/rclone/rclone.conf`（Windows は `%APPDATA%\rclone\rclone.conf`）に追記:

```ini
[r2]
type = s3
provider = Cloudflare
access_key_id = YOUR_ACCESS_KEY_ID
secret_access_key = YOUR_SECRET_ACCESS_KEY
region = auto
endpoint = https://cdd8f59359fe226645e7b541cdc53b57.r2.cloudflarestorage.com
acl = private
```

> `acl = private` のままでOK。公開はカスタムドメイン経由で行われるため、オブジェクトACLは関係しません。

### 4. 動作確認

```bash
rclone listremotes
rclone ls r2:2026-public-production
```

## アップロード

```bash
# プロジェクトルートから
./public-buckets/sponsor-logos/upload-sponsor-logos.sh
```

`logos/` 配下の画像が `r2:2026-public-production/sponsors/` にアップロードされます。
アップロード後、数分で `https://2026-bucket.flutterkaigi.jp/sponsors/<ファイル名>` から取得可能です。
