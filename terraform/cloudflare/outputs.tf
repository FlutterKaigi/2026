output "bucket_name" {
  description = "Name of the R2 public bucket"
  value       = cloudflare_r2_bucket.public.name
}

output "public_url" {
  description = "Public base URL for the bucket via the custom domain"
  value       = "https://${var.custom_domain}"
}
