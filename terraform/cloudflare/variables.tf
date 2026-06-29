variable "account_id" {
  type        = string
  description = "Cloudflare Account ID"
  default     = "cdd8f59359fe226645e7b541cdc53b57"
}

variable "zone_id" {
  type        = string
  description = "Cloudflare Zone ID for flutterkaigi.jp (ダッシュボードの Overview 右側で確認)"
}

variable "bucket_name" {
  type        = string
  description = "R2 public bucket name"
  default     = "2026-public-production"
}

variable "custom_domain" {
  type        = string
  description = "Custom domain for public access to the bucket"
  default     = "2026-bucket.flutterkaigi.jp"
}
