#!/bin/bash
set -euo pipefail

# =============================================================================
# FlutterKaigi 2026 公式写真アルバム 変換スクリプト
# =============================================================================
# source/ 配下の jpg / jpeg / png を webp に変換して photos/ に出力する。
#
# トップの写真ゾーン（apps/website/lib/constants/photo_album.dart）が参照する名前
# そのままで出力するので、受け付けるファイル名は 01〜10（写真。数字は表示の優先度）
# と bg（背景）だけ。元写真のファイル名が公開 URL に出ないよう、それ以外の名前は
# 変換せずにエラーにする。同じ名前の出力は毎回上書きする。
#
# cwebp は EXIF や位置情報などのメタデータを引き継がないので、出力には含まれない。
#
# 必要なツール:
#   - cwebp (webp への変換)                 : brew install webp
#   - sips  (元画像の幅の確認。macOS 標準)
#
# 使い方:
#   # source/ に 01.jpg … 10.jpg と bg.jpg を置いてから、プロジェクトルートで実行
#   ./public-buckets/album-photos/convert-album-photos.sh
#
#   その後アップロード:
#   ./public-buckets/album-photos/upload-album-photos.sh
#
# オプション（環境変数）:
#   WEBP_QUALITY=78    写真の品質 (0-100)
#   MAX_WIDTH=960      写真の最大幅(px)。超える場合のみ縮小（拡大はしない）
#   BG_QUALITY=55      背景の品質
#   BG_MAX_WIDTH=640   背景の最大幅(px)。背景は鮮明なファイルのまま配信され（ぼかしは
#                      表示側の CSS で掛ける）、顔が判別できない小ささにしておく
#   BG_CROP="x y w h"  背景だけ、縮小の前に元画像のこの範囲(px)を切り出す
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/source"
DEST_DIR="$SCRIPT_DIR/photos"

WEBP_QUALITY="${WEBP_QUALITY:-78}"
MAX_WIDTH="${MAX_WIDTH:-960}"
BG_QUALITY="${BG_QUALITY:-55}"
BG_MAX_WIDTH="${BG_MAX_WIDTH:-640}"
BG_CROP="${BG_CROP:-}"

# --- 前提チェック ---
missing=0
if ! command -v cwebp >/dev/null 2>&1; then
  echo "ERROR: cwebp が見つかりません。'brew install webp' を実行してください。" >&2
  missing=1
fi
if ! command -v sips >/dev/null 2>&1; then
  echo "ERROR: sips が見つかりません（macOS 標準のコマンドです）。" >&2
  missing=1
fi
[ "$missing" -eq 0 ] || exit 1

if [ ! -d "$SOURCE_DIR" ]; then
  echo "ERROR: 変換元ディレクトリがありません: $SOURCE_DIR" >&2
  exit 1
fi

# --- BG_CROP の確認 ---
crop_x="" crop_y="" crop_w="" crop_h="" crop_extra=""
if [ -n "$BG_CROP" ]; then
  read -r crop_x crop_y crop_w crop_h crop_extra <<< "$BG_CROP"
  for v in "$crop_x" "$crop_y" "$crop_w" "$crop_h"; do
    case "$v" in
      '' | *[!0-9]*)
        echo "ERROR: BG_CROP は 'x y w h' の 4 つの数字で指定してください: $BG_CROP" >&2
        exit 1
        ;;
    esac
  done
  if [ -n "$crop_extra" ]; then
    echo "ERROR: BG_CROP は 'x y w h' の 4 つの数字で指定してください: $BG_CROP" >&2
    exit 1
  fi
fi

# --- 対象ファイルの収集と名前の確認 ---
# bash 3.2 (macOS 標準) でも動くよう while-read + -print0 で走査する
files=()
while IFS= read -r -d '' src; do
  files+=("$src")
done < <(find "$SOURCE_DIR" -maxdepth 1 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0 | sort -z)

if [ "${#files[@]}" -eq 0 ]; then
  echo "変換対象の画像がありません: $SOURCE_DIR"
  echo "（01.jpg … 10.jpg と bg.jpg を source/ に置いてください）"
  exit 0
fi

seen=" "
for src in "${files[@]}"; do
  file="$(basename "$src")"
  name="${file%.*}"
  case "$name" in
    0[1-9] | 10 | bg) ;;
    *)
      echo "ERROR: ファイル名は 01〜10 と bg だけ使えます: $file" >&2
      exit 1
      ;;
  esac
  case "$seen" in
    *" $name "*)
      echo "ERROR: 同じ名前の画像が複数あります（拡張子違い）: $name" >&2
      exit 1
      ;;
  esac
  seen="$seen$name "
done

mkdir -p "$DEST_DIR"

echo "変換元 : $SOURCE_DIR"
echo "出力先 : $DEST_DIR"
echo "対象   : ${#files[@]} ファイル"
echo ""

# --- 変換 ---
for src in "${files[@]}"; do
  file="$(basename "$src")"
  name="${file%.*}"
  out="$DEST_DIR/$name.webp"

  quality="$WEBP_QUALITY"
  max_width="$MAX_WIDTH"
  crop_args=()
  if [ "$name" = "bg" ]; then
    quality="$BG_QUALITY"
    max_width="$BG_MAX_WIDTH"
    if [ -n "$BG_CROP" ]; then
      crop_args=(-crop "$crop_x" "$crop_y" "$crop_w" "$crop_h")
    fi
  fi

  # 縮小するかは、切り出す場合は切り出し後の幅で決める（cwebp は切り出してから縮小する）。
  width="$(sips -g pixelWidth "$src" 2>/dev/null | awk '/pixelWidth:/{print $2}')"
  if [ "${#crop_args[@]}" -gt 0 ]; then
    width="$crop_w"
  fi
  resize_args=()
  if [ -n "${width:-}" ] && [ "$width" -gt "$max_width" ]; then
    resize_args=(-resize "$max_width" 0)
  fi

  cwebp -quiet -q "$quality" -m 6 \
    ${crop_args[@]+"${crop_args[@]}"} ${resize_args[@]+"${resize_args[@]}"} \
    "$src" -o "$out"

  printf '  ✓ %s  →  %s.webp (%s bytes)\n' "$file" "$name" "$(wc -c < "$out" | tr -d ' ')"
done

echo ""
echo "完了: ${#files[@]} 件を変換しました（出力: $DEST_DIR）"
echo ""
echo "次のステップ: アップロード"
echo "  ./public-buckets/album-photos/upload-album-photos.sh"
