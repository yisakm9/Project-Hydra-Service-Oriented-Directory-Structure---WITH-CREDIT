# ==============================================================================
# GCP KMS MODULE
# Cloud KMS Key Ring + Crypto Key
# ==============================================================================

resource "google_kms_key_ring" "hydra" {
  name     = "${var.project_name}-keyring-${var.environment}"
  location = var.gcp_region
}

resource "google_kms_crypto_key" "hydra" {
  name            = "${var.project_name}-key-${var.environment}"
  key_ring        = google_kms_key_ring.hydra.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}
