# ==============================================================================
# GCP IAM MODULE
# Service Account + IAM Bindings (replaces AWS IAM Role/Policy/Instance Profile)
# ==============================================================================

# --- 1. Service Account for C2 Instances ---
resource "google_service_account" "c2_sa" {
  account_id   = "${var.project_name}-c2-${var.environment}"
  display_name = "Hydra C2 Service Account (${var.environment})"
}

# --- 2. GCS Access (Backups & Loot) ---
resource "google_storage_bucket_iam_member" "c2_storage" {
  bucket = var.gcs_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.c2_sa.email}"
}

# --- 3. Pub/Sub Access (Hybrid Local PC Tasking) ---
resource "google_project_iam_member" "c2_pubsub_publisher" {
  project = var.gcp_project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.c2_sa.email}"
}

resource "google_project_iam_member" "c2_pubsub_subscriber" {
  project = var.gcp_project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.c2_sa.email}"
}
