output "instance_group" {
  description = "Self-link of the managed instance group"
  value       = google_compute_instance_group_manager.c2_mig.instance_group
}

output "instance_group_name" {
  description = "Name of the MIG"
  value       = google_compute_instance_group_manager.c2_mig.name
}
