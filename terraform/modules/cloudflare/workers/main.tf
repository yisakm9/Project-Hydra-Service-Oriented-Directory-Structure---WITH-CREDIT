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

# Deploy the Worker
resource "cloudflare_worker_script" "ghost_proxy" {
  account_id = var.cloudflare_account_id
  name       = "${var.project_name}-proxy-${var.environment}"
  content    = file(var.worker_script_path)
  module     = true

  plain_text_binding {
    name = "C2_BACKEND"
    text = "https://${var.c2_backend_url}"
  }
}

# Enable the worker on the *.workers.dev subdomain
resource "cloudflare_worker_domain" "workers_dev" {
  account_id = var.cloudflare_account_id
  hostname   = "${cloudflare_worker_script.ghost_proxy.name}.YOUR_WORKERS_SUBDOMAIN.workers.dev"
  service    = cloudflare_worker_script.ghost_proxy.name
  zone_id    = "" # Not needed for workers.dev
  
  # Note: Currently, Terraform requires a custom domain to use cloudflare_worker_domain easily.
  # If you don't have a domain, Cloudflare automatically enables the worker on 
  # <script-name>.<your-subdomain>.workers.dev by default when the script is uploaded!
}