output "worker_name" {
  description = "Name of the deployed worker"
  # Note the plural 'workers' here as well
  value       = cloudflare_workers_script.ghost_proxy.name 
}