variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "instance_group" {
  description = "Self-link of the MIG instance group"
  type        = string
}
