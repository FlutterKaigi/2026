#!/bin/bash
set -euo pipefail

# =============================================================================
# FlutterKaigi 2026 スポンサーロゴ アップロードスクリプト
# =============================================================================
# logos/ 配下の画像を R2 公開バケット (2026-public-production) にアップロードする。
#
# 前提:
#   - rclone がインストール済み
#   - rclone リモート "r2" が設定済み（public-buckets/README.md 参照）
#
# 使い方:
#   ./public-buckets/sponsor-logos/upload-sponsor-logos.sh
#
# アップロード後の公開URL:
#   https://2026-bucket.flutterkaigi.jp/logos/<ファイル名>
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/logos"
RCLONE_REMOTE="r2"
BUCKET_NAME="2026-public-production"
DEST_PREFIX="logos"

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
  echo "ERROR: ロゴディレクトリがありません: $SOURCE_DIR" >&2
  exit 1
fi

# --- 対象ファイル数の確認 ---
count=$(find "$SOURCE_DIR" -type f \
  \( -iname '*.webp' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.svg' \) | wc -l)

if [ "$count" -eq 0 ]; then
  echo "アップロード対象の画像がありません: $SOURCE_DIR"
  exit 0
fi

echo "アップロード先 : ${RCLONE_REMOTE}:${BUCKET_NAME}/${DEST_PREFIX}/"
echo "対象ファイル数 : ${count}"
echo ""

# --- アップロード ---
# --header-upload で Cache-Control を付与（CDN/ブラウザキャッシュ）
# --s3-no-check-bucket でバケット存在チェック(要 CreateBucket 権限)を省略
rclone copy "$SOURCE_DIR" "${RCLONE_REMOTE}:${BUCKET_NAME}/${DEST_PREFIX}/" \
  --progress \
  --exclude ".*" \
  --header-upload "Cache-Control: public, max-age=86400" \
  --s3-no-check-bucket

echo ""
echo "完了: https://2026-bucket.flutterkaigi.jp/${DEST_PREFIX}/<ファイル名> で取得できます"

