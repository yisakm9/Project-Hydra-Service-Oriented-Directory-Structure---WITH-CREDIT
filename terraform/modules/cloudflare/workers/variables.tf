variable "project_name" { type = string }
variable "environment" { type = string }
variable "cloudflare_account_id" { type = string }

variable "c2_backend_url" {
  description = "The GCP Load Balancer IP to forward traffic to"
  type        = string
}

variable "worker_script_path" {
  description = "Path to the JavaScript proxy code"
  type        = string
}

variable "local_tunnel_cname" {
  description = "The internal CNAME of the Cloudflare Tunnel"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for googleupdate.uk domain routing"
  type        = string
}