#!/bin/bash
set -euo pipefail

# =============================================================================
# FlutterKaigi 2026 公式写真アルバム アップロードスクリプト
# =============================================================================
# photos/ 配下の 01〜10.webp と bg.webp を R2 公開バケット (2026-public-production)
# にアップロードする。企業スポンサーロゴ (public-buckets/sponsor-logos/)・個人スポンサー
# 写真 (public-buckets/individual-photos/) とはプレフィックスを分け、`album/` 配下に
# 独立して置く。
#
# 前提:
#   - rclone がインストール済み
#   - rclone リモート "r2" が設定済み（public-buckets/README.md 参照）
#
# 使い方:
#   ./public-buckets/album-photos/upload-album-photos.sh
#
#   アップロードされるファイルだけを確認する（何も送らない）:
#   DRY_RUN=1 ./public-buckets/album-photos/upload-album-photos.sh
#
# アップロード後の公開URL:
#   https://2026-bucket.flutterkaigi.jp/album/<名前>.webp
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/photos"
RCLONE_REMOTE="r2"
BUCKET_NAME="2026-public-production"
DEST_PREFIX="album"
# 他のツール(1日)より短くしている。撮影チームから掲載の取り下げを頼まれて R2 から消したとき、
# CDN・ブラウザのキャッシュに古い写真が長く残らないようにするため。
CACHE_CONTROL="public, max-age=3600"

# --- 前提チェック ---
if ! command -v rclone >/dev/null 2>&1; then
  echo "ERROR: rclone がインストールされていません" >&2
  exit 1
fi

if ! rclone listremotes | grep -q "^${RCLONE_REMOTE}:"; then
  echo "ERROR: rclone リモート '${RCLONE_REMOTE}' が未設定です。public-buckets/README.md を参照してください。" >&2
  exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo "ERROR: 写真ディレクトリがありません: $SOURCE_DIR" >&2
  exit 1
fi

# --- 対象ファイルの確認 ---
# サイトが参照する名前（01〜10 と bg）の webp だけを送る。
targets=()
while IFS= read -r -d '' f; do
  targets+=("$f")
done < <(find "$SOURCE_DIR" -maxdepth 1 -type f \
  \( -name '0[1-9].webp' -o -name '10.webp' -o -name 'bg.webp' \) -print0 | sort -z)

if [ "${#targets[@]}" -eq 0 ]; then
  echo "アップロード対象の画像がありません: $SOURCE_DIR"
  echo "（先に convert-album-photos.sh で 01〜10.webp / bg.webp を作ってください）"
  exit 0
fi

# 進捗表示は端末に出すときだけ（CI やパイプ越しでは行が大量に流れるため）
progress_args=()
if [ -t 1 ]; then
  progress_args=(--progress)
fi

dry_run_args=()
if [ "${DRY_RUN:-0}" = "1" ]; then
  dry_run_args=(--dry-run)
  echo "DRY_RUN=1: 実際にはアップロードしません"
fi

echo "アップロード先 : ${RCLONE_REMOTE}:${BUCKET_NAME}/${DEST_PREFIX}/"
echo "Cache-Control  : ${CACHE_CONTROL}"
echo "対象ファイル数 : ${#targets[@]}"
for f in "${targets[@]}"; do
  printf '  %s (%s bytes)\n' "$(basename "$f")" "$(wc -c < "$f" | tr -d ' ')"
done
echo ""

# --- アップロード ---
# --filter で、上の名前以外のファイルが photos/ に紛れていても送らない
#   （先に書いた規則が優先される。先頭の / は photos/ 直下だけを指す）
# --header-upload で Cache-Control を付与（CDN/ブラウザキャッシュ）
# --s3-no-check-bucket でバケット存在チェック(要 CreateBucket 権限)を省略
rclone copy "$SOURCE_DIR" "${RCLONE_REMOTE}:${BUCKET_NAME}/${DEST_PREFIX}/" \
  --filter "+ /0[1-9].webp" --filter "+ /10.webp" --filter "+ /bg.webp" --filter "- *" \
  --header-upload "Cache-Control: ${CACHE_CONTROL}" \
  --s3-no-check-bucket \
  ${progress_args[@]+"${progress_args[@]}"} \
  ${dry_run_args[@]+"${dry_run_args[@]}"}

echo ""
echo "完了: https://2026-bucket.flutterkaigi.jp/${DEST_PREFIX}/<名前>.webp で取得できます"
