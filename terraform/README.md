# FlutterKaigi 2026 Terraform

FlutterKaigi 2026 のインフラを Terraform で管理します。

現状は **スポンサーロゴ用の R2 公開バケット**（`terraform/cloudflare`）を管理しています。

## 構成方針

2025 をベースにしつつ、本リポジトリはパブリック・ブランチ保護なしのため **GitHub Actions による自動 apply は採用しません**。

| 対象 | 置き場所 | 補足 |
| --- | --- | --- |
| コード (`.tf`) | GitHub（このリポジトリ） | チームで共有・レビュー |
| state (`tfstate`) | R2 の `tf-state` バケット | S3 互換 backend で共有・ロック。**Git には入れない** |
| API トークン | 各自のローカル環境変数 | コミットしない |
| apply 実行 | 各自のローカル | 自動 apply なし |

## ディレクトリ

```
terraform/
  cloudflare/        # R2 公開バケット + カスタムドメイン
    provider.tf
    backend.tf
    backend.tfbackend.example
    variables.tf
    main.tf
    outputs.tf
```

`cloudflare` モジュールで作るもの:

- R2 バケット `2026-public-production`
- カスタムドメイン `2026-bucket.flutterkaigi.jp`（`enabled = true` で公開）

## セットアップ手順

### 1. ツール

- Terraform CLI（1.13 系）
- （任意）ロゴアップロード用に Rclone

### 2. Cloudflare API トークン（apply 実行用）

[ダッシュボード](https://dash.cloudflare.com/) → My Profile → API Tokens で以下の権限のトークンを作成:

| スコープ | 権限 | 用途 |
| --- | --- | --- |
| Account / Workers R2 Storage | Edit | バケット・カスタムドメイン作成 |
| Zone / DNS | Edit | カスタムドメインの DNS / 証明書発行 |

- Account Resources: Include → `FlutterKaigi`
- Zone Resources: Include → Specific zone → `flutterkaigi.jp`

```bash
export CLOUDFLARE_API_TOKEN="<発行したトークン>"
```

> zone_id は Terraform 変数で直接渡すため、`Zone / Zone / Read` 権限は不要。

### 3. state 用 R2 認証情報（backend アクセス用 / 上の API トークンとは別物）

[R2 → API トークン](https://dash.cloudflare.com/cdd8f59359fe226645e7b541cdc53b57/r2/api-tokens) で
**Object Read & Write** 権限の R2 API トークンを発行し、`backend.tfbackend` を作成:

```bash
cd terraform/cloudflare
cp backend.tfbackend.example backend.tfbackend
# backend.tfbackend を編集して access_key / secret_key を記入
```

> `backend.tfbackend` は `.gitignore` 済み。コミットしないこと。
> state 用バケット `tf-state` が存在しない場合は、先に Cloudflare ダッシュボードで作成しておくこと。

### 4. zone_id を設定

Cloudflare ダッシュボードで `flutterkaigi.jp` を選び、Overview ページ右側の「Zone ID」をコピーして `terraform.tfvars` に記入:

```bash
cd terraform/cloudflare
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集して zone_id を記入（terraform.tfvars は gitignore 済み）
```

### 5. 適用

```bash
cd terraform/cloudflare
terraform init -backend-config=backend.tfbackend
terraform plan      # r2_bucket 1 + r2_custom_domain 1 が作成される想定
terraform apply
```

### 6. 確認

```bash
terraform output public_url   # https://2026-bucket.flutterkaigi.jp
```

apply 後、カスタムドメインの SSL 証明書がアクティブになるまで数分かかる場合があります。
有効化後、`https://2026-bucket.flutterkaigi.jp/<key>` でファイルを取得できます。

## スポンサーロゴのアップロード

バケット作成は Terraform、ファイル投入は Rclone で行います（2025 と同じ思想）。
Rclone のリモート設定は 2025 の `bff/public-buckets/RCLONE_SETUP.md` を参照。
アップロード先バケットは `2026-public-production`。
