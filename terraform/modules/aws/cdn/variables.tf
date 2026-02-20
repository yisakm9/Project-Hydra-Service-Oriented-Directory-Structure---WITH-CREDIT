variable "project_name" { type = string }
variable "environment"  { type = string }
variable "origin_domain_name" {
  description = "The DNS domain of the ALB"
  type        = string
}