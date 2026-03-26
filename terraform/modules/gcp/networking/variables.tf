variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., production)"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for subnet placement"
  type        = string
}

variable "subnet_cidrs" {
  description = "CIDR ranges for the two subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}
