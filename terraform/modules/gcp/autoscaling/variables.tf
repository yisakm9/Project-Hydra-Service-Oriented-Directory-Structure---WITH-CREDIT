variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "gcp_region" {
  type = string
}
variable "gcp_zone" {
  type = string
}
variable "machine_type" {
  description = "GCE machine type"
  type        = string
  default     = "e2-standard-2" # 2 vCPU, 8GB (equiv to m7i-flex.large)
}
variable "subnet_ids" {
  description = "Subnet self-links for instance placement"
  type        = list(string)
}
variable "network_tags" {
  description = "Network tags for firewall rules"
  type        = list(string)
}
variable "service_account_email" {
  description = "Service account email for the instances"
  type        = string
}
variable "startup_script" {
  description = "Rendered startup script content"
  type        = string
}
variable "public_key" {
  description = "SSH public key for instance access"
  type        = string
}
