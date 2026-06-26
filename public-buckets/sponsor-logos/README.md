# スポンサーロゴ アップロードツール

スポンサーロゴを R2 公開バケット `2026-public-production` にアップロードするツールです。
バケット／カスタムドメインは `terraform/cloudflare` で構築済みです。

## ディレクトリ

```
sponsor-logos/
├── logos/                     # ★ ここにロゴ画像を置く（画像本体は Git 管理外）
│   └── .gitignore             # 画像をコミット対象外にする設定
├── upload-sponsor-logos.sh    # アップロードスクリプト
└── README.md                  # このファイル
```

## ロゴ画像の置き方・形式

- 画像を `logos/` 直下に置く。**画像本体は Git 管理されません**（`logos/.gitignore` で除外。各自ローカルに配置 → rclone でアップロード）。
- 対応形式: **webp / png / jpg / jpeg / svg**（推奨は webp または svg）。
- **ファイル名がそのまま公開URLのキー**になります。
  - 例: `logos/example-corp.webp` → `https://2026-bucket.flutterkaigi.jp/sponsors/example-corp.webp`
- ファイル名は URL に使える文字（半角英数・ハイフン）にする。日本語やスペースは避ける。
- サブディレクトリも階層ごと反映されます。
  - 例: `logos/platinum/foo.webp` → `https://2026-bucket.flutterkaigi.jp/sponsors/platinum/foo.webp`

## 使い方

事前に rclone のセットアップが必要です（手順は [`../README.md`](../README.md) を参照）。

```bash
# プロジェクトルートから実行
./public-buckets/sponsor-logos/upload-sponsor-logos.sh
```

- `logos/` 配下の画像が `r2:2026-public-production/sponsors/` にアップロードされます。
- `Cache-Control: public, max-age=86400` が付与されます。
- アップロード後、数分で `https://2026-bucket.flutterkaigi.jp/sponsors/<ファイル名>` から取得可能です。

## アップロード済みファイルの確認

```bash
rclone ls r2:2026-public-production/sponsors/
```
