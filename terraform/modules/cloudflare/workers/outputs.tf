output "worker_name" {
  description = "Name of the deployed worker"
  value       = cloudflare_worker_script.ghost_proxy.name
}