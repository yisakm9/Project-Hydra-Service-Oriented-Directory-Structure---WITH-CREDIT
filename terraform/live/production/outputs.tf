output "c2_callback_url" {
  description = "The GCP LB IP (point Cloudflare Worker C2_BACKEND here)"
  value       = module.load_balancing.lb_ip_address
}

output "gcs_vault_name" {
  description = "The GCS Bucket Name for manual uploads and backups"
  value       = module.storage.bucket_name
}

output "pubsub_task_topic" {
  description = "The Pub/Sub topic for your Local Python Agent (tasks)"
  value       = module.messaging.task_topic_name
}

output "pubsub_task_subscription" {
  description = "The Pub/Sub subscription for receiving tasks"
  value       = module.messaging.task_subscription_name
}

output "pubsub_response_topic" {
  description = "The Pub/Sub topic for Local Agent responses"
  value       = module.messaging.response_topic_name
}

output "cloudflare_worker_name" {
  description = "The name of the deployed Cloudflare Worker"
  value       = module.cloudflare_workers.worker_name
}

output "local_pc_tunnel_token" {
  description = "Run: cloudflared tunnel run --token <this_value>"
  value       = module.cloudflare_tunnel.tunnel_token
  sensitive   = true
}

output "c2_service_account" {
  description = "Service Account email for the C2 instances"
  value       = module.iam.service_account_email
}