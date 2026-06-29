terraform {
  required_version = "~> 1.13"
  required_providers {
    # https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

# API トークンは CLOUDFLARE_API_TOKEN 環境変数から読み込む。
# プロバイダーブロックには直書きしない。
provider "cloudflare" {}
