terraform {
  # state は R2 の tf-state バケットに保存して共有する（Git にはコミットしない）。
  # access_key / secret_key などは backend.tfbackend 経由で渡す:
  #   terraform init -backend-config=backend.tfbackend
  backend "s3" {
    bucket                      = "tf-state"
    key                         = "flutterkaigi-2026-cloudflare.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    endpoints                   = { s3 = "https://cdd8f59359fe226645e7b541cdc53b57.r2.cloudflarestorage.com" }
  }
}
