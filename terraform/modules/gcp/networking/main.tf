# ==============================================================================
# GCP NETWORKING MODULE
# VPC + Subnets + Cloud Router (replaces AWS VPC/IGW/Subnets/Route Tables)
# ==============================================================================

# --- 1. VPC Network ---
resource "google_compute_network" "main" {
  name                    = "${var.project_name}-vpc-${var.environment}"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# --- 2. Subnets (x2, different zones for LB HA) ---
resource "google_compute_subnetwork" "public" {
  count = 2

  name          = "${var.project_name}-subnet-${count.index + 1}-${var.environment}"
  ip_cidr_range = var.subnet_cidrs[count.index]
  region        = var.gcp_region
  network       = google_compute_network.main.id

  # Enable flow logs for OpSec audit trail (missing in AWS version)
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# NOTE: Cloud NAT removed to save ~$32/month.
# Instances use ephemeral external IPs via access_config instead.
