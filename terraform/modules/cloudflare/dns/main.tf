terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Generate a cryptographically secure 32-character secret for the tunnel
resource "random_password" "tunnel_secret" {
  length  = 32
  special = false
}

# Provision the Cloudflare Argo Tunnel
resource "cloudflare_tunnel" "local_bridge" {
  account_id = var.cloudflare_account_id
  name       = "${var.project_name}-local-bridge-${var.environment}"
  secret     = base64encode(random_password.tunnel_secret.result)
  config_src = "local" # Tells CF we will manage the routing locally
}