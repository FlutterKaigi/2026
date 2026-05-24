# website

A new Jaspr project

## Running the project

Run your project using `jaspr serve`.

The development server will be available on `http://localhost:8080`.

## Building the project

Build your project using `jaspr build`.

The output will be located inside the `build/jaspr/` directory.

## PR Preview

PR を作成 / 更新すると `https://2026.flutterkaigi.jp/pr-preview/pr-<PR番号>/` に自動でプレビューがデプロイされ、PR コメントに URL が投稿される。

- ワークフロー: `.github/workflows/preview_website.yaml`
- ビルドは `dart run jaspr_cli:jaspr build --dart-define=BASE_HREF=/pr-preview/pr-<N>/` で行われる（`<base href>` と内部リンクが書き換わる）。
- プレビューは `noindex,nofollow` 付きで検索エンジンに収集されない。
- PR をクローズ / マージするとプレビューは自動削除される。

ローカルで preview と同じビルドを再現する場合:

```sh
cd apps/website
make build-preview PR_NUMBER=123
```

## 前提となる GitHub Pages 設定

このリポジトリの GitHub Pages 発行元は **Deploy from a branch (`gh-pages` / root)** に設定されている必要がある。本番デプロイ (`deploy_website.yaml`) と PR プレビューが共に `gh-pages` ブランチに書き込み、サブパスで共存する。
