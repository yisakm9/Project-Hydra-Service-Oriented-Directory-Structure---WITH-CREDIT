variable "aws_region" {
  description = "AWS Region (e.g., us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "my_ip" {
  description = "Your IP address for SSH access (CIDR format, e.g., 1.2.3.4/32)"
  type        = string
}

variable "cloudflare_api_token" {
  description = "API Token for Cloudflare"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Zone ID for Cloudflare (Optional if using only workers.dev)"
  type        = string
  default     = ""
}