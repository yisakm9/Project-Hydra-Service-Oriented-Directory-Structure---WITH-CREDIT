variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-2" # CHANGED FROM us-east-1 to Ohio
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

variable "public_key_path" {
  description = "Path to the public SSH key"
  type        = string
  default     = "../../../hydra_key.pub"
}
variable "public_key" {
  description = "The public SSH key string"
  type        = string
}
variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true
}