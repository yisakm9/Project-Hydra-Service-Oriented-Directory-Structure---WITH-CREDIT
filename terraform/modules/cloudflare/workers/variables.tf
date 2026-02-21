variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Your Cloudflare Account ID"
  type        = string
  sensitive   = true
}

variable "c2_backend_url" {
  description = "The AWS CloudFront URL to forward traffic to"
  type        = string
}

variable "worker_script_path" {
  description = "Path to the JavaScript proxy code"
  type        = string
}