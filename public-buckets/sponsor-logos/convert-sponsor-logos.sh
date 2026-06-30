#!/bin/bash
set -euo pipefail

# =============================================================================
# FlutterKaigi 2026 スポンサーロゴ 変換スクリプト
# =============================================================================
# source/ 配下の svg / png / jpg / jpeg を webp に変換し、
# ファイル名を UUID（ランダムで一意なキー）にして logos/ に出力する。
#
# 出力された logos/ 配下の webp は upload-sponsor-logos.sh で
# R2 公開バケットにアップロードできる。
#
# 変換元 → 出力 → 公開URL の対応は logos-manifest.tsv に追記される。
# （UUID ファイル名だけではどのスポンサーのロゴか分からないため）
#
# 必要なツール:
#   - cwebp        (png/jpg → webp)        : brew install webp
#   - rsvg-convert (svg のラスタライズ用)   : brew install librsvg
#   - uuidgen      (macOS 標準)
#
# 使い方:
#   # source/ に元画像を置いてから、プロジェクトルートで実行
#   ./public-buckets/sponsor-logos/convert-sponsor-logos.sh
#
#   その後アップロード:
#   ./public-buckets/sponsor-logos/upload-sponsor-logos.sh
#
# オプション（環境変数）:
#   WEBP_LOSSLESS=1   ロスレス変換（既定。ロゴの輪郭・透過を保持）
#   WEBP_LOSSLESS=0   ロッシー変換（WEBP_QUALITY を使用）
#   WEBP_QUALITY=90   ロッシー時の品質 (0-100)
#   MAX_WIDTH=1024    出力の最大幅(px)。svg はこの幅でラスタライズ、
#                     png/jpg はこの幅を超える場合のみ縮小（拡大はしない）
#   CLEAN=1           実行前に logos/ の *.webp を削除してから変換する
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/source"
DEST_DIR="$SCRIPT_DIR/logos"
MANIFEST="$SCRIPT_DIR/logos-manifest.tsv"
PUBLIC_BASE="https://2026-bucket.flutterkaigi.jp/sponsors"

WEBP_LOSSLESS="${WEBP_LOSSLESS:-1}"
WEBP_QUALITY="${WEBP_QUALITY:-90}"
MAX_WIDTH="${MAX_WIDTH:-1024}"
CLEAN="${CLEAN:-0}"

# --- 前提チェック ---
missing=0
if ! command -v cwebp >/dev/null 2>&1; then
  echo "ERROR: cwebp が見つかりません。'brew install webp' を実行してください。" >&2
  missing=1
fi
if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "ERROR: rsvg-convert が見つかりません。'brew install librsvg' を実行してください。" >&2
  missing=1
fi
if ! command -v uuidgen >/dev/null 2>&1; then
  echo "ERROR: uuidgen が見つかりません。" >&2
  missing=1
fi
[ "$missing" -eq 0 ] || exit 1

if [ ! -d "$SOURCE_DIR" ]; then
  echo "ERROR: 変換元ディレクトリがありません: $SOURCE_DIR" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

if [ "$CLEAN" = "1" ]; then
  echo "CLEAN=1: logos/ 配下の *.webp を削除します"
  find "$DEST_DIR" -type f -iname '*.webp' -delete
fi

# --- 対象ファイル数の確認 ---
# サブディレクトリ（platinum/ などのティア分け）も維持する
count=$(find "$SOURCE_DIR" -type f \
  \( -iname '*.svg' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | wc -l | tr -d ' ')

if [ "$count" -eq 0 ]; then
  echo "変換対象の画像がありません: $SOURCE_DIR"
  echo "（svg / png / jpg / jpeg を source/ に置いてください）"
  exit 0
fi

# --- マニフェスト初期化（無ければヘッダを書く）---
if [ ! -f "$MANIFEST" ]; then
  printf 'timestamp\tvariant\tsource\twebp\turl\n' > "$MANIFEST"
fi

if [ "$WEBP_LOSSLESS" = "1" ]; then
  echo "変換モード   : ロスレス (lossless)"
else
  echo "変換モード   : ロッシー (quality=${WEBP_QUALITY})"
fi
echo "変換元       : $SOURCE_DIR"
echo "出力先       : $DEST_DIR"
echo "マニフェスト : $MANIFEST"
echo "対象ファイル : ${count}"
echo ""

now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
converted=0

# bash 3.2 (macOS 標準) でも動くよう while-read + -print0 で走査する
while IFS= read -r -d '' src; do
  # source/ からの相対パス（サブディレクトリを維持するため）
  rel="${src#"$SOURCE_DIR"/}"
  subdir="$(dirname "$rel")"
  [ "$subdir" = "." ] && subdir=""

  uuid="$(uuidgen | tr 'A-Z' 'a-z')"
  if [ -n "$subdir" ]; then
    out_rel="$subdir/$uuid.webp"
    mkdir -p "$DEST_DIR/$subdir"
  else
    out_rel="$uuid.webp"
  fi
  out="$DEST_DIR/$out_rel"

  ext="$(printf '%s' "${src##*.}" | tr 'A-Z' 'a-z')"

  if [ "$ext" = "svg" ]; then
    # svg → 一時 png(透過維持) → webp。MAX_WIDTH でラスタライズ
    tmp_png="$(mktemp -t sponsorlogo).png"
    rsvg-convert -w "$MAX_WIDTH" "$src" -o "$tmp_png"
    if [ "$WEBP_LOSSLESS" = "1" ]; then
      cwebp -quiet -lossless "$tmp_png" -o "$out"
    else
      cwebp -quiet -q "$WEBP_QUALITY" "$tmp_png" -o "$out"
    fi
    rm -f "$tmp_png"
  else
    # png / jpg / jpeg → webp。MAX_WIDTH を超える場合のみ縮小（拡大はしない）
    srcw="$(sips -g pixelWidth "$src" 2>/dev/null | awk '/pixelWidth:/{print $2}')"
    if [ -n "${srcw:-}" ] && [ "$srcw" -gt "$MAX_WIDTH" ]; then
      rflag="-resize $MAX_WIDTH 0"
    else
      rflag=""
    fi
    if [ "$WEBP_LOSSLESS" = "1" ]; then
      cwebp -quiet -lossless $rflag "$src" -o "$out"
    else
      cwebp -quiet -q "$WEBP_QUALITY" $rflag "$src" -o "$out"
    fi
  fi

  # バリアント判定: ファイル名(拡張子除く)末尾が _Secondary なら secondary、他は primary
  base_noext="$(basename "$rel")"; base_noext="${base_noext%.*}"
  case "$(printf '%s' "$base_noext" | tr 'A-Z' 'a-z')" in
    *_secondary) variant="secondary" ;;
    *)           variant="primary" ;;
  esac

  printf '%s\t%s\t%s\t%s\t%s\n' "$now" "$variant" "$rel" "$out_rel" "$PUBLIC_BASE/$out_rel" >> "$MANIFEST"
  echo "  ✓ [$variant] $rel  →  $out_rel"
  converted=$((converted + 1))
done < <(find "$SOURCE_DIR" -type f \
  \( -iname '*.svg' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print0 | sort -z)

echo ""
echo "完了: ${converted} 件を webp に変換しました"
echo ""
echo "対応表 (source → 公開URL):"
echo "  $MANIFEST"
echo ""
echo "次のステップ: アップロード"
echo "  ./public-buckets/sponsor-logos/upload-sponsor-logos.sh"
