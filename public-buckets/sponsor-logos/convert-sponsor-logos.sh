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
# 既定は「増分変換」: manifest に未記録の source だけを変換する。
# そのため source/ に新しい画像を足して再実行するだけで、新規分だけ
# 変換・追記される（既存分は再変換されず UUID も維持される）。
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
#   CLEAN=1           全件リビルド。logos/ の *.webp と manifest を削除し、
#                     全 source を新しい UUID で変換し直す（増分スキップを無効化）
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
  echo "CLEAN=1: logos/ の *.webp と manifest を削除し、全件リビルドします"
  find "$DEST_DIR" -type f -iname '*.webp' -delete
  rm -f "$MANIFEST"
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

# macOS は濁点/半濁点付きのファイル名を NFD(分解形) で保存することがあり、
# git や manifest 側の NFC(合成形) と完全一致しなくなる（例: アンドパッド の ド/パ）。
# その場合に増分スキップが効かず再変換(UUID重複)になるため、比較・記録は常に
# NFC に正規化して揃える。iconv の UTF-8-MAC は分解形を表す入力エンコーディングで、
# UTF-8 へ変換すると合成形(NFC)になる（NFC 入力はそのまま保持される＝冪等）。
to_nfc() {
  printf '%s' "$1" | iconv -f UTF-8-MAC -t UTF-8 2>/dev/null || printf '%s' "$1"
}

# 既存 manifest の source 列(3列目)を NFC に揃えて一度だけ読み込む（比較用キー）
MANIFEST_KEYS="$(to_nfc "$(awk -F'\t' 'NR>1{print $3}' "$MANIFEST")")"

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
skipped=0

# 既に manifest に記録済みの source か判定（NFC 正規化済みキーと完全一致なら "yes"）
is_in_manifest() {
  if printf '%s\n' "$MANIFEST_KEYS" | grep -qxF -- "$1"; then
    echo "yes"
  fi
}

# bash 3.2 (macOS 標準) でも動くよう while-read + -print0 で走査する
while IFS= read -r -d '' src; do
  # source/ からの相対パス（サブディレクトリを維持するため）
  rel="${src#"$SOURCE_DIR"/}"
  # 比較・記録用のキーは NFC に正規化（実ファイルの読み込みは $src のまま使う）
  rel_key="$(to_nfc "$rel")"

  # 増分: 既に変換済み(manifest に記録済み)の source はスキップ
  if [ -n "$(is_in_manifest "$rel_key")" ]; then
    echo "  - skip (変換済み): $rel_key"
    skipped=$((skipped + 1))
    continue
  fi

  subdir="$(dirname "$rel_key")"
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
  base_noext="$(basename "$rel_key")"; base_noext="${base_noext%.*}"
  case "$(printf '%s' "$base_noext" | tr 'A-Z' 'a-z')" in
    *_secondary) variant="secondary" ;;
    *)           variant="primary" ;;
  esac

  printf '%s\t%s\t%s\t%s\t%s\n' "$now" "$variant" "$rel_key" "$out_rel" "$PUBLIC_BASE/$out_rel" >> "$MANIFEST"
  echo "  ✓ [$variant] $rel_key  →  $out_rel"
  converted=$((converted + 1))
done < <(find "$SOURCE_DIR" -type f \
  \( -iname '*.svg' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print0 | sort -z)

echo ""
if [ "$converted" -eq 0 ]; then
  echo "新規の変換対象はありませんでした（${skipped} 件は変換済みのためスキップ）"
else
  echo "完了: ${converted} 件を変換 / ${skipped} 件をスキップ（変換済み）"
fi
echo ""
echo "対応表 (source → 公開URL):"
echo "  $MANIFEST"
echo ""
echo "次のステップ: アップロード"
echo "  ./public-buckets/sponsor-logos/upload-sponsor-logos.sh"
