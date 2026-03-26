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

# --- 3. Cloud Router (for Cloud NAT if needed later) ---
resource "google_compute_router" "main" {
  name    = "${var.project_name}-router-${var.environment}"
  region  = var.gcp_region
  network = google_compute_network.main.id
}

# --- 4. Cloud NAT (instances don't need public IPs to reach internet) ---
# Unlike AWS where we needed map_public_ip_on_launch, GCP Cloud NAT
# gives outbound internet without exposing instance IPs
resource "google_compute_router_nat" "main" {
  name                               = "${var.project_name}-nat-${var.environment}"
  router                             = google_compute_router.main.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
