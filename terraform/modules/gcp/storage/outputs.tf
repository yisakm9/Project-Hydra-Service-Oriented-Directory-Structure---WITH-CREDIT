output "bucket_name" {
  description = "Name of the GCS bucket"
  value       = google_storage_bucket.hydra_vault.name
}

output "bucket_url" {
  description = "URL of the GCS bucket"
  value       = google_storage_bucket.hydra_vault.url
}
