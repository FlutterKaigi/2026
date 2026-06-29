# スポンサーロゴを格納する公開バケット
resource "cloudflare_r2_bucket" "public" {
  account_id    = var.account_id
  name          = var.bucket_name
  location      = "apac"
  storage_class = "Standard"
}

# カスタムドメインを紐付けて公開アクセスを有効化する。
# enabled = true で https://<custom_domain>/<key> から取得可能になる。
resource "cloudflare_r2_custom_domain" "public" {
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.public.name
  domain      = var.custom_domain
  zone_id     = var.zone_id
  enabled     = true
  min_tls     = "1.2"
}
