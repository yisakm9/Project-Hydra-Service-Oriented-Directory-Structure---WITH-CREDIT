# ==============================================================================
# GCP LOAD BALANCING MODULE
# External HTTP(S) Load Balancer
# (replaces AWS ALB + Target Group + Listener)
# ==============================================================================

# --- 1. Health Check ---
resource "google_compute_health_check" "c2_lb_health" {
  name                = "${var.project_name}-lb-health-${var.environment}"
  check_interval_sec  = 15
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = 80
    request_path = "/health"
  }
}

# --- 2. Backend Service (replaces Target Group) ---
resource "google_compute_backend_service" "c2_backend" {
  name                  = "${var.project_name}-backend-${var.environment}"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL"

  health_checks = [google_compute_health_check.c2_lb_health.id]

  backend {
    group           = var.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
  }

  # Cloud CDN: pass-through mode, zero caching for C2 traffic
  enable_cdn = true
  cdn_policy {
    cache_mode                   = "USE_ORIGIN_HEADERS"
    signed_url_cache_max_age_sec = 0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# --- 3. URL Map (routing rules) ---
resource "google_compute_url_map" "c2_url_map" {
  name            = "${var.project_name}-url-map-${var.environment}"
  default_service = google_compute_backend_service.c2_backend.id
}

# --- 4. HTTP Proxy ---
resource "google_compute_target_http_proxy" "c2_http_proxy" {
  name    = "${var.project_name}-http-proxy-${var.environment}"
  url_map = google_compute_url_map.c2_url_map.id
}

# --- 5. Global Forwarding Rule (the actual frontend) ---
resource "google_compute_global_forwarding_rule" "c2_frontend" {
  name                  = "${var.project_name}-frontend-${var.environment}"
  target                = google_compute_target_http_proxy.c2_http_proxy.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
}
