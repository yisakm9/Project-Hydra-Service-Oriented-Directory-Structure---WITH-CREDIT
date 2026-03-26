variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "network_name" {
  description = "Name of the VPC network for firewall rules"
  type        = string
}
variable "my_ip" {
  description = "Admin IP in CIDR format"
  type        = string
}
