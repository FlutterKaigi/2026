# 公式写真アルバム 変換・アップロードツール

トップページの「写真ゾーン」（`PhotoAlbumHero`）に載せる写真 10 枚と背景 1 枚を webp に変換し、
R2 公開バケット `2026-public-production` の `album/` プレフィックスにアップロードするツールです。
バケット／カスタムドメインは `terraform/cloudflare` で構築済みです。

写真は**このリポジトリに入れません**。Git の履歴は後から消せませんが、R2 のファイルなら、
撮影チームから掲載を取り下げたい連絡があったときに消せるためです
（消し方は、下の「写真の差し替え・取り下げ」）。

## 全体の流れ

```
source/ に元写真(jpg/png)を 01〜10 と bg の名前で置く
        │
        ▼  convert-album-photos.sh
photos/ に 01〜10.webp と bg.webp を出力
        │
        ▼  upload-album-photos.sh
R2 公開バケット → https://2026-bucket.flutterkaigi.jp/album/<名前>.webp
        │
        ▼  サイトが絶対 URL で参照
apps/website/lib/constants/photo_album.dart
```

## ファイル名

サイトのコードが次の名前で参照しているので、名前は固定です（個人スポンサー写真のような UUID 命名にはしません）。

| 名前 | 内容 |
| --- | --- |
| `01`〜`10` | 散らして並べる写真。数字は表示の優先度で、01 が主役の大きな枠。01〜05 がスマホに、01〜07 がタブレットにも出る |
| `bg` | 全面に敷く、ぼかした背景 |

`convert-album-photos.sh` は、この名前以外のファイルをエラーにします（元写真のファイル名が公開 URL に出ないようにするため）。

## 写真を選ぶときの決まり

- **撮影チーム（公式写真）の確認が済んだものだけ**を使う。顔が大きく写る写真は特に。
- 参加者が写る写真は、掲載を望まない旨の連絡を受けていないかをあわせて確認する。
- PC の画面が読める写真は避ける。
- 元写真は撮影チームの公式アルバムから取る。ライセンスは CC BY-NC 4.0（クレジット: FlutterKaigi）。
  アルバムの共有リンクは公開前の情報なので、このリポジトリには書かない。

## ディレクトリ

```
album-photos/
├── source/                          # ★ 変換元の写真(jpg/png)を置く（本体は Git 管理外）
│   └── .gitignore
├── photos/                          # 変換後の 01〜10.webp / bg.webp 出力先（本体は Git 管理外）
│   └── .gitignore
├── convert-album-photos.sh          # 変換スクリプト (jpg/png → webp)
├── upload-album-photos.sh           # アップロードスクリプト
└── README.md                        # このファイル
```

## 1. 変換する

### 準備（初回のみ）

```bash
brew install webp
```

- `webp` … `cwebp`（jpg/png → webp）
- 元画像の幅の確認には、macOS 標準の `sips` を使います。

### 実行

`source/` 直下に、元写真を `01.jpg`〜`10.jpg` と `bg.jpg` の名前で置きます（png も可）。
**本体は Git 管理されません**（`source/.gitignore` で除外）。

```bash
# プロジェクトルートから実行
./public-buckets/album-photos/convert-album-photos.sh
```

`source/` にあるファイルだけを `photos/<名前>.webp` に変換します（`photos/` にある他のファイルには触りません）。
同じ名前の出力は上書きされます。メタデータ（EXIF や位置情報など）は出力に含まれません。

オプション（環境変数で指定）:

| 変数 | 既定 | 説明 |
| --- | --- | --- |
| `WEBP_QUALITY` | `78` | 写真の品質 (0-100) |
| `MAX_WIDTH` | `960` | 写真の最大幅(px)。超える場合のみ縮小（拡大はしない）。1 枚 30〜60KB 前後になる |
| `BG_QUALITY` | `55` | 背景の品質 |
| `BG_MAX_WIDTH` | `640` | 背景の最大幅(px)。背景は鮮明なファイルのまま配信され（ぼかしは表示側の CSS で掛けます）、顔が判別できない小ささにしておく |
| `BG_CROP` | なし | `"x y w h"`（元画像のピクセル）。背景だけ、縮小の前にこの範囲を切り出す |

現在の背景は、2 日目の全員集合の写真（8189×5462px）から、壁を除いて人の写る下半分だけを切り出したものです。
写真をそのまま拡大すると壁の色で平坦になるので、人の写る範囲だけを切り出しています:

```bash
BG_CROP="819 2512 6551 2950" ./public-buckets/album-photos/convert-album-photos.sh
```

## 2. アップロードする

事前に rclone のセットアップが必要です（手順は [`../README.md`](../README.md) を参照）。

```bash
# プロジェクトルートから実行
./public-buckets/album-photos/upload-album-photos.sh

# どのファイルが送られるかだけ確認する（何もアップロードしない）
DRY_RUN=1 ./public-buckets/album-photos/upload-album-photos.sh
```

- `photos/` 配下の `01〜10.webp` と `bg.webp` が `r2:2026-public-production/album/` にアップロードされます（それ以外のファイルは送りません）。
- `Cache-Control: public, max-age=3600`（1 時間）が付与されます。他のツールの 1 日より短いのは、取り下げたときに古い写真が長く残らないようにするためです。
- アップロード後、数分で `https://2026-bucket.flutterkaigi.jp/album/<名前>.webp` から取得可能です。

## 写真の差し替え・取り下げ

- **差し替え**: 同じ名前で変換してアップロードし直すと、サイトのコードを変えずに入れ替わります（キャッシュが最大 1 時間残ります）。
  写真の中身が変わるときは、`apps/website/lib/constants/photo_album.dart` の `alt` と `objectPosition`（縦長に切り抜くときの位置）も見直してください。
- **取り下げ**（掲載を望まない連絡を受けたときなど）:

  ```bash
  rclone deletefile r2:2026-public-production/album/<名前>.webp
  ```

  消した写真は、サイト側で自動的にグラデーションのタイルに戻ります（コードの変更は不要）。
  CDN とブラウザのキャッシュには最大 1 時間残るので、すぐに消したいときは、Cloudflare ダッシュボードでその URL のキャッシュをパージしてください。
  サイトのコードからも外すときは、`photo_album.dart` の該当エントリを削除します。

## アップロード済みファイルの確認

```bash
rclone ls r2:2026-public-production/album/
```
