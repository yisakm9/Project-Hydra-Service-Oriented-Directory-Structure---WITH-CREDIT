variable "project_name" { type = string }
variable "environment"  { type = string }
variable "vpc_id"       { type = string }
variable "public_subnets" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}
variable "security_groups" {
  description = "List of security groups for the ALB"
  type        = list(string)
}