output "lb_ip_address" {
  description = "External IP of the load balancer"
  value       = google_compute_global_forwarding_rule.c2_frontend.ip_address
}

output "backend_service_id" {
  description = "ID of the backend service"
  value       = google_compute_backend_service.c2_backend.id
}
