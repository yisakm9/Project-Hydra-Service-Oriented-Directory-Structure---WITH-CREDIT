output "key_id" {
  description = "ID of the KMS crypto key"
  value       = google_kms_crypto_key.hydra.id
}

output "key_ring_id" {
  description = "ID of the KMS key ring"
  value       = google_kms_key_ring.hydra.id
}
