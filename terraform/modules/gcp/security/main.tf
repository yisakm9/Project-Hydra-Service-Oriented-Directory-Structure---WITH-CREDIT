# ==============================================================================
# GCP SECURITY MODULE
# Firewall Rules (replaces AWS Security Groups)
# ==============================================================================

# --- 1. Allow Health Checks from GCP Load Balancer ---
# GCP LB health checks come from these well-known IP ranges
resource "google_compute_firewall" "allow_health_check" {
  name    = "${var.project_name}-allow-health-check-${var.environment}"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # GCP Load Balancer health check source ranges
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["c2-node"]
}

# --- 2. Allow HTTP/HTTPS from Internet to LB ---
# The LB itself handles this, but we need to allow traffic through
resource "google_compute_firewall" "allow_http" {
  name    = "${var.project_name}-allow-http-${var.environment}"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["lb-target"]
}

# --- 3. SSH from Admin IP Only ---
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh-${var.environment}"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.my_ip]
  target_tags   = ["c2-node"]
}

# --- 4. Mythic Web UI from Admin IP Only ---
resource "google_compute_firewall" "allow_mythic_ui" {
  name    = "${var.project_name}-allow-mythic-ui-${var.environment}"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["7443"]
  }

  source_ranges = [var.my_ip]
  target_tags   = ["c2-node"]
}

# --- 5. Allow All Outbound (for updates, GCS, Pub/Sub) ---
resource "google_compute_firewall" "allow_egress" {
  name      = "${var.project_name}-allow-egress-${var.environment}"
  network   = var.network_name
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["c2-node"]
}
