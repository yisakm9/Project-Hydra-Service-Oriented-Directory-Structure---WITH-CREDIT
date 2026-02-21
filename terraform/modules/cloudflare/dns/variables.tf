variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Your Cloudflare Account ID"
  type        = string
  sensitive   = true
}