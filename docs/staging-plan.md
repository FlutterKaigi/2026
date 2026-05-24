# 2026 Website ステージング環境 実装計画

## 1. ゴール

PR 作成・更新時に **一時的なプレビュー URL** が自動で払い出され、PR コメントに投稿される仕組みを 2026 に追加する。スポンサーロゴ確認等のレビューに使える状態を目指す。認証は当初設定しない（2025 踏襲）。

## 2. 前提となる 2026 の現状

| 項目 | 内容 | 出典 |
|------|------|------|
| ホスティング | GitHub Pages（`apps/website/CNAME` あり、Jaspr SSG） | `.github/workflows/deploy_website.yaml` |
| デプロイトリガ | `workflow_dispatch` のみ（手動） | 同上 |
| ステージング環境 | **未整備** | — |
| ビルド | `dart run jaspr_cli:jaspr build` | `apps/website/Makefile` |
| 言語切替 / BFF 連携 | 2025 時点では未確認 | — |

**重要な構成差分**: 2025 は Cloudflare Workers (`wrangler versions upload`) で PR preview を作っていたが、2026 は GitHub Pages を本番に採用済み。**2025 と同じ手法はそのまま踏襲できない**。

## 3. 推奨アプローチ

**`rossjrw/pr-preview-action` を使い、`gh-pages` ブランチのサブパス (`/pr-preview/pr-<N>/`) に PR ごとの preview を配置する。**

### 推奨理由

- **本番と同じ GitHub Pages インフラを再利用** — 追加で Cloudflare Workers/Pages を契約・設定する必要がない。
- **2025 と同等の UX を維持できる** — PR ごとに固有 URL が払い出され、PR コメントに自動投稿される。リンクは `https://2026.flutterkaigi.jp/pr-preview/pr-<N>/`。
- **マージ時に自動クリーンアップ** — PR を閉じると preview が消えるので、運用ゴミが残らない。
- **既存ワークフローへの差分が小さい** — 本番デプロイ workflow を維持したまま、PR 用 workflow を追加するだけ。

### この案の弱点と対処

1. **Jaspr ビルドで `<base href>` を可変にする必要がある**
   - 本番は `/`、PR preview は `/pr-preview/pr-<N>/`。
   - Jaspr が `--base-href` 系のオプションを持っているか、または出力 HTML を後処理で書き換える方式を確認する必要あり（→ ステップ 4 で検証）。
2. **本番と PR preview が同一オリジン下に同居する**
   - 認証なし＋同一ドメインなので、検索エンジンにインデックスされうる。
   - 対策: PR preview のビルド出力に `<meta name="robots" content="noindex">` または `_headers` 相当を埋め込む。
3. **重い静的サイトだと `gh-pages` ブランチが肥大化**
   - スポンサーロゴ等のアセットは外部 (R2 等) に逃がす運用が望ましい。これは 2025 と同じ。

## 4. 実装ステップ

### Step 1. Jaspr の base-href 対応を検証（最初のブロッカー候補）

- `jaspr build --help` で `--base-href` 等のオプション有無を確認。
- 無い場合の選択肢:
  - **(a)** `web/index.html` の `<base href="/">` を envsubst でビルド前に書き換え
  - **(b)** post-process スクリプトで `build/jaspr/**/*.html` 内のリンクを書き換え
- ルーティング (Jaspr Router) が basePath を考慮できるか確認。
- **このステップで不可能と判明したら、推奨アプローチを Cloudflare Pages 併用案（後述「代替案 A」）に切り替える**。

### Step 2. `Makefile` に base-href 可変のビルドターゲットを追加

```makefile
build-prod:
	dart run jaspr_cli:jaspr build

build-preview:
	BASE_HREF=/pr-preview/pr-$(PR_NUMBER)/ dart run jaspr_cli:jaspr build
```

実装方式は Step 1 の結果で確定する。

### Step 3. 既存 `deploy_website.yaml` を 2 ファイルに分割

| ファイル | トリガ | 出力先 |
|----------|--------|--------|
| `deploy_website.yaml` | `push` to `main` (workflow_dispatch も残す) | GitHub Pages 本番 |
| `preview_website.yaml` (新規) | `pull_request` (opened/synchronize/reopened/closed) | `gh-pages` ブランチの `/pr-preview/pr-<N>/` |

### Step 4. `preview_website.yaml` 新規作成（雛形）

```yaml
name: PR Preview Website

on:
  pull_request:
    types: [opened, synchronize, reopened, closed]
    paths: [apps/website/**]

concurrency:
  group: preview-${{ github.event.number }}
  cancel-in-progress: true

permissions: {}

jobs:
  preview:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v6
      - id: flutter-version
        run: echo "version=$(jq -r .flutter .fvmrc)" >> "$GITHUB_OUTPUT"
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ steps.flutter-version.outputs.version }}
      - run: dart pub get
      - if: github.event.action != 'closed'
        working-directory: apps/website
        run: make build-preview PR_NUMBER=${{ github.event.number }}
      - uses: rossjrw/pr-preview-action@v1
        with:
          source-dir: apps/website/build/jaspr
          preview-branch: gh-pages
          umbrella-dir: pr-preview
          action: auto
```

`pr-preview-action` が PR コメント投稿・PR クローズ時の preview 削除を自動でやる。

### Step 5. SEO 防止のため `noindex` メタを preview ビルドに埋め込む

Step 2 のビルドターゲットで、`BASE_HREF` が設定されているときだけ `<meta name="robots" content="noindex,nofollow">` を `index.html` に注入する。

### Step 6. ドキュメント更新

- `apps/website/README.md` に「PR を作ると `https://2026.flutterkaigi.jp/pr-preview/pr-<N>/` にプレビューが出る」旨を追記。
- スポンサーロゴ確認のフロー（2025 の `bff/public-buckets/company-logos/upload-company-logos.sh` 相当）が 2026 で同等に整備されるなら、確認手順を README に書く。

### Step 7. 動作確認

- ダミー PR を作り、preview URL が PR コメントに付くこと
- リンク・画像が壊れていないこと（base-href が正しく効いていること）
- PR を閉じると preview が消えること
- 本番 (`main` push) は今まで通り `2026.flutterkaigi.jp` に出ること

## 5. 代替案

### 代替案 A: GitHub Pages（本番）+ **Cloudflare Pages**（PR preview）

- Cloudflare Pages を GitHub 連携で繋ぐと、PR ごとに `https://<commit>.<project>.pages.dev` が自動払い出し。PR コメントへの投稿も Cloudflare 側がやる。
- **メリット**: base-href 問題が一切起きない（独立オリジン）。設定がとにかく楽。
- **デメリット**: ホスティング基盤が 2 つに分かれる。Cloudflare アカウント・プロジェクトの管理が増える。
- **Step 1 で base-href 対応が困難と判明した場合の自動切替先**。

### 代替案 B: 2025 と完全に同じ構成（Cloudflare Workers）に戻す

- 本番デプロイ先も Cloudflare Workers に統一する案。
- **メリット**: 2025 の workflow・スクリプト一式をほぼコピペで持ち込める。
- **デメリット**: 2026 で既に決めた「GitHub Pages 本番」方針をひっくり返す判断が要る。`apps/website/CNAME` も使えなくなる。
- **2026 で GitHub Pages を選んだ理由が「Cloudflare 依存を減らしたい」だったなら採用すべきでない**。

## 6. 想定スケジュール（参考）

| ステップ | 想定工数 |
|----------|----------|
| Step 1 (base-href 検証) | 0.5d — ここが最重要 |
| Step 2-4 (Makefile + workflow) | 1.0d |
| Step 5-6 (noindex + docs) | 0.5d |
| Step 7 (動作確認) | 0.5d |
| **合計** | **約 2.5d** |

base-href が解決できれば残りは機械的。Step 1 で躓いたら代替案 A に切り替えて再見積もり。

## 7. 認証について（参考）

2025 同様、認証は当初付けない方針。後日付ける場合の選択肢は前回提示した通り:

- 推奨アプローチ採用時: **GitHub Pages 単体には BASIC 認証を仕掛けられない** ため、認証要件が出てきたら代替案 A（Cloudflare Pages） or 代替案 B（Cloudflare Workers + Basic 認証ミドルウェア）への移行が必要になる。
- 2026 では当面「URL を関係者間でのみ共有する」運用合意でカバーする想定。
