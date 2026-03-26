output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.main.name
}

output "network_id" {
  description = "Self-link of the VPC network"
  value       = google_compute_network.main.self_link
}

output "subnet_ids" {
  description = "Self-links of the subnets"
  value       = google_compute_subnetwork.public[*].self_link
}

output "subnet_names" {
  description = "Names of the subnets"
  value       = google_compute_subnetwork.public[*].name
}
