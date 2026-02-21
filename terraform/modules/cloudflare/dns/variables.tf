variable "project_name" { type = string }
variable "environment" { type = string }
variable "cloudflare_account_id" { type = string }
variable "c2_backend_url" { type = string }
variable "worker_script_path" { type = string }

# ADDED: The missing variable
variable "local_tunnel_cname" { 
  description = "The internal CNAME of the Cloudflare Tunnel"
  type = string 
}