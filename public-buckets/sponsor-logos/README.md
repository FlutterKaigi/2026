# スポンサーロゴ 変換・アップロードツール

スポンサーロゴを webp に変換し、R2 公開バケット `2026-public-production` にアップロードするツールです。
バケット／カスタムドメインは `terraform/cloudflare` で構築済みです。

## 全体の流れ

```
source/ に元画像(svg/png/jpg)を置く
        │
        ▼  convert-sponsor-logos.sh
logos/ に <UUID>.webp を出力（対応表は logos-manifest.tsv）
        │
        ▼  upload-sponsor-logos.sh
R2 公開バケット → https://2026-bucket.flutterkaigi.jp/sponsors/<UUID>.webp
```

ファイル名は UUID にするため、公開URLからスポンサー名が推測できません。
**どの UUID がどのスポンサーか**は変換時に生成される `logos-manifest.tsv` で確認します。

## ディレクトリ

```
sponsor-logos/
├── source/                    # ★ 変換元の画像(svg/png/jpg)を置く（本体は Git 管理外）
│   └── .gitignore
├── logos/                     # 変換後の <UUID>.webp 出力先（本体は Git 管理外）
│   └── .gitignore
├── logos-manifest.tsv         # 変換元→UUID→公開URL の対応表（Git 管理外・自動生成）
├── convert-sponsor-logos.sh   # 変換スクリプト (svg/png/jpg → webp, UUID 命名)
├── upload-sponsor-logos.sh    # アップロードスクリプト
└── README.md                  # このファイル
```

## 1. 変換ツールの準備（初回のみ）

```bash
brew install webp librsvg
```

- `webp` … `cwebp`（png/jpg → webp）
- `librsvg` … `rsvg-convert`（svg のラスタライズ）

## 2. 元画像を置いて変換する

- 変換元を `source/` 直下に置く。**本体は Git 管理されません**（`source/.gitignore` で除外）。
- 対応形式: **svg / png / jpg / jpeg**。
- サブディレクトリ（ティア分けなど）は階層ごと維持されます。
  - 例: `source/platinum/foo.svg` → `logos/platinum/<UUID>.webp`
- 元画像のファイル名は何でも可（出力は UUID に置き換わるため）。
- **Primary / Secondary** の区別: ファイル名（拡張子を除く）末尾が `_Secondary`
  のものは manifest の `variant` 列が `secondary` になります。それ以外は `primary`。
  - 例: `D2026-021_株式会社アンドパッド.svg` → primary（横型など主ロゴ）
  - 例: `D2026-021_株式会社アンドパッド_Secondary.svg` → secondary（縦型など副ロゴ）

```bash
# プロジェクトルートから実行
./public-buckets/sponsor-logos/convert-sponsor-logos.sh
```

実行すると `logos/` に `<UUID>.webp` が出力され、`logos-manifest.tsv` に
`変換元ファイル → UUID.webp → 公開URL` が追記されます。

**増分変換がデフォルト**です。manifest に未記録の source だけが変換されるため、
あとから `source/` にロゴを足して再実行するだけで、**新規分だけ**変換・追記されます
（既存分は再変換されず UUID も維持）。全部やり直したいときは `CLEAN=1`。

オプション（環境変数で指定）:

| 変数 | 既定 | 説明 |
| --- | --- | --- |
| `WEBP_LOSSLESS` | `1` | ロスレス変換（ロゴの輪郭・透過を保持）。`0` でロッシー |
| `WEBP_QUALITY` | `90` | ロッシー時の品質 (0-100) |
| `MAX_WIDTH` | `1024` | 出力の最大幅(px)。svg はこの幅でラスタライズ、png/jpg はこの幅を超える場合のみ縮小（拡大はしない）。高さはアスペクト比維持 |
| `CLEAN` | `0` | `1` で全件リビルド（`logos/` の `*.webp` と manifest を削除し、全 source を新しい UUID で変換し直す。増分スキップは無効化） |

## 3. アップロードする

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
