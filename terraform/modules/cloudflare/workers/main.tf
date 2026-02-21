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

  # Pass the CloudFront URL to the Worker
 plain_text_binding {
    name = "C2_BACKEND"
    text = "https://${var.c2_backend_url}"
  }

  # ADD THIS BLOCK:
  plain_text_binding {
    name = "LOCAL_TUNNEL"
    # Tunnels use a unique internal address ending in cfargotunnel.com
    text = "https://${var.local_tunnel_cname}" 
  }
}
