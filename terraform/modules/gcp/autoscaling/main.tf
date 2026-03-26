# ==============================================================================
# GCP AUTOSCALING MODULE
# Instance Template + Managed Instance Group
# (replaces AWS Launch Template + Auto Scaling Group)
# ==============================================================================

# --- 1. Ubuntu 24.04 Image Lookup ---
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

# --- 2. Instance Template ---
resource "google_compute_instance_template" "c2_template" {
  name_prefix  = "${var.project_name}-template-"
  machine_type = var.machine_type
  region       = var.gcp_region

  tags = var.network_tags

  disk {
    source_image = data.google_compute_image.ubuntu.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = 30
    disk_type    = "pd-ssd"

    disk_encryption_key {
      # Uses Google-managed encryption; swap to CMEK key if KMS module is wired
    }
  }

  network_interface {
    subnetwork = var.subnet_ids[0]

    # No external IP — Cloud NAT handles outbound
    # Uncomment access_config for direct SSH (without tunnel)
    # access_config {}
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  # The Mythic C2 bootstrap script (equivalent to AWS user_data)
  metadata = {
    startup-script = var.startup_script
    ssh-keys       = "hydra:${var.public_key}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --- 3. Health Check for Auto-Healing ---
resource "google_compute_health_check" "c2_health" {
  name                = "${var.project_name}-mig-health-${var.environment}"
  check_interval_sec  = 15
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 80
    request_path = "/health"
  }
}

# --- 4. Managed Instance Group (MIG) ---
resource "google_compute_instance_group_manager" "c2_mig" {
  name               = "${var.project_name}-mig-${var.environment}"
  zone               = var.gcp_zone
  base_instance_name = "${var.project_name}-node"
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.c2_template.self_link_unique
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.c2_health.id
    initial_delay_sec = 1200 # 20 min for Mythic to fully bootstrap
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 1
    max_unavailable_fixed = 1
  }
}
