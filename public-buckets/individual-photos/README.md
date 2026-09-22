# 個人スポンサー写真 変換・アップロードツール

個人スポンサーの写真を webp に変換し、R2 公開バケット `2026-public-production` にアップロードするツールです。
バケット／カスタムドメインは `terraform/cloudflare` で構築済みです。

企業スポンサーロゴ用の [`sponsor-logos/`](../sponsor-logos/) と同じ仕組みですが、R2 上のプレフィックスを
`individual/` に分け、個人スポンサーを独立して管理できるようにした姉妹ツールです。

## 全体の流れ

```
source/ に元画像(svg/png/jpg)を置く
        │
        ▼  convert-individual-photos.sh
photos/ に <UUID>.webp を出力（対応表は photos-manifest.tsv）
        │
        ▼  upload-individual-photos.sh
R2 公開バケット → https://2026-bucket.flutterkaigi.jp/individual/<UUID>.webp
```

ファイル名は UUID にするため、公開URLから個人スポンサー名が推測できません。
**どの UUID が誰の写真か**は変換時に生成される `photos-manifest.tsv` で確認します。

## ディレクトリ

```
individual-photos/
├── source/                          # ★ 変換元の写真(svg/png/jpg)を置く（本体は Git 管理外）
│   └── .gitignore
├── photos/                          # 変換後の <UUID>.webp 出力先（本体は Git 管理外）
│   └── .gitignore
├── photos-manifest.tsv              # 変換元→UUID→公開URL の対応表（Git 管理外・自動生成）
├── convert-individual-photos.sh     # 変換スクリプト (svg/png/jpg → webp, UUID 命名)
├── upload-individual-photos.sh      # アップロードスクリプト
└── README.md                        # このファイル
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
- 元画像のファイル名は何でも可（出力は UUID に置き換わるため）。

```bash
# プロジェクトルートから実行
./public-buckets/individual-photos/convert-individual-photos.sh
```

実行すると `photos/` に `<UUID>.webp` が出力され、`photos-manifest.tsv` に
`変換元ファイル → UUID.webp → 公開URL` が追記されます。

**増分変換がデフォルト**です。manifest に未記録の source だけが変換されるため、
あとから `source/` に写真を足して再実行するだけで、**新規分だけ**変換・追記されます
（既存分は再変換されず UUID も維持）。全部やり直したいときは `CLEAN=1`。

オプション（環境変数で指定）:

| 変数 | 既定 | 説明 |
| --- | --- | --- |
| `WEBP_LOSSLESS` | `0` | ロッシー変換（既定）。`1` でロスレス。顔写真は透過が不要で、ロスレスにすると企業ロゴ用と違いファイルサイズが増えるだけなので既定はロッシー |
| `WEBP_QUALITY` | `90` | ロッシー時の品質 (0-100) |
| `MAX_WIDTH` | `320` | 出力の最大幅(px)。svg はこの幅でラスタライズ、png/jpg はこの幅を超える場合のみ縮小（拡大はしない）。ホームの円形アバター表示(96px、Retinaで最大288px相当)と、OGPカードへの合成(最大268px相当)の両方を余裕を持ってカバーできるサイズ |
| `CLEAN` | `0` | `1` で全件リビルド（`photos/` の `*.webp` と manifest を削除し、全 source を新しい UUID で変換し直す。増分スキップは無効化） |

## 3. アップロードする

事前に rclone のセットアップが必要です（手順は [`../README.md`](../README.md) を参照）。

```bash
# プロジェクトルートから実行
./public-buckets/individual-photos/upload-individual-photos.sh
```

- `photos/` 配下の画像が `r2:2026-public-production/individual/` にアップロードされます。
- `Cache-Control: public, max-age=86400` が付与されます。
- アップロード後、数分で `https://2026-bucket.flutterkaigi.jp/individual/<ファイル名>` から取得可能です。

## アップロード済みファイルの確認

```bash
rclone ls r2:2026-public-production/individual/
```
