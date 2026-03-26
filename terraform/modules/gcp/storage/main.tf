# ==============================================================================
# GCP STORAGE MODULE
# GCS Bucket (replaces AWS S3)
# ==============================================================================

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# --- 1. The Main Bucket (Hydra Vault) ---
resource "google_storage_bucket" "hydra_vault" {
  name          = "${var.project_name}-vault-${var.environment}-${random_id.bucket_suffix.hex}"
  location      = var.gcp_region
  force_destroy = false # Set to true for full_burn operations

  # Equivalent of S3 Block Public Access
  uniform_bucket_level_access = true

  # Versioning for Phoenix strategy (restore C2 state from backups)
  versioning {
    enabled = true
  }

  # GCS encrypts by default with Google-managed keys
  # CMEK can be added via the KMS module later

  labels = {
    project = var.project_name
  }
}
